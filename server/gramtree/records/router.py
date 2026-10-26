"""Authenticated cooking-record HTTP API."""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select, tuple_
from sqlalchemy.orm import Session

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import PageParams, decode_cursor, encode_cursor, page_params
from gramtree.core.time import utcnow
from gramtree.deps import SessionDep, SettingsDep
from gramtree.recipes.models import Recipe, RecipeVersion
from gramtree.records import context as record_context
from gramtree.records.models import CookingRecord, CookingRecordRevision
from gramtree.records.schemas import (
    CookingRecordCreate,
    CookingRecordHistoryOut,
    CookingRecordListOut,
    CookingRecordOut,
    CookingRecordRevisionCreate,
    CookingRecordRevisionOut,
)
from gramtree.records.service import matches_submission, record_created_event
from gramtree.runtime_config import service as config

router = APIRouter(prefix="/records", tags=["records"])
PageDep = Annotated[PageParams, Depends(page_params)]


def _out(row: CookingRecord) -> CookingRecordOut:
    return CookingRecordOut.model_validate(row, from_attributes=True)


def _owned(session: Session, owner: uuid.UUID, record_id: uuid.UUID) -> CookingRecord:
    row = session.scalar(
        select(CookingRecord).where(CookingRecord.id == record_id, CookingRecord.owner_id == owner)
    )
    if row is None:
        raise NotFound()
    return row


def _validate_recipe_reference(
    session: Session, owner: uuid.UUID, body: CookingRecordCreate
) -> tuple[Recipe | None, RecipeVersion | None]:
    if body.recipe_version_id is None:
        if body.verification == "cooking_mode":
            raise ApiError(422, "invalid_record", "记录内容有误", "做菜模式验证必须关联菜谱版本")
        if body.recipe_id is not None:
            raise ApiError(422, "invalid_record", "记录内容有误", "缺少菜谱版本")
        return None, None
    version = session.get(RecipeVersion, body.recipe_version_id)
    if version is None:
        raise NotFound()
    from gramtree.recipes.publication import readable_version

    try:
        recipe, version = readable_version(session, owner, version.recipe_id, version.id)
    except NotFound:
        # A signed frozen execution authorizes only this record write. Withdrawal
        # must not destroy somebody else's offline data or restore public access.
        from gramtree.records.completion import completed_context

        if body.completion is None:
            raise
        completed_context(owner, body, session.info["settings"])
        recipe = session.get(Recipe, version.recipe_id)
        if recipe is None or body.recipe_id != recipe.id:
            raise NotFound() from None
    if body.recipe_id is not None and body.recipe_id != recipe.id:
        raise ApiError(422, "invalid_record", "记录内容有误", "菜谱版本关联不一致")
    if body.verification == "cooking_mode":
        raise ApiError(422, "verification_unavailable", "不能自行声明做菜模式验证")
    return recipe, version


def _record_context(
    session: Session, owner: uuid.UUID, ids: list[uuid.UUID], settings
) -> tuple[dict, list[uuid.UUID]]:
    try:
        return record_context.build(session, owner, ids, settings)
    except ValueError as exc:
        code = str(exc)
        if code == "sensitive_consent_required":
            raise ApiError(403, code, "请先单独同意收集家庭成员信息") from exc
        raise ApiError(422, code, "同吃成员不是本账号已授权成员") from exc


@router.post("", response_model=CookingRecordOut, status_code=201, responses=ERROR_RESPONSES)
def create_record(
    body: CookingRecordCreate, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> CookingRecordOut:
    from gramtree.records.completion import completed_context
    from gramtree.taste_profiles.service import lock_owner

    recipe, version = _validate_recipe_reference(session, auth.user.id, body)
    verification, source_context = completed_context(auth.user.id, body, settings)
    # Serialize retries before inserting FK rows, matching durable sync's order.
    lock_owner(session, auth.user.id)
    taste_summary, co_diner_ids = _record_context(
        session, auth.user.id, body.co_diner_ids, settings
    )
    if body.source == "cooking_session" and body.recipe_version_id is None:
        raise ApiError(422, "invalid_record", "记录内容有误", "做菜模式记录需要菜谱版本")
    if body.source != "cooking_session" and body.verification == "cooking_mode":
        raise ApiError(422, "invalid_record", "记录内容有误", "入口不能声明做菜模式验证")
    existing = session.scalar(
        select(CookingRecord).where(
            CookingRecord.owner_id == auth.user.id, CookingRecord.client_id == body.client_id
        )
    )
    if existing is not None:
        if not matches_submission(existing, body, verification, source_context):
            raise ApiError(409, "record_id_reused", "记录 ID 已用于其他内容")
        return _out(existing)
    row = CookingRecord(
        owner_id=auth.user.id,
        client_id=body.client_id,
        recipe_id=recipe.id if recipe else body.recipe_id,
        recipe_version_id=version.id if version else None,
        dish_name=body.dish_name,
        source=body.source,
        verification=verification,
        counts_as_cooked=body.source != "dining"
        and (body.completion is None or bool(body.completion.completed_steps)),
        meal=body.meal,
        occurred_at=body.occurred_at
        or (body.completion.finished_at if body.completion else utcnow()),
        snapshot=body.snapshot,
        adjustments=body.adjustments,
        source_context=source_context,
        taste_summary=taste_summary,
        co_diner_ids=[str(item) for item in co_diner_ids],
    )
    session.add(row)
    session.flush()
    record_created_event(session, auth.user.id, row)
    from gramtree.recipes.publication import record_completed

    record_completed(session, settings, row)
    session.commit()
    session.refresh(row)
    return _out(row)


@router.get("", response_model=CookingRecordListOut, responses=ERROR_RESPONSES)
def list_records(auth: CurrentAuth, session: SessionDep, page: PageDep) -> CookingRecordListOut:
    maximum = int(config.get(session, "api.page_size_max"))
    if page.limit > maximum:
        raise ApiError(422, "invalid_request", "请求参数有误", f"limit 不能超过 {maximum}")
    stmt = select(CookingRecord).where(CookingRecord.owner_id == auth.user.id)
    if page.cursor:
        at, row_id = decode_cursor(page.cursor)
        stmt = stmt.where(tuple_(CookingRecord.created_at, CookingRecord.id) < tuple_(at, row_id))
    rows = list(
        session.scalars(
            stmt.order_by(CookingRecord.created_at.desc(), CookingRecord.id.desc()).limit(
                page.limit + 1
            )
        )
    )
    more = len(rows) > page.limit
    rows = rows[: page.limit]
    return CookingRecordListOut(
        items=[_out(row) for row in rows],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if more else None,
    )


@router.delete(
    "/{record_id}", status_code=204, responses=ERROR_RESPONSES, operation_id="deleteRecord"
)
def delete_record(
    record_id: IdV4, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> None:
    from gramtree.accounts import deletion
    from gramtree.exports import service as exports

    exports.lock_owner(session, auth.user.id)
    row = _owned(session, auth.user.id, record_id)
    deletion.erase_owner_caches(settings, auth.user.id)
    deletion.erase_record(session, row)
    exports.invalidate_owner_exports(session, settings, auth.user.id)
    session.commit()


@router.get("/{record_id}", response_model=CookingRecordOut, responses=ERROR_RESPONSES)
def get_record(record_id: IdV4, auth: CurrentAuth, session: SessionDep) -> CookingRecordOut:
    return _out(_owned(session, auth.user.id, record_id))


@router.post(
    "/{record_id}/revisions",
    response_model=CookingRecordRevisionOut,
    status_code=201,
    responses=ERROR_RESPONSES,
)
def revise_record(
    record_id: IdV4,
    body: CookingRecordRevisionCreate,
    auth: CurrentAuth,
    session: SessionDep,
) -> CookingRecordRevisionOut:
    row = _owned(session, auth.user.id, record_id)
    existing = session.scalar(
        select(CookingRecordRevision).where(
            CookingRecordRevision.owner_id == auth.user.id,
            CookingRecordRevision.revision_id == body.revision_id,
        )
    )
    if existing is not None:
        if existing.record_id != row.id or existing.value != body.value:
            raise ApiError(409, "revision_id_reused", "修订 ID 已用于其他内容")
        return CookingRecordRevisionOut.model_validate(existing, from_attributes=True)
    current = session.scalar(
        select(CookingRecordRevision.revision)
        .where(CookingRecordRevision.record_id == row.id)
        .order_by(CookingRecordRevision.revision.desc())
    )
    revision = CookingRecordRevision(
        owner_id=auth.user.id,
        record_id=row.id,
        revision_id=body.revision_id,
        revision=(current or 0) + 1,
        field=body.field,
        value=body.value,
        note=body.note,
    )
    session.add(revision)
    session.flush()
    _learn_from_record(session, auth.user.id, row)
    session.commit()
    from gramtree.tasks.jobs import run_taste_learning

    run_taste_learning.delay(str(auth.user.id))
    session.refresh(revision)
    return CookingRecordRevisionOut.model_validate(revision, from_attributes=True)


def _learn_from_record(session: Session, owner_id: uuid.UUID, row: CookingRecord) -> None:
    """New feedback revisions update attribution and existing signals once."""
    from gramtree.taste_profiles import learning
    from gramtree.taste_profiles import service as taste_service

    if not learning.automation_enabled(session):
        return
    scale = taste_service.scale_for(session)
    profile = taste_service.locked_profile(session, owner_id, scale)
    revisions = list(
        session.scalars(
            select(CookingRecordRevision).where(
                CookingRecordRevision.record_id == row.id,
                CookingRecordRevision.field == "feedback",
            )
        )
    )
    flavors = learning.feedback_flavors(revisions)
    if flavors:
        existing = session.get(learning.TasteAttribution, row.id)
        if existing is None or existing.decision_source != "user":
            verdict = learning.rule_verdict(session, row.recipe_version_id, owner_id, flavors)
            learning.record_verdict(
                session,
                profile,
                row,
                verdict,
                flavors,
                learning._latest_feedback_revision_id(session, row.id),
            )
    learning.collect_signals(session, profile, row)


@router.get(
    "/{record_id}/history", response_model=CookingRecordHistoryOut, responses=ERROR_RESPONSES
)
def record_history(
    record_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> CookingRecordHistoryOut:
    row = _owned(session, auth.user.id, record_id)
    revisions = session.scalars(
        select(CookingRecordRevision)
        .where(CookingRecordRevision.record_id == row.id)
        .order_by(CookingRecordRevision.revision)
    )
    return CookingRecordHistoryOut(
        items=[
            CookingRecordRevisionOut.model_validate(item, from_attributes=True)
            for item in revisions
        ]
    )
