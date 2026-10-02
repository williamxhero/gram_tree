"""私有菜谱 HTTP 接口（SPEC-002.2）。"""

import base64
import binascii
import json
import uuid
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import Response

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, ErrorResponse
from gramtree.core.ids import IdV4
from gramtree.core.pagination import PageParams, page_params
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.recipes import service
from gramtree.recipes.schemas import (
    MoldSpec,
    RecipeCreate,
    RecipeDetail,
    RecipeImageOut,
    RecipeImageStagedOut,
    RecipeImageUpload,
    RecipeIngredientDisplayOut,
    RecipeList,
    RecipeMoldConversionOut,
    RecipeMoldConversionRequest,
    RecipeServingConversionOut,
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


def _parse_optional_measure_id(raw: str | None) -> uuid.UUID | None:
    if not raw:
        return None
    try:
        value = uuid.UUID(raw)
    except ValueError as exc:
        raise ApiError(
            422, "invalid_request", "请求参数有误", "measure_id 不是有效的 UUID"
        ) from exc
    if value.version != 4:
        raise ApiError(422, "invalid_request", "请求参数有误", "measure_id 不是有效的 UUID v4")
    return value


def _parse_target_mold(raw: str | None) -> MoldSpec | None:
    if raw is None:
        return None
    try:
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError
        return MoldSpec.model_validate(value)
    except (TypeError, ValueError, json.JSONDecodeError) as exc:
        raise ApiError(422, "invalid_mold", "目标模具参数有误") from exc


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


@router.post(
    "/images/staging",
    response_model=RecipeImageStagedOut,
    status_code=201,
    responses=_errors(401, 422, 503),
)
def stage_recipe_image(
    body: RecipeImageUpload,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
) -> RecipeImageStagedOut:
    try:
        content = base64.b64decode(body.content_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ApiError(422, "invalid_image", "图片格式有误") from exc
    return service.stage_image(session, settings, auth.user, content, body.content_type)


@router.get("/images/staging/{image_id}", responses=_errors(404))
def read_staged_recipe_image(
    image_id: IdV4,
    session: SessionDep,
    settings: SettingsDep,
    expires: int = Query(),
    signature: str = Query(),
) -> Response:
    content, content_type = service.signed_staged_image_file(
        session, settings, image_id, expires, signature
    )
    return Response(
        content=content, media_type=content_type, headers={"Cache-Control": "private, no-store"}
    )


@router.get(
    "/{recipe_id}/servings",
    response_model=RecipeServingConversionOut,
    responses=_errors(401, 404, 422),
)
def convert_current_recipe_servings(
    recipe_id: IdV4,
    auth: CurrentAuth,
    session: SessionDep,
    target_servings: int = Query(),
) -> RecipeServingConversionOut:
    return service.convert_recipe_servings(session, auth.user, recipe_id, target_servings)


@router.post(
    "/{recipe_id}/mold",
    response_model=RecipeMoldConversionOut,
    responses=_errors(401, 404, 422),
)
def convert_current_recipe_mold(
    recipe_id: IdV4,
    body: RecipeMoldConversionRequest,
    auth: CurrentAuth,
    session: SessionDep,
) -> RecipeMoldConversionOut:
    return service.convert_recipe_mold(session, auth.user, recipe_id, body.target_mold)


@router.get(
    "/{recipe_id}/display",
    response_model=RecipeIngredientDisplayOut,
    responses=_errors(401, 404, 422),
)
def display_current_recipe_ingredients(
    recipe_id: IdV4,
    auth: CurrentAuth,
    session: SessionDep,
    mode: Literal["base", "standard", "home"] = Query(),
    raw_measure_id: str | None = Query(default=None, alias="measure_id"),
    target_servings: int | None = Query(default=None, ge=1),
    target_mold: str | None = Query(default=None, description="JSON encoded target mold"),
) -> RecipeIngredientDisplayOut:
    return service.display_recipe_ingredients(
        session,
        auth.user,
        recipe_id,
        mode,
        measure_id=_parse_optional_measure_id(raw_measure_id),
        target_servings=target_servings,
        target_mold=_parse_target_mold(target_mold),
    )


@router.get(
    "/{recipe_id}/versions/{version_id}/display",
    response_model=RecipeIngredientDisplayOut,
    responses=_errors(401, 404, 422),
)
def display_recipe_version_ingredients(
    recipe_id: IdV4,
    version_id: IdV4,
    auth: CurrentAuth,
    session: SessionDep,
    mode: Literal["base", "standard", "home"] = Query(),
    raw_measure_id: str | None = Query(default=None, alias="measure_id"),
    target_servings: int | None = Query(default=None, ge=1),
    target_mold: str | None = Query(default=None, description="JSON encoded target mold"),
) -> RecipeIngredientDisplayOut:
    return service.display_recipe_ingredients(
        session,
        auth.user,
        recipe_id,
        mode,
        measure_id=_parse_optional_measure_id(raw_measure_id),
        version_id=version_id,
        target_servings=target_servings,
        target_mold=_parse_target_mold(target_mold),
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
    "/{recipe_id}/versions/{version_id}/servings",
    response_model=RecipeServingConversionOut,
    responses=_errors(401, 404, 422),
)
def convert_recipe_version_servings(
    recipe_id: IdV4,
    version_id: IdV4,
    auth: CurrentAuth,
    session: SessionDep,
    target_servings: int = Query(),
) -> RecipeServingConversionOut:
    return service.convert_recipe_servings(
        session, auth.user, recipe_id, target_servings, version_id
    )


@router.post(
    "/{recipe_id}/versions/{version_id}/mold",
    response_model=RecipeMoldConversionOut,
    responses=_errors(401, 404, 422),
)
def convert_recipe_version_mold(
    recipe_id: IdV4,
    version_id: IdV4,
    body: RecipeMoldConversionRequest,
    auth: CurrentAuth,
    session: SessionDep,
) -> RecipeMoldConversionOut:
    return service.convert_recipe_mold(session, auth.user, recipe_id, body.target_mold, version_id)


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
    redis: RedisDep,
    settings: SettingsDep,
) -> RecipeImageOut:
    try:
        content = base64.b64decode(body.content_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ApiError(422, "invalid_image", "图片格式有误") from exc
    return service.save_image(
        session, redis, settings, auth.user, recipe_id, content, body.content_type
    )


@router.get("/{recipe_id}/images/{image_id}", responses=_errors(404))
def read_recipe_image(
    recipe_id: IdV4,
    image_id: IdV4,
    session: SessionDep,
    settings: SettingsDep,
    expires: int = Query(),
    signature: str = Query(),
) -> Response:
    content, content_type = service.signed_image_file(
        session, settings, recipe_id, image_id, expires, signature
    )
    return Response(
        content=content,
        media_type=content_type,
        headers={"Cache-Control": "private, no-store"},
    )
