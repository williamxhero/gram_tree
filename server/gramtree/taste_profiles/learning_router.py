"""SPEC-005.3 learning, attribution and change-control API."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import (
    Page,
    PageParams,
    check_limit,
    decode_cursor,
    encode_cursor,
    page_params,
)
from gramtree.deps import SessionDep
from gramtree.records.models import CookingRecord
from gramtree.runtime_config import service as config
from gramtree.taste_profiles import learning, service
from gramtree.taste_profiles.models import TasteProfileChange
from gramtree.taste_profiles.schemas import (
    AttributionAnswer,
    AttributionOut,
    AttributionStateOut,
    AutomationOut,
    FieldLockWrite,
    LearningRunOut,
    TasteChangeStatusOut,
    TasteProfileChangeOut,
)

router = APIRouter(prefix="/me/taste-profile", tags=["taste-profile"])
# Record-scoped attribution lives on the record itself.
record_router = APIRouter(prefix="/records", tags=["records"])
_ERRORS = {
    **ERROR_RESPONSES,
    401: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    409: {"model": ErrorResponse},
    422: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}
PageDep = Annotated[PageParams, Depends(page_params)]


def _out(row: TasteProfileChange) -> TasteProfileChangeOut:
    return TasteProfileChangeOut.model_validate(row)


def _state(row: learning.TasteAttribution) -> AttributionStateOut:
    return AttributionStateOut(
        attribution=AttributionOut.model_validate(learning.attribution_out(row)),
        reason_text=learning.qualitative_reason(row),
    )


@router.get("/automation", response_model=AutomationOut, responses=_ERRORS)
def get_automation(auth: CurrentAuth, session: SessionDep) -> AutomationOut:
    return AutomationOut(
        automatic_learning=learning.automation_enabled(session),
        save_to_taste=learning.save_to_taste_enabled(session),
    )


@record_router.put(
    "/{record_id}/attribution",
    response_model=AttributionStateOut,
    responses=_ERRORS,
)
def answer_attribution(
    record_id: IdV4,
    body: AttributionAnswer,
    auth: CurrentAuth,
    session: SessionDep,
) -> AttributionStateOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    record = session.scalar(
        select(CookingRecord).where(
            CookingRecord.id == record_id, CookingRecord.owner_id == auth.user.id
        )
    )
    if record is None:
        raise NotFound()
    revisions = list(
        session.scalars(
            select(learning.CookingRecordRevision).where(
                learning.CookingRecordRevision.record_id == record.id,
                learning.CookingRecordRevision.field == "feedback",
            )
        )
    )
    flavors = learning.feedback_flavors(revisions)
    row = learning.upsert_answer(
        session,
        profile,
        record,
        body.answer,
        feedback_revision_id=learning._latest_feedback_revision_id(session, record.id),
        flavors=flavors,
    )
    learning.collect_signals(session, profile, record)
    session.commit()
    return _state(row)


@record_router.get(
    "/{record_id}/attribution", response_model=AttributionStateOut, responses=_ERRORS
)
def get_attribution(record_id: IdV4, auth: CurrentAuth, session: SessionDep) -> AttributionStateOut:
    record = session.scalar(
        select(CookingRecord).where(
            CookingRecord.id == record_id, CookingRecord.owner_id == auth.user.id
        )
    )
    if record is None:
        raise NotFound()
    row = session.get(learning.TasteAttribution, record.id)
    if row is None:
        revisions = list(
            session.scalars(
                select(learning.CookingRecordRevision).where(
                    learning.CookingRecordRevision.record_id == record.id,
                    learning.CookingRecordRevision.field == "feedback",
                )
            )
        )
        flavors = learning.feedback_flavors(revisions)
        if flavors:
            row = learning.record_verdict(
                session,
                service.locked_profile(session, auth.user.id, service.scale_for(session)),
                record,
                learning.rule_verdict(session, record.recipe_version_id, auth.user.id, flavors),
                flavors,
                learning._latest_feedback_revision_id(session, record.id),
            )
            session.commit()
    if row is None or row.owner_id != auth.user.id:
        return AttributionStateOut(attribution=None, reason_text="")
    return _state(row)


@router.post("/learning/run", response_model=LearningRunOut, responses=_ERRORS)
def run_learning(auth: CurrentAuth, session: SessionDep) -> LearningRunOut:
    if not learning.automation_enabled(session):
        raise NotFound()
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    records = list(
        session.scalars(
            select(CookingRecord).where(CookingRecord.owner_id == auth.user.id).limit(500)
        )
    )
    for record in records:
        learning.collect_signals(session, profile, record)
    outcome = learning.apply_learning(session, profile)
    session.commit()
    return LearningRunOut(
        applied_changes=[_out(row) for row in outcome.applied],
        pending_suggestions=[_out(row) for row in outcome.pending],
        signals_considered=outcome.signals_considered,
    )


@router.get("/changes/pending", response_model=Page[TasteProfileChangeOut], responses=_ERRORS)
def list_pending_changes(
    auth: CurrentAuth, session: SessionDep, page: PageDep
) -> Page[TasteProfileChangeOut]:
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(TasteProfileChange).where(
        TasteProfileChange.owner_id == auth.user.id,
        TasteProfileChange.status == "pending",
    )
    if page.cursor:
        timestamp, row_id = decode_cursor(page.cursor)
        query = query.where(
            (TasteProfileChange.created_at < timestamp)
            | ((TasteProfileChange.created_at == timestamp) & (TasteProfileChange.id < row_id))
        )
    rows = list(
        session.scalars(
            query.order_by(
                TasteProfileChange.created_at.desc(), TasteProfileChange.id.desc()
            ).limit(page.limit + 1)
        )
    )
    more = len(rows) > page.limit
    rows = rows[: page.limit]
    return Page[TasteProfileChangeOut](
        items=[_out(row) for row in rows],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if more else None,
    )


@router.post(
    "/changes/{change_id}/confirm", response_model=TasteProfileChangeOut, responses=_ERRORS
)
def confirm_change(
    change_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> TasteProfileChangeOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    row = learning.owned_change(session, auth.user.id, change_id)
    learning.confirm_change(session, profile, row)
    session.commit()
    session.refresh(row)
    return _out(row)


@router.post("/changes/{change_id}/revert", response_model=TasteProfileChangeOut, responses=_ERRORS)
def revert_change(change_id: IdV4, auth: CurrentAuth, session: SessionDep) -> TasteProfileChangeOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    row = learning.owned_change(session, auth.user.id, change_id)
    learning.revert_change(session, profile, row)
    session.commit()
    session.refresh(row)
    return _out(row)


@router.put("/locks", response_model=AutomationOut, responses=_ERRORS)
def set_field_lock(body: FieldLockWrite, auth: CurrentAuth, session: SessionDep) -> AutomationOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    learning.set_lock(session, profile, body.field, body.locked)
    session.commit()
    return AutomationOut(
        automatic_learning=learning.automation_enabled(session),
        save_to_taste=learning.save_to_taste_enabled(session),
    )


@router.get("/change-facts", response_model=TasteChangeStatusOut, responses=_ERRORS)
def change_facts(auth: CurrentAuth, session: SessionDep) -> TasteChangeStatusOut:
    applied, reverted = learning.revert_rate(session, auth.user.id)
    return TasteChangeStatusOut(auto_changes=applied, auto_reverted=reverted)


@router.post(
    "/records/{record_id}/save-to-taste",
    response_model=list[TasteProfileChangeOut],
    responses=_ERRORS,
)
def save_to_taste(
    record_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> list[TasteProfileChangeOut]:
    if not learning.save_to_taste_enabled(session):
        raise NotFound()
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    record = session.scalar(
        select(CookingRecord).where(
            CookingRecord.id == record_id, CookingRecord.owner_id == auth.user.id
        )
    )
    if record is None:
        raise NotFound()
    changes = [item for item in (record.adjustments or []) if isinstance(item, dict)]
    # Materialize the record's ordinary evidence first so explicit-save can
    # consume exactly the matching adjustment signal in the same transaction.
    learning.collect_signals(session, profile, record)
    rows = learning.explicit_save_change(session, profile, record, changes)
    session.commit()
    return [_out(row) for row in rows]


__all__ = ["record_router", "router"]
