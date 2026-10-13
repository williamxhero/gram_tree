"""Private, single-item recipe imports for text, one-page links and screenshots."""

from __future__ import annotations

import base64
import binascii
import hashlib
import ipaddress
import json
import os
import socket
import tempfile
import uuid
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

import httpx
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import APIRouter
from pydantic import BaseModel, ConfigDict, Field
from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.deps import CurrentAuth
from gramtree.ai import gateway
from gramtree.ai import service as ai_service
from gramtree.ai.schemas import GeneratedDraft
from gramtree.core.errors import ApiError
from gramtree.core.time import utcnow
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.events import service as events
from gramtree.events.registry import BY_KEY
from gramtree.recipes import food_safety, reproducibility
from gramtree.recipes import service as recipes
from gramtree.recipes.import_models import RecipeImport
from gramtree.recipes.schemas import (
    RecipeDetail,
    RecipeSource,
    ValueSource,
)
from gramtree.settings import Settings

router = APIRouter(prefix="/recipe-imports", tags=["recipe-imports"])
MAX_IMAGES = 9
MAX_IMAGE_BYTES = 2 * 1024 * 1024
MAX_PAGE_BYTES = 1_000_000
PAGE_TIMEOUT_SECONDS = 8.0


class ImportInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    text: str | None = Field(default=None, max_length=20_000)
    url: str | None = Field(default=None, max_length=2048)
    images_base64: list[str] = Field(default_factory=list, max_length=MAX_IMAGES)
    source_note: str | None = Field(default=None, max_length=500)


class ImportOut(BaseModel):
    import_id: str | None = None
    status: str
    reason: str | None = None
    next_step: str | None = None
    recipe: RecipeDetail | None = None
    field_states: dict[str, str] = Field(default_factory=dict)
    failed_images: list[int] = Field(default_factory=list)
    reproducibility: dict | None = None


class _ImportContentV1(BaseModel):
    import_id: str
    mode: str
    status: str
    reason: str | None = None
    image_count: int = 0
    failed_image_count: int = 0
    recognized_fields: int = 0
    estimated_fields: int = 0
    incomplete_fields: int = 0


class _PageText(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._hidden = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in ("script", "style", "noscript", "svg", "video", "img", "iframe"):
            self._hidden += 1

    def handle_endtag(self, tag: str) -> None:
        if tag in ("script", "style", "noscript", "svg", "video", "img", "iframe"):
            self._hidden = max(0, self._hidden - 1)
        elif tag in ("p", "div", "li", "br", "h1", "h2", "h3"):
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self._hidden and data.strip():
            self.parts.append(data.strip())


def _encrypt(settings: Settings, owner_id: uuid.UUID, import_id: uuid.UUID, text: str) -> bytes:
    key = hashlib.sha256(settings.auth_secret.encode("utf-8")).digest()
    nonce = os.urandom(12)
    aad = f"gramtree:recipe-import:v1:{owner_id}:{import_id}".encode()
    return nonce + AESGCM(key).encrypt(nonce, text.encode("utf-8"), aad)


def _decrypt(settings: Settings, row: RecipeImport) -> str:
    key = hashlib.sha256(settings.auth_secret.encode("utf-8")).digest()
    aad = f"gramtree:recipe-import:v1:{row.owner_id}:{row.id}".encode()
    return (
        AESGCM(key)
        .decrypt(row.original_ciphertext[:12], row.original_ciphertext[12:], aad)
        .decode()
    )


def _safe_url(raw: str, *, allow_local: bool) -> tuple[str, str]:
    try:
        parsed = urlsplit(raw)
        if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username:
            raise ValueError
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        addresses = {
            ipaddress.ip_address(item[4][0]) for item in socket.getaddrinfo(parsed.hostname, port)
        }
        if (not addresses or any(not ip.is_global for ip in addresses)) and not (
            allow_local and parsed.hostname in ("localhost", "127.0.0.1", "::1")
        ):
            raise ValueError
        return raw, parsed.hostname.lower()
    except (ValueError, OSError, UnicodeError) as exc:
        raise ApiError(422, "invalid_import_url", "链接格式有误，请粘贴公开网页链接") from exc


def _read_page(url: str, *, allow_local: bool) -> tuple[str | None, str | None, str | None]:
    _, host = _safe_url(url, allow_local=allow_local)
    try:
        with httpx.stream(
            "GET",
            url,
            follow_redirects=False,
            timeout=PAGE_TIMEOUT_SECONDS,
            headers={"User-Agent": "GramTreeRecipeImporter/1.0 (+https://gramtree.app/import)"},
        ) as response:
            if response.status_code in (401, 403, 407):
                return (
                    None,
                    "login_required" if response.status_code == 401 else "access_denied",
                    None,
                )
            if 300 <= response.status_code < 400:
                return None, "access_denied", None
            if response.status_code >= 400:
                return None, "access_denied", None
            chunks = bytearray()
            for chunk in response.iter_bytes():
                chunks.extend(chunk)
                if len(chunks) > MAX_PAGE_BYTES:
                    return None, "page_too_large", None
            content_type = response.headers.get("content-type", "")
            if "html" not in content_type and "text/plain" not in content_type:
                return None, "not_recipe", None
            raw = chunks.decode(response.encoding or "utf-8", errors="replace")
            if "html" in content_type:
                parser = _PageText()
                parser.feed(raw)
                raw = " ".join(parser.parts)
            text = " ".join(raw.split())
            if len(text) < 40:
                reason = (
                    "recipe_may_be_in_images"
                    if any(term in text for term in ("笔记", "分享", "小红书"))
                    else "content_too_short"
                )
                return None, reason, None
            if not any(
                term in text
                for term in ("食材", "材料", "做法", "步骤", "克", "勺", "分钟", "炒", "煮")
            ):
                return None, "not_recipe", None
            return text[:20_000], None, host
    except httpx.TimeoutException:
        return None, "timeout", None
    except httpx.HTTPError:
        return None, "access_denied", None


def _draft_from_model(raw) -> tuple[GeneratedDraft, dict[str, str]]:
    value = json.loads(raw) if isinstance(raw, str) else raw
    draft = GeneratedDraft.model_validate(value.get("draft", value))
    states = value.get("field_states", {}) if isinstance(value, dict) else {}
    valid = {"recognized", "ai_estimated", "incomplete"}
    return draft, {str(k): str(v) for k, v in states.items() if v in valid}


def _record_event(session: Session, redis: Redis, owner_id: uuid.UUID, row: RecipeImport) -> None:
    content = _ImportContentV1(
        import_id=str(row.id),
        mode=row.mode,
        status=row.status,
        reason=row.reason,
        image_count=row.image_count,
        failed_image_count=row.failed_image_count,
        recognized_fields=sum(value == "recognized" for value in row.field_states.values()),
        estimated_fields=sum(value == "ai_estimated" for value in row.field_states.values()),
        incomplete_fields=sum(value == "incomplete" for value in row.field_states.values()),
    )
    now = utcnow()
    spec = BY_KEY[("recipe.import", 1)]
    if spec.content_schema is not None:
        content = spec.content_schema.model_validate(content.model_dump())
    events.upload(
        session,
        redis,
        owner_id,
        [
            events.EventInput(
                id=uuid.uuid4(),
                event_type="recipe.import",
                type_version=1,
                device_id="server",
                device_time=now,
                app_version="server",
                correlation={},
                content=content.model_dump(mode="json", exclude_none=True),
            )
        ],
        now,
    )


def create_import(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner,
    body: ImportInput,
) -> ImportOut:
    if sum(bool(x) for x in (body.text, body.url, body.images_base64)) != 1:
        raise ApiError(422, "invalid_import", "请粘贴文字、一个链接或选择图片")
    mode = "text" if body.text else "link" if body.url else "image"
    source_url = None
    platform = "unknown"
    source_text = body.text.strip() if body.text else ""
    image_bytes: list[bytes] = []
    failed_images: list[int] = []
    if body.url:
        source_url, platform = _safe_url(body.url, allow_local=settings.env == "test")
        prior = session.scalar(
            select(RecipeImport).where(
                RecipeImport.owner_id == owner.id,
                RecipeImport.source_url == source_url,
                RecipeImport.recipe_id.is_not(None),
            )
        )
        if prior:
            assert prior.recipe_id is not None
            recipe = recipes.get_recipe(session, settings, owner, prior.recipe_id)
            return ImportOut(
                import_id=str(prior.id),
                status="duplicate",
                recipe=recipe,
                next_step="打开已有菜谱，或粘贴文字后重新导入。",
            )
        page_text, reason, host = _read_page(source_url, allow_local=settings.env == "test")
        if reason:
            row = RecipeImport(
                owner_id=owner.id,
                mode=mode,
                source_url=source_url,
                source_platform=platform,
                original_ciphertext=b"",
                status="failed",
                reason=reason,
                field_states={},
                image_count=0,
                failed_image_count=0,
            )
            session.add(row)
            session.flush()
            row.original_ciphertext = _encrypt(settings, owner.id, row.id, "")
            _record_event(session, redis, owner.id, row)
            session.commit()
            return ImportOut(
                import_id=str(row.id),
                status="failed",
                reason=reason,
                next_step="请粘贴页面文字后重试。"
                if reason != "recipe_may_be_in_images"
                else "请截取笔记图片后导入。",
            )
        source_text = page_text or ""
        platform = host or "unknown"
    elif body.images_base64:
        for index, encoded in enumerate(body.images_base64, start=1):
            try:
                data = base64.b64decode(encoded, validate=True)
            except (ValueError, binascii.Error):
                failed_images.append(index)
                continue
            if (
                not data
                or len(data) > MAX_IMAGE_BYTES
                or not data.startswith((b"\xff\xd8", b"\x89PNG\r\n\x1a\n", b"RIFF"))
            ):
                failed_images.append(index)
                continue
            image_bytes.append(data)

    if mode == "text" and len(source_text) < 12:
        return ImportOut(
            status="failed", reason="content_too_short", next_step="请补充菜名、食材或步骤。"
        )
    if not source_text and not image_bytes:
        return ImportOut(
            status="failed",
            reason="not_recipe",
            next_step="请换一段菜谱文字或更清晰的图片。",
            failed_images=failed_images,
        )
    operation_id = uuid.uuid4()
    payload = {
        "text": source_text,
        "intent": {
            "dish_name": "从用户提供的外部内容中提取菜谱",
            "servings": None,
            "taste": [],
            "restrictions": [],
            "cookware": [],
        },
        "source_url": source_url,
        "source_platform": platform,
        "source_note": body.source_note,
        "images_base64": [base64.b64encode(x).decode("ascii") for x in image_bytes],
    }
    temp_paths: list[Path] = []
    try:
        with tempfile.TemporaryDirectory(prefix="gramtree-import-") as directory:
            for index, data in enumerate(image_bytes):
                path = Path(directory) / f"{index + 1}.jpg"
                path.write_bytes(data)
                temp_paths.append(path)
            try:
                raw = gateway.call(
                    session, settings, owner.id, "recipe_import", payload, operation_id
                )
                draft, states = _draft_from_model(raw)
                recipe_draft = draft.recipe
                if not recipe_draft.dish_name or (
                    not recipe_draft.snapshot.ingredients and not recipe_draft.snapshot.steps
                ):
                    raise ValueError("not_recipe")
                recipe_draft.ai_assisted = True
                recipe_draft.change_note = "外部导入 · AI 协助"
                recipe_draft.snapshot.text_source = ValueSource(
                    source="ai_estimated", basis="从外部内容提取并改写"
                )
                recipe_draft.snapshot.source = RecipeSource(
                    url=source_url, platform=platform, note=body.source_note
                )
                ai_service._mark_sources(draft)
                confirmations = ai_service._normalize(session, settings, owner, draft, operation_id)
                safety = food_safety.check(
                    session, recipe_draft.snapshot, recipe_draft.dish_name or ""
                )
                if safety.high_risk or not safety.can_save:
                    raise ValueError("unsafe_or_prohibited_content")
                snapshot = recipes._validate_snapshot(
                    session, recipe_draft.snapshot, owner.id, settings=settings
                )
                recipe_draft.snapshot = snapshot
                detail = recipes.create_recipe(session, redis, settings, owner, recipe_draft)
                if confirmations:
                    for item in confirmations:
                        states[f"ingredient:{item.split('：', 1)[0]}"] = "incomplete"
                if failed_images:
                    for index in failed_images:
                        states[f"image:{index}"] = "incomplete"
                incomplete = bool(failed_images or any(s == "incomplete" for s in states.values()))
                import_row = RecipeImport(
                    owner_id=owner.id,
                    mode=mode,
                    source_url=source_url,
                    source_platform=platform,
                    recipe_id=detail.id,
                    original_ciphertext=b"",
                    status="partial" if incomplete else "success",
                    reason=None,
                    field_states=states,
                    image_count=len(body.images_base64),
                    failed_image_count=len(failed_images),
                )
                session.add(import_row)
                session.flush()
                import_row.original_ciphertext = _encrypt(
                    settings, owner.id, import_row.id, source_text or "[图片导入]"
                )
                _record_event(session, redis, owner.id, import_row)
                session.commit()
                return ImportOut(
                    import_id=str(import_row.id),
                    status=import_row.status,
                    recipe=detail,
                    field_states=states,
                    failed_images=failed_images,
                    reproducibility=reproducibility.check(detail.version.snapshot).model_dump(
                        mode="json"
                    ),
                )
            except gateway.Unavailable as exc:
                reason = exc.reason
                status = "failed"
            except (ValueError, KeyError, TypeError, json.JSONDecodeError):
                reason = "not_recipe"
                status = "failed"
        row = RecipeImport(
            owner_id=owner.id,
            mode=mode,
            source_url=source_url,
            source_platform=platform,
            original_ciphertext=b"",
            status=status,
            reason=reason,
            field_states={},
            image_count=len(body.images_base64),
            failed_image_count=len(failed_images),
        )
        session.add(row)
        session.flush()
        row.original_ciphertext = _encrypt(settings, owner.id, row.id, source_text or "[图片导入]")
        _record_event(session, redis, owner.id, row)
        session.commit()
        next_step = (
            "请粘贴页面文字后重试。"
            if reason in ("model_unavailable", "daily_quota", "monthly_budget")
            else "请换一段菜谱文字或更清晰的图片。"
        )
        return ImportOut(
            import_id=str(row.id),
            status="failed",
            reason=reason,
            next_step=next_step,
            failed_images=failed_images,
        )
    finally:
        for path in temp_paths:
            path.unlink(missing_ok=True)


def read_original(session: Session, settings: Settings, owner, import_id: uuid.UUID) -> str:
    row = session.scalar(
        select(RecipeImport).where(RecipeImport.id == import_id, RecipeImport.owner_id == owner.id)
    )
    if row is None:
        from gramtree.core.errors import NotFound

        raise NotFound()
    return _decrypt(settings, row)


@router.post("", response_model=ImportOut)
def import_recipe(
    body: ImportInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> ImportOut:
    return create_import(session, redis, settings, auth.user, body)


class ImportOriginalOut(BaseModel):
    original_text: str


@router.get("/{import_id}/original", response_model=ImportOriginalOut)
def get_import_original(
    import_id: uuid.UUID, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> ImportOriginalOut:
    return ImportOriginalOut(original_text=read_original(session, settings, auth.user, import_id))
