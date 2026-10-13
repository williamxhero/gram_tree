"""Registered durable writes for cooking records."""

import uuid
from typing import Any

from pydantic import BaseModel, ConfigDict
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.events.sync_contract import (
    WriteApplication,
    WriteDeferred,
    WriteEnvelope,
    WriteFailure,
    WriteResourceResult,
    WriteTypeSpec,
)
from gramtree.records import context as record_context
from gramtree.records.models import CookingRecord
from gramtree.records.schemas import CookingRecordCreate
from gramtree.records.service import record_created_event


class CookingRecordWritePayload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    record: CookingRecordCreate


def _validate(payload: dict[str, Any]) -> BaseModel:
    return CookingRecordWritePayload.model_validate(payload)


def _authorize(session: Session, owner: uuid.UUID, payload: BaseModel) -> None:
    parsed = CookingRecordWritePayload.model_validate(payload).record
    if parsed.verification == "cooking_mode":
        raise WriteFailure("verification_unavailable")
    if parsed.recipe_version_id is not None:
        from gramtree.recipes.models import Recipe, RecipeVersion

        version = session.get(RecipeVersion, parsed.recipe_version_id)
        if version is None:
            raise WriteDeferred("reference_not_arrived")
        recipe = session.get(Recipe, version.recipe_id)
        if recipe is None or recipe.owner_id != owner:
            raise WriteFailure("reference_forbidden")
    if parsed.source == "cooking_session" and parsed.recipe_version_id is None:
        raise WriteFailure("reference_required")
    try:
        record_context.build(session, owner, parsed.co_diner_ids, session.info["settings"])
    except Exception as exc:
        raise WriteFailure("invalid_co_diners") from exc


def _resolve(
    session: Session,
    owner: uuid.UUID,
    payload: BaseModel,
    dependencies: dict[uuid.UUID, WriteResourceResult],
) -> BaseModel:
    _authorize(session, owner, payload)
    return payload


def _apply(
    session: Session,
    owner: uuid.UUID,
    envelope: WriteEnvelope,
    payload: BaseModel,
    now,
) -> WriteApplication:
    parsed = CookingRecordWritePayload.model_validate(payload).record
    taste_summary, co_diner_ids = record_context.build(
        session, owner, parsed.co_diner_ids, session.info["settings"]
    )
    existing = session.scalar(
        select(CookingRecord).where(
            CookingRecord.owner_id == owner,
            CookingRecord.client_id == parsed.client_id,
        )
    )
    if existing is None:
        row = CookingRecord(
            owner_id=owner,
            client_id=parsed.client_id,
            recipe_id=parsed.recipe_id,
            recipe_version_id=parsed.recipe_version_id,
            dish_name=parsed.dish_name,
            source=parsed.source,
            # A client cannot self-attest the trusted cooking-mode outcome.
            # The source still counts as cooked, while verification remains
            # unverified until a server-owned session handoff exists.
            verification="unverified",
            counts_as_cooked=parsed.source != "dining",
            meal=parsed.meal,
            occurred_at=parsed.occurred_at or now,
            snapshot=parsed.snapshot,
            adjustments=parsed.adjustments,
            source_context=parsed.source_context,
            taste_summary=taste_summary,
            co_diner_ids=[str(item) for item in co_diner_ids],
        )
        session.add(row)
        session.flush()
        record_created_event(session, owner, row)
    else:
        if (
            existing.recipe_version_id != parsed.recipe_version_id
            or existing.source != parsed.source
        ):
            raise WriteFailure("record_id_reused")
        row = existing
    return WriteApplication(
        result=WriteResourceResult(resource_type="cooking.record", resource_id=row.id),
        facts=[{"record_id": str(row.id), "client_id": str(row.client_id)}],
    )


cooking_record_write_spec = WriteTypeSpec(
    write_type="cooking_record.create",
    conflict_rule="append_only",
    validate=_validate,
    authorize=_authorize,
    resolve_references=_resolve,
    apply=_apply,
)
