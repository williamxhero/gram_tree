"""私有菜谱 HTTP 接口（SPEC-002.2）。"""

import base64
import binascii
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import FileResponse

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, ErrorResponse
from gramtree.core.ids import IdV4
from gramtree.core.pagination import PageParams, page_params
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.recipes import service
from gramtree.recipes.schemas import (
    RecipeCreate,
    RecipeDetail,
    RecipeImageOut,
    RecipeImageUpload,
    RecipeList,
    RecipeVersionCreate,
    RecipeVersionHistory,
)
from gramtree.runtime_config import service as config

router = APIRouter(prefix="/recipes", tags=["recipes"])
PageDep = Annotated[PageParams, Depends(page_params)]


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    responses: dict[int | str, dict[str, Any]] = dict(ERROR_RESPONSES)
    for code in codes:
        responses[code] = {"model": ErrorResponse}
    return responses


@router.post("", response_model=RecipeDetail, status_code=201, responses=_errors(401, 409))
def create_recipe(
    body: RecipeCreate,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> RecipeDetail:
    try:
        return service.create_recipe(session, redis, settings, auth.user, body)
    except ValueError as exc:
        raise ApiError(422, "invalid_recipe", "菜谱结构有误", str(exc)) from exc


@router.get("", response_model=RecipeList, responses=_errors(401))
def list_recipes(auth: CurrentAuth, session: SessionDep, page: PageDep) -> RecipeList:
    return service.list_recipes(
        session,
        auth.user,
        cursor=page.cursor,
        limit=page.limit,
        maximum=int(config.get(session, "api.page_size_max")),
    )


@router.get("/{recipe_id}", response_model=RecipeDetail, responses=_errors(401, 404))
def get_recipe(
    recipe_id: IdV4, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> RecipeDetail:
    return service.get_recipe(session, settings, auth.user, recipe_id)


@router.post(
    "/{recipe_id}/versions",
    response_model=RecipeDetail,
    status_code=201,
    responses=_errors(401, 404),
)
def save_recipe_version(
    recipe_id: IdV4,
    body: RecipeVersionCreate,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> RecipeDetail:
    return service.save_version(session, redis, settings, auth.user, recipe_id, body)


@router.get(
    "/{recipe_id}/versions", response_model=RecipeVersionHistory, responses=_errors(401, 404)
)
def list_recipe_versions(
    recipe_id: IdV4, auth: CurrentAuth, session: SessionDep, page: PageDep
) -> RecipeVersionHistory:
    return service.list_versions(
        session,
        auth.user,
        recipe_id,
        cursor=page.cursor,
        limit=page.limit,
        maximum=int(config.get(session, "api.page_size_max")),
    )


@router.get(
    "/{recipe_id}/versions/{version_id}", response_model=RecipeDetail, responses=_errors(401, 404)
)
def get_recipe_version(
    recipe_id: IdV4,
    version_id: IdV4,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
) -> RecipeDetail:
    return service.get_version(session, settings, auth.user, recipe_id, version_id)


@router.delete("/{recipe_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_errors(401, 404))
def delete_recipe(
    recipe_id: IdV4, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> None:
    service.delete_recipe(session, auth.user, recipe_id, settings)


@router.post(
    "/{recipe_id}/images",
    response_model=RecipeImageOut,
    status_code=201,
    responses=_errors(401, 404, 503),
)
def upload_recipe_image(
    recipe_id: IdV4,
    body: RecipeImageUpload,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
) -> RecipeImageOut:
    try:
        content = base64.b64decode(body.content_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ApiError(422, "invalid_image", "图片格式有误") from exc
    return service.save_image(session, settings, auth.user, recipe_id, content, body.content_type)


@router.get("/{recipe_id}/images/{image_id}", responses=_errors(404))
def read_recipe_image(
    recipe_id: IdV4,
    image_id: IdV4,
    session: SessionDep,
    settings: SettingsDep,
    expires: int = Query(),
    signature: str = Query(),
) -> FileResponse:
    path, content_type = service.signed_image_file(
        session, settings, recipe_id, image_id, expires, signature
    )
    return FileResponse(
        path, media_type=content_type, headers={"Cache-Control": "private, no-store"}
    )
