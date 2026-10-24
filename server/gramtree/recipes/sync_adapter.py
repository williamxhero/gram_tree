"""Manual recipe saves on the account-scoped durable write pipeline."""

import uuid
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator
from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError
from gramtree.core.ids import IdV4
from gramtree.events.sync_contract import (
    WriteApplication,
    WriteConflict,
    WriteDeferred,
    WriteEnvelope,
    WriteFailure,
    WriteResourceResult,
    WriteTypeSpec,
)
from gramtree.recipes import improvements as improvement_service
from gramtree.recipes import service
from gramtree.recipes.improvement_schemas import (
    ImprovementPreviewInput,
    ImprovementSaveInput,
    RecordVersionSaveInput,
)
from gramtree.recipes.models import Recipe, RecipeVersion
from gramtree.recipes.schemas import RecipeVersionCreate
from gramtree.records.models import CookingRecord
from gramtree.settings import Settings


class RecipeSavePayload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    recipe_id: IdV4
    candidate_version_id: IdV4
    baseline_version_id: IdV4 | None = None
    baseline_write_id: IdV4 | None = None
    candidate: RecipeVersionCreate

    @model_validator(mode="after")
    def manual_candidate(self) -> "RecipeSavePayload":
        if (self.baseline_version_id is None) == (self.baseline_write_id is None):
            raise ValueError("Exactly one baseline resource or confirmed write is required")
        if (
            self.candidate.ai_assisted
            or self.candidate.image_ids
            or self.candidate.base_version_id is not None
            or self.candidate.expected_current_version_id is not None
        ):
            raise ValueError(
                "Offline manual saves cannot forge AI, staged images or baseline fences"
            )
        return self


def _validate(payload: dict[str, Any]) -> BaseModel:
    return RecipeSavePayload.model_validate(payload)


def _authorize(session: Session, owner: uuid.UUID, payload: BaseModel) -> None:
    parsed = RecipeSavePayload.model_validate(payload)
    recipe = session.scalar(
        select(Recipe).where(Recipe.id == parsed.recipe_id, Recipe.owner_id == owner)
    )
    if recipe is None:
        raise WriteFailure("recipe_not_writable")
    if parsed.baseline_version_id is not None:
        version = session.get(RecipeVersion, parsed.baseline_version_id)
        if version is not None and version.recipe_id != recipe.id:
            raise WriteFailure("reference_forbidden")


def _resolve(
    session: Session,
    owner: uuid.UUID,
    payload: BaseModel,
    dependencies: dict[uuid.UUID, WriteResourceResult],
) -> BaseModel:
    parsed = RecipeSavePayload.model_validate(payload)
    baseline_id = parsed.baseline_version_id
    if parsed.baseline_write_id is not None:
        confirmed = dependencies.get(parsed.baseline_write_id)
        if confirmed is None:
            raise WriteFailure("baseline_dependency_required")
        if confirmed.resource_type != "recipe.version":
            raise WriteFailure("baseline_dependency_type")
        baseline_id = confirmed.resource_id
    assert baseline_id is not None
    version = session.get(RecipeVersion, baseline_id)
    if version is None:
        raise WriteDeferred("reference_not_arrived")
    if version.recipe_id != parsed.recipe_id:
        raise WriteFailure("reference_forbidden")
    # Keep the immutable envelope untouched; this is a transaction-local resolved
    # payload whose resource ID came from a confirmed same-owner typed dependency.
    return parsed.model_copy(update={"baseline_version_id": baseline_id, "baseline_write_id": None})


def recipe_version_write_spec(settings: Settings, redis: Redis) -> WriteTypeSpec:
    def apply(
        session: Session,
        owner: uuid.UUID,
        envelope: WriteEnvelope,
        payload: BaseModel,
        now: datetime,
    ) -> WriteApplication:
        parsed = RecipeSavePayload.model_validate(payload)
        assert parsed.baseline_version_id is not None
        recipe = session.scalar(
            select(Recipe)
            .where(Recipe.id == parsed.recipe_id, Recipe.owner_id == owner)
            .with_for_update()
            .execution_options(populate_existing=True)
        )
        user = session.get(User, owner)
        if recipe is None or user is None:
            raise WriteFailure("recipe_not_writable")
        if parsed.baseline_version_id != recipe.current_version_id:
            remote = service.get_recipe(session, settings, user, recipe.id)
            baseline = service.get_version(
                session, settings, user, recipe.id, parsed.baseline_version_id
            )
            raise WriteConflict(
                {
                    "recipe_id": str(recipe.id),
                    "candidate_version_id": str(parsed.candidate_version_id),
                    "baseline_version_id": str(parsed.baseline_version_id),
                    "baseline": baseline.model_dump(mode="json"),
                    "local": parsed.candidate.model_dump(mode="json"),
                    "remote": remote.model_dump(mode="json"),
                }
            )
        if session.get(RecipeVersion, parsed.candidate_version_id) is not None:
            raise WriteFailure("candidate_version_id_reused")
        body = parsed.candidate.model_copy(
            update={
                "base_version_id": parsed.baseline_version_id,
                "expected_current_version_id": parsed.baseline_version_id,
            }
        )
        try:
            detail = service.mutate_version(
                session,
                redis,
                settings,
                user,
                recipe.id,
                body,
                version_id=parsed.candidate_version_id,
            )
        except ApiError as error:
            raise WriteFailure(error.code) from error
        return WriteApplication(
            result=WriteResourceResult(
                resource_type="recipe.version",
                resource_id=detail.version.id,
                values={"detail": detail.model_dump(mode="json")},
            ),
            # mutate_version enqueues the existing authoritative recipe save
            # outbox. A second generic fact would double count the same save.
            facts=[],
        )

    return WriteTypeSpec(
        write_type="recipe_version.save",
        conflict_rule="preserve_both",
        validate=_validate,
        authorize=_authorize,
        resolve_references=_resolve,
        apply=apply,
    )


class RecordImprovementPayload(BaseModel):
    """The exact user choice needed to replay a cooking-record save."""

    model_config = ConfigDict(extra="forbid")

    record_id: IdV4 | None = None
    record_write_id: IdV4 | None = None
    recipe_id: IdV4
    source_version_id: IdV4
    change_note: str = Field(default="临场调整", max_length=2000)
    microadjust_choice: Literal["branch", "taste"] | None = None
    expected_profile_version: int | None = Field(default=None, ge=1)

    @model_validator(mode="after")
    def record_reference(self) -> "RecordImprovementPayload":
        if self.record_id is None and self.record_write_id is None:
            raise ValueError("A record resource or producing write is required")
        return self


def _record_improvement_validate(payload: dict[str, Any]) -> BaseModel:
    return RecordImprovementPayload.model_validate(payload)


def _record_improvement_authorize(session: Session, owner: uuid.UUID, payload: BaseModel) -> None:
    parsed = RecordImprovementPayload.model_validate(payload)
    # A typed prerequisite may not have arrived yet. Resolve it only after the
    # sync pipeline verifies its immutable, same-owner confirmation receipt.
    if parsed.record_id is None:
        return
    record = session.scalar(
        select(CookingRecord).where(
            CookingRecord.id == parsed.record_id,
            CookingRecord.owner_id == owner,
        )
    )
    if record is None:
        raise WriteFailure("record_not_writable")
    if record.recipe_id != parsed.recipe_id or record.recipe_version_id != parsed.source_version_id:
        raise WriteFailure("reference_forbidden")


def _record_improvement_resolve(
    session: Session,
    owner: uuid.UUID,
    payload: BaseModel,
    dependencies: dict[uuid.UUID, WriteResourceResult],
) -> BaseModel:
    parsed = RecordImprovementPayload.model_validate(payload)
    if parsed.record_write_id is not None:
        producer = dependencies.get(parsed.record_write_id)
        if producer is None:
            raise WriteFailure("record_dependency_required")
        if producer.resource_type != "cooking.record":
            raise WriteFailure("record_dependency_type")
        if parsed.record_id is not None and parsed.record_id != producer.resource_id:
            raise WriteFailure("record_dependency_mismatch")
        parsed = parsed.model_copy(update={"record_id": producer.resource_id})
    _record_improvement_authorize(session, owner, parsed)
    return parsed


def record_improvement_write_spec(settings: Settings, redis: Redis) -> WriteTypeSpec:
    def apply(
        session: Session,
        owner: uuid.UUID,
        envelope: WriteEnvelope,
        payload: BaseModel,
        now: datetime,
    ) -> WriteApplication:
        del now
        parsed = RecordImprovementPayload.model_validate(payload)
        assert parsed.record_id is not None
        recipe = session.get(Recipe, parsed.recipe_id)
        user = session.get(User, owner)
        if recipe is None or user is None:
            raise WriteFailure("record_not_writable")
        if recipe.owner_id != owner and parsed.microadjust_choice is None:
            try:
                preview = improvement_service.preview(
                    session,
                    settings,
                    user,
                    parsed.recipe_id,
                    ImprovementPreviewInput(
                        source_version_id=parsed.source_version_id,
                        from_cooking_record_id=parsed.record_id,
                        change_note=parsed.change_note,
                    ),
                )
            except ApiError as error:
                raise WriteFailure(error.code) from error
            if preview.microadjust_prompt is not None:
                # Confirm the retained intent, not a branch or unchosen taste update.
                return WriteApplication(
                    result=WriteResourceResult(
                        resource_type="record.improvement",
                        resource_id=parsed.record_id,
                        values={"preview": preview.model_dump(mode="json")},
                    ),
                    facts=[],
                )
        if recipe.owner_id == owner:
            body = RecordVersionSaveInput(
                request_id=envelope.write_id,
                change_note=parsed.change_note,
            )
            try:
                response = improvement_service.save_record_version(
                    session,
                    redis,
                    settings,
                    user,
                    parsed.record_id,
                    body,
                    commit=False,
                )
            except ApiError as error:
                raise WriteFailure(error.code) from error
        else:
            body = ImprovementSaveInput(
                request_id=envelope.write_id,
                source_version_id=parsed.source_version_id,
                from_cooking_record_id=parsed.record_id,
                change_note=parsed.change_note,
                microadjust_choice=parsed.microadjust_choice,
                expected_profile_version=parsed.expected_profile_version,
            )
            try:
                response = improvement_service.save(
                    session,
                    redis,
                    settings,
                    user,
                    parsed.recipe_id,
                    body,
                    commit=False,
                )
            except ApiError as error:
                raise WriteFailure(error.code) from error
        return WriteApplication(
            result=WriteResourceResult(
                resource_type="record.improvement",
                resource_id=parsed.record_id,
                values={"response": response.model_dump(mode="json")},
            ),
            facts=[],
        )

    return WriteTypeSpec(
        write_type="record_improvement.save",
        conflict_rule="preserve_both",
        validate=_record_improvement_validate,
        authorize=_record_improvement_authorize,
        resolve_references=_record_improvement_resolve,
        apply=apply,
    )
