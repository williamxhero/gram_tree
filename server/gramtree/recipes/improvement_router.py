"""Improvement working copies and explicit save choices."""

from fastapi import APIRouter

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES
from gramtree.core.ids import IdV4
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.recipes import improvements
from gramtree.recipes.improvement_schemas import (
    ImprovementDraftInput,
    ImprovementDraftOut,
    ImprovementPreviewInput,
    ImprovementPreviewOut,
    ImprovementSaveInput,
    ImprovementSaveOut,
    RecordVersionSaveInput,
)

router = APIRouter(tags=["improvements"], responses=ERROR_RESPONSES)


@router.post(
    "/records/{record_id}/save-version",
    response_model=ImprovementSaveOut,
    status_code=201,
    operation_id="save_record_version",
)
def save_record_version(
    record_id: IdV4,
    body: RecordVersionSaveInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> ImprovementSaveOut:
    return improvements.save_record_version(session, redis, settings, auth.user, record_id, body)


@router.post(
    "/recipes/{recipe_id}/improvement-drafts",
    response_model=ImprovementDraftOut,
    status_code=201,
    operation_id="create_improvement_draft",
)
def create_improvement_draft(
    recipe_id: IdV4, body: ImprovementDraftInput, auth: CurrentAuth, session: SessionDep
) -> ImprovementDraftOut:
    return improvements.create_draft(session, auth.user, recipe_id, body.source_version_id)


@router.get(
    "/improvement-drafts/{draft_id}",
    response_model=ImprovementDraftOut,
    operation_id="get_improvement_draft",
)
def get_improvement_draft(
    draft_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> ImprovementDraftOut:
    return improvements.draft_out(improvements.owned_draft(session, auth.user, draft_id))


@router.post(
    "/recipes/{recipe_id}/improvements/preview",
    response_model=ImprovementPreviewOut,
    operation_id="preview_improvement",
)
def preview_improvement(
    recipe_id: IdV4,
    body: ImprovementPreviewInput,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
) -> ImprovementPreviewOut:
    return improvements.preview(session, settings, auth.user, recipe_id, body)


@router.post(
    "/recipes/{recipe_id}/improvements",
    response_model=ImprovementSaveOut,
    status_code=201,
    operation_id="save_improvement",
)
def save_improvement(
    recipe_id: IdV4,
    body: ImprovementSaveInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> ImprovementSaveOut:
    return improvements.save(session, redis, settings, auth.user, recipe_id, body)
