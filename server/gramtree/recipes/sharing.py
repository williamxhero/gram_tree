"""Fail-closed public recipe previews and owner-issued opaque share links."""

from __future__ import annotations

import re
import secrets
import uuid
from html import escape
from urllib.parse import parse_qs, urlsplit

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, Response
from pydantic import BaseModel, ConfigDict, Field, ValidationError
from sqlalchemy import select
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from gramtree.accounts.deps import CurrentAuth
from gramtree.accounts.models import User, UserStatus
from gramtree.core.errors import ERROR_RESPONSES, ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.deps import SessionDep, SettingsDep
from gramtree.recipes.models import Dish, Recipe, RecipeImage, RecipeVersion, ShareComplaint
from gramtree.recipes.storage import make_recipe_storage
from gramtree.runtime_config import service as config

api_router = APIRouter(prefix="/recipes", tags=["recipe-sharing"])
resolver_router = APIRouter(prefix="/shares", tags=["recipe-sharing"])
web_router = APIRouter(include_in_schema=False)
_UNAVAILABLE = (
    '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    '<title>菜谱不存在或已下架</title><meta name="robots" content="noindex,nofollow">'
    "</head><body><main><h1>菜谱不存在或已下架</h1></main></body></html>"
)
_NOT_FOUND = HTMLResponse(_UNAVAILABLE, status_code=404, headers={"Cache-Control": "no-store"})
_LICENSE = "CC BY-NC-SA 4.0"
_PHOTO_RIGHTS = "照片版权归上传者所有"


class RecipeShareLink(BaseModel):
    model_config = ConfigDict(extra="forbid")

    share_id: str = Field(min_length=40, max_length=64)
    url: str
    app_path: str


class PublicRecipeProjection(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str
    description: str
    nickname: str
    image_url: str | None
    license: str
    photo_rights: str


class RecipeShareTarget(BaseModel):
    model_config = ConfigDict(extra="forbid")

    share_id: str
    recipe_id: IdV4
    app_path: str


class ShareComplaintInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    contact: str = Field(min_length=3, max_length=320, pattern=r"^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$")
    message: str = Field(min_length=10, max_length=4000)
    share_id: str | None = Field(
        default=None, min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_-]+$"
    )


class ShareComplaintReceipt(BaseModel):
    accepted: bool = True


def _submit_complaint(session: Session, body: ShareComplaintInput) -> None:
    session.add(ShareComplaint(contact=body.contact, message=body.message, share_id=body.share_id))
    session.commit()


PublicRow = tuple[Recipe, RecipeVersion, RecipeImage | None, Dish, User]


def _origin(session: Session) -> str:
    configured = str(config.get(session, "sharing.public_base_url")).strip().rstrip("/")
    parsed = urlsplit(configured)
    if (
        parsed.scheme != "https"
        or not parsed.netloc
        or parsed.username is not None
        or parsed.password is not None
        or parsed.path
        or parsed.query
        or parsed.fragment
    ):
        raise ValueError("sharing.public_base_url must be an HTTPS origin")
    return configured


def _reject_ai_crawler(request: Request, session: Session) -> None:
    raw = config.get(session, "sharing.ai_crawlers")
    values = raw.get("values", []) if isinstance(raw, dict) else []
    user_agent = request.headers.get("user-agent", "").casefold()
    if any(
        isinstance(agent, str) and agent.strip() and agent.strip().casefold() in user_agent
        for agent in values
    ):
        raise ApiError(403, "crawler_denied", "此页面不允许用于自动化训练抓取", None)


def _public_recipe(session: Session, share_id: str) -> PublicRow | None:
    enabled = bool(config.get(session, "feature.public_recipes"))
    if not enabled:
        return None
    row = session.execute(
        select(Recipe, RecipeVersion, RecipeImage, Dish, User)
        .join(RecipeVersion, RecipeVersion.id == Recipe.current_version_id)
        .join(Dish, Dish.id == Recipe.dish_id)
        .join(User, User.id == Recipe.owner_id)
        .outerjoin(RecipeImage, RecipeImage.version_id == RecipeVersion.id)
        .where(
            Recipe.share_id == share_id,
            User.status == UserStatus.active,
            Recipe.visibility == "public",
            Recipe.approved_public_version_id == Recipe.current_version_id,
        )
        .order_by(RecipeImage.created_at.desc())
    ).first()
    if row is None:
        return None
    recipe, version, image, dish, author = row
    return recipe, version, image, dish, author


def _owner_projection(
    session: Session, recipe_id: uuid.UUID, owner_id: uuid.UUID
) -> PublicRow | None:
    row = session.execute(
        select(Recipe, RecipeVersion, RecipeImage, Dish, User)
        .join(RecipeVersion, RecipeVersion.id == Recipe.current_version_id)
        .join(Dish, Dish.id == Recipe.dish_id)
        .join(User, User.id == Recipe.owner_id)
        .outerjoin(RecipeImage, RecipeImage.version_id == RecipeVersion.id)
        .where(
            Recipe.id == recipe_id,
            Recipe.owner_id == owner_id,
            Recipe.visibility == "public",
            Recipe.approved_public_version_id == Recipe.current_version_id,
        )
        .order_by(RecipeImage.created_at.desc())
    ).first()
    if row is None:
        return None
    return row[0], row[1], row[2], row[3], row[4]


def _projection(row: PublicRow, image_url: str | None) -> PublicRecipeProjection:
    _, version, _, dish, author = row
    snapshot = version.snapshot if isinstance(version.snapshot, dict) else {}
    description = snapshot.get("description")
    return PublicRecipeProjection(
        title=dish.name,
        description=description if isinstance(description, str) else "",
        nickname=author.nickname,
        image_url=image_url,
        license=_LICENSE,
        photo_rights=_PHOTO_RIGHTS,
    )


def _public_image_url(share_id: str, image: RecipeImage | None) -> str | None:
    return f"/s/{share_id}/image" if image is not None else None


def _page_html(projection: PublicRecipeProjection, base_url: str, app_path: str) -> str:
    title = escape(projection.title)
    description = escape(projection.description)
    nickname = escape(projection.nickname)
    image = ""
    og_image = ""
    if projection.image_url:
        image_url = escape(base_url + projection.image_url, quote=True)
        image = f'<img src="{image_url}" alt="{title}" width="1200" height="900">'
        og_image = f'<meta property="og:image" content="{image_url}">'
    return (
        '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        f'<title>{title}</title><meta property="og:title" content="{title}">'
        f'<meta property="og:description" content="{description}">{og_image}'
        "<style>body{margin:0;padding:24px 16px;background:#F7F4EE;color:#1B1813;"
        "font-family:'Noto Sans SC',sans-serif;line-height:1.7}main{max-width:760px;"
        "margin:0 auto}img{display:block;width:100%;height:auto;max-height:70vh;"
        "object-fit:cover;border-radius:4px}h1{font-family:'Noto Serif SC',serif}"
        "a{display:inline-block;background:#1B1813;color:#FFFDF9;padding:10px 16px;"
        "text-decoration:none;border-radius:4px}</style></head><body><main>"
        f"{image}<h1>{title}</h1><p>{description}</p>"
        f"<p>作者：{nickname}</p><p>{escape(projection.license)}；{escape(projection.photo_rights)}</p>"
        f'<a href="{escape(app_path, quote=True)}">在 App 里看完整菜谱</a>'
        '<p><a href="/download">没有 App？获取测试版</a></p>'
        '<p><a href="/complaints">权利投诉</a></p>'
        "</main></body></html>"
    )


@api_router.post(
    "/{recipe_id}/share",
    response_model=RecipeShareLink,
    status_code=201,
    responses={**ERROR_RESPONSES, 404: {"description": "不可分享"}},
    operation_id="create_recipe_share",
)
def create_recipe_share(
    recipe_id: IdV4,
    auth: CurrentAuth,
    session: SessionDep,
) -> RecipeShareLink:
    row = _owner_projection(session, recipe_id, auth.user.id)
    if row is None:
        raise NotFound()
    # Serialize first issuance so concurrent taps return the same stable share ID.
    recipe = session.scalar(
        select(Recipe)
        .where(Recipe.id == recipe_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if (
        recipe is None
        or recipe.visibility != "public"
        or recipe.approved_public_version_id != recipe.current_version_id
    ):
        raise NotFound()
    if not bool(config.get(session, "feature.public_recipes")):
        raise NotFound()
    try:
        origin = _origin(session)
    except ValueError:
        raise NotFound() from None
    if not recipe.share_id:
        recipe.share_id = secrets.token_urlsafe(32)
        session.commit()
    app_path = f"/recipes/{recipe.id}"
    return RecipeShareLink(
        share_id=recipe.share_id, url=f"{origin}/s/{recipe.share_id}", app_path=app_path
    )


@api_router.get(
    "/{recipe_id}/share-preview",
    response_model=PublicRecipeProjection,
    responses={**ERROR_RESPONSES, 404: {"description": "不可分享"}},
    operation_id="get_recipe_share_preview",
)
def get_recipe_share_preview(
    recipe_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> PublicRecipeProjection:
    row = _owner_projection(session, recipe_id, auth.user.id)
    if row is None or not bool(config.get(session, "feature.public_recipes")):
        raise NotFound()
    recipe, version, image, dish, author = row
    del version, dish, author
    image_url = _public_image_url(recipe.share_id, image) if recipe.share_id and image else None
    return _projection(row, image_url)


@resolver_router.get(
    "/{share_id}",
    response_model=RecipeShareTarget,
    responses=ERROR_RESPONSES,
    operation_id="resolve_recipe_share",
)
def resolve_recipe_share(share_id: str, request: Request, session: SessionDep) -> RecipeShareTarget:
    _reject_ai_crawler(request, session)
    row = _public_recipe(session, share_id) if len(share_id) == 43 else None
    if row is None:
        raise NotFound()
    request.scope["gramtree.content_id"] = str(row[0].id)
    return RecipeShareTarget(
        share_id=share_id, recipe_id=row[0].id, app_path=f"/recipes/{row[0].id}"
    )


@resolver_router.post(
    "/{share_id}/complaints",
    response_model=ShareComplaintReceipt,
    status_code=201,
    responses=ERROR_RESPONSES,
    operation_id="submit_recipe_share_complaint",
)
def submit_recipe_share_complaint(
    share_id: str, body: ShareComplaintInput, session: SessionDep
) -> ShareComplaintReceipt:
    # Accept unavailable links too, without disclosing whether they once existed.
    try:
        validated = ShareComplaintInput(
            contact=body.contact, message=body.message, share_id=share_id
        )
    except ValidationError:
        raise ApiError(422, "invalid_complaint", "请检查投诉内容", None) from None
    _submit_complaint(session, validated)
    return ShareComplaintReceipt()


@web_router.get("/s/{share_id}", response_class=HTMLResponse)
def shared_recipe_page(share_id: str, request: Request, session: SessionDep) -> Response:
    _reject_ai_crawler(request, session)
    if len(share_id) != 43:
        return _NOT_FOUND
    row = _public_recipe(session, share_id)
    if row is None:
        return _NOT_FOUND
    _, version, image, _, _ = row
    try:
        origin = _origin(session)
    except ValueError:
        return _NOT_FOUND
    projection = _projection(row, _public_image_url(share_id, image))
    app_path = f"{origin}/s/{share_id}"
    response = HTMLResponse(_page_html(projection, origin, app_path))
    response.headers["Cache-Control"] = "no-store"
    request.scope["gramtree.content_id"] = str(version.id)
    return response


@web_router.get("/s/{share_id}/image")
def shared_recipe_image(
    share_id: str, request: Request, session: SessionDep, settings: SettingsDep
) -> Response:
    _reject_ai_crawler(request, session)
    if len(share_id) != 43:
        return Response(
            status_code=404,
            content=b"",
            media_type="image/png",
            headers={"Cache-Control": "no-store"},
        )
    row = _public_recipe(session, share_id)
    if row is None or row[2] is None:
        return Response(
            status_code=404,
            content=b"",
            media_type="image/png",
            headers={"Cache-Control": "no-store"},
        )
    image = row[2]
    request.scope["gramtree.content_id"] = str(row[1].id)
    try:
        content = make_recipe_storage(settings).get(image.storage_key)
    except Exception:
        return Response(
            status_code=404,
            content=b"",
            media_type="image/png",
            headers={"Cache-Control": "no-store"},
        )
    return Response(
        content=content,
        media_type=image.content_type,
        headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"},
    )


@web_router.get("/robots.txt", response_class=Response)
def robots_txt(session: SessionDep) -> Response:
    raw = config.get(session, "sharing.ai_crawlers")
    values = raw.get("values", []) if isinstance(raw, dict) else []
    agents = [
        str(value).strip()
        for value in values
        if re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", str(value).strip())
    ]
    body = (
        "User-agent: *\nAllow: /\n"
        + "".join(f"\nUser-agent: {agent}\nDisallow: /" for agent in agents)
        + "\n"
    )
    return Response(body, media_type="text/plain", headers={"Cache-Control": "public, max-age=300"})


@web_router.get("/complaints", response_class=HTMLResponse)
def complaint_page(session: SessionDep) -> HTMLResponse:
    contact = str(config.get(session, "sharing.complaint_contact")).strip() or "请联系平台支持团队"
    escaped = escape(contact)
    link = (
        f'<a href="mailto:{escape(contact, quote=True)}">{escaped}</a>'
        if "@" in contact and " " not in contact
        else f"<p>{escaped}</p>"
    )
    html = (
        "<!doctype html><html lang='zh-CN'><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        "<title>权利投诉</title></head><body><main><h1>权利投诉</h1>"
        f"{link}<p>投诉资料仅用于联系和人工复核，不公开展示。</p>"
        '<form action="/complaints" method="post">'
        '<label>联系邮箱<input name="contact" type="email" maxlength="320" required></label>'
        '<label>分享 ID（选填）<input name="share_id" maxlength="64"></label>'
        '<label>权利说明<textarea name="message" minlength="10" maxlength="4000" required>'
        "</textarea></label>"
        '<button type="submit">提交侵权投诉</button></form></main></body></html>'
    )
    return HTMLResponse(html)


@web_router.post("/complaints", response_class=HTMLResponse, status_code=201)
async def submit_complaint_form(request: Request, session: SessionDep) -> HTMLResponse:
    if request.headers.get("content-type", "").split(";")[0] != "application/x-www-form-urlencoded":
        raise ApiError(415, "invalid_complaint", "仅支持文字投诉表单", None)
    payload = bytearray()
    async for chunk in request.stream():
        payload.extend(chunk)
        if len(payload) > 16384:
            raise ApiError(413, "invalid_complaint", "投诉内容过长", None)
    try:
        fields = parse_qs(payload.decode("utf-8"), keep_blank_values=True, max_num_fields=3)
        if any(len(values) != 1 for values in fields.values()):
            raise ValueError("duplicate fields")
        data = {key: values[0] for key, values in fields.items()}
        if not data.get("share_id"):
            data.pop("share_id", None)
        body = ShareComplaintInput.model_validate(data)
    except (ValueError, UnicodeError, ValidationError):
        raise ApiError(422, "invalid_complaint", "请检查投诉内容", None) from None
    await run_in_threadpool(_submit_complaint, session, body)
    return HTMLResponse(
        "<!doctype html><html lang='zh-CN'><head><meta charset='utf-8'>"
        "<title>投诉已收到</title></head><body><h1>投诉已收到，等待人工复核</h1></body></html>",
        status_code=201,
        headers={"Cache-Control": "no-store"},
    )


@web_router.get("/download", response_class=HTMLResponse)
def download_page(session: SessionDep) -> HTMLResponse:
    url = str(config.get(session, "sharing.download_url")).strip()
    parsed = urlsplit(url)
    if parsed.scheme != "https" or not parsed.netloc or parsed.username is not None:
        return HTMLResponse(
            "<!doctype html><html lang='zh-CN'><head><meta charset='utf-8'>"
            "<title>获取 App</title></head><body><main><h1>获取 App</h1>"
            "<p>请联系平台支持团队获取测试版。</p></main></body></html>"
        )
    safe_url = escape(url, quote=True)
    return HTMLResponse(
        "<!doctype html><html lang='zh-CN'><head><meta charset='utf-8'>"
        "<title>获取 App</title></head><body><main><h1>获取 App</h1>"
        f"<a href='{safe_url}'>下载或获取测试版</a></main></body></html>"
    )
