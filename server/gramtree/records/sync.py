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
from gramtree.records.service import matches_submission, record_created_event


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
        from gramtree.recipes.models import RecipeVersion

        version = session.get(RecipeVersion, parsed.recipe_version_id)
        if version is None:
            raise WriteDeferred("reference_not_arrived")
        from gramtree.core.errors import ApiError
        from gramtree.recipes.publication import readable_version

        try:
            recipe, _ = readable_version(session, owner, version.recipe_id, version.id)
        except ApiError as exc:
            from gramtree.recipes.models import Recipe
            from gramtree.records.completion import completed_context

            if exc.status != 404 or parsed.completion is None:
                raise WriteFailure("reference_forbidden") from exc
            try:
                completed_context(owner, parsed, session.info["settings"])
            except ApiError as proof_error:
                raise WriteFailure(proof_error.code) from proof_error
            recipe = session.get(Recipe, version.recipe_id)
            if recipe is None or parsed.recipe_id != recipe.id:
                raise WriteFailure("reference_forbidden") from exc
        if parsed.recipe_id is not None and parsed.recipe_id != recipe.id:
            raise WriteFailure("reference_mismatch")
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
    from gramtree.core.errors import ApiError
    from gramtree.recipes.models import RecipeVersion
    from gramtree.records.completion import completed_context

    parsed = CookingRecordWritePayload.model_validate(payload).record
    try:
        verification, source_context = completed_context(owner, parsed, session.info["settings"])
    except ApiError as exc:
        raise WriteFailure(exc.code) from exc
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
        recipe_id = parsed.recipe_id
        if parsed.recipe_version_id is not None:
            version = session.get(RecipeVersion, parsed.recipe_version_id)
            if version is None:
                raise WriteDeferred("reference_not_arrived")
            recipe_id = version.recipe_id
        row = CookingRecord(
            owner_id=owner,
            client_id=parsed.client_id,
            recipe_id=recipe_id,
            recipe_version_id=parsed.recipe_version_id,
            dish_name=parsed.dish_name,
            source=parsed.source,
            verification=verification,
            counts_as_cooked=parsed.source != "dining"
            and (parsed.completion is None or bool(parsed.completion.completed_steps)),
            meal=parsed.meal,
            occurred_at=parsed.occurred_at
            or (parsed.completion.finished_at if parsed.completion else now),
            snapshot=parsed.snapshot,
            adjustments=parsed.adjustments,
            source_context=source_context,
            taste_summary=taste_summary,
            co_diner_ids=[str(item) for item in co_diner_ids],
            photos=parsed.photos,
        )
        session.add(row)
        session.flush()
        record_created_event(session, owner, row)
        from gramtree.recipes.publication import record_completed

        record_completed(session, session.info["settings"], row)
    else:
        if not matches_submission(existing, parsed, verification, source_context):
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
