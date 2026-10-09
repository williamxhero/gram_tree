"""Offline write registration extends, never bypasses, the experience registry."""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from gramtree.events import service, validation
from gramtree.events.models import Event
from gramtree.events.router import EventCorrelationIds, EventUploadItem, _validate_taste_link
from gramtree.events.sync_contract import (
    WriteApplication,
    WriteDeferred,
    WriteEnvelope,
    WriteFailure,
    WriteResourceResult,
    WriteTypeSpec,
)
from gramtree.recipes.models import Recipe, RecipeVersion
from gramtree.runtime_config import service as config_service


class ExperiencePayload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    event_type: str = Field(min_length=1, max_length=100)
    type_version: int = Field(ge=1)
    device_id: str = Field(min_length=1, max_length=64)
    app_version: str = Field(min_length=1, max_length=32)
    correlation: dict[str, str] = Field(default_factory=dict)
    content: dict[str, Any] = Field(default_factory=dict)


def _validate(payload: dict[str, Any]) -> BaseModel:
    parsed = ExperiencePayload.model_validate(payload)
    rejection = validation.validate_event(
        parsed.event_type, parsed.type_version, dict(parsed.correlation), parsed.content
    )
    if rejection:
        raise WriteFailure(rejection.code)
    # Recipe mutations produce authoritative facts on the server. Composition
    # events also include legitimate client display/cache/fallback observations.
    if parsed.event_type == "recipe.version_saved":
        raise WriteFailure("server_fact_only")
    parsed.correlation = {key: str(uuid.UUID(value)) for key, value in parsed.correlation.items()}
    return parsed


def authorize_envelope(
    session: Session, owner: uuid.UUID, envelope: WriteEnvelope, payload: BaseModel
) -> None:
    """Reuse the upload boundary before looking up even a replay's receipt."""
    if not isinstance(payload, ExperiencePayload):
        return
    item = EventUploadItem(
        id=envelope.write_id,
        event_type=payload.event_type,
        type_version=payload.type_version,
        device_id=payload.device_id,
        device_time=envelope.device_time,
        app_version=payload.app_version,
        correlation=EventCorrelationIds.model_validate(payload.correlation),
        content=payload.content,
    )
    rejection = _validate_taste_link(session, owner, item, payload.correlation)
    if rejection:
        raise WriteFailure(rejection.code)


def _authorize(session: Session, owner: uuid.UUID, payload: BaseModel) -> None:
    parsed = ExperiencePayload.model_validate(payload)
    version_id = parsed.correlation.get("recipe_version_id")
    if version_id:
        version = session.get(RecipeVersion, uuid.UUID(version_id))
        if version is not None:
            recipe = session.get(Recipe, version.recipe_id)
            if recipe is None or recipe.owner_id != owner:
                raise WriteFailure("reference_forbidden")


def _resolve(
    session: Session,
    owner: uuid.UUID,
    payload: BaseModel,
    dependencies: dict[uuid.UUID, WriteResourceResult],
) -> BaseModel:
    # Existing business correlations are resource IDs. Dependency IDs identify
    # writes only: they must never be silently substituted into correlations.
    parsed = ExperiencePayload.model_validate(payload)
    version_id = parsed.correlation.get("recipe_version_id")
    if version_id and session.get(RecipeVersion, uuid.UUID(version_id)) is None:
        raise WriteDeferred("reference_not_arrived")
    return parsed


def _apply(
    session: Session,
    owner: uuid.UUID,
    envelope: WriteEnvelope,
    payload: BaseModel,
    now: datetime,
) -> WriteApplication:
    parsed = ExperiencePayload.model_validate(payload)
    item = service.EventInput(
        id=envelope.write_id,
        event_type=parsed.event_type,
        type_version=parsed.type_version,
        device_id=parsed.device_id,
        device_time=envelope.device_time,
        app_version=parsed.app_version,
        correlation=parsed.correlation,
        content=parsed.content,
    )
    existing = session.get(Event, item.id)
    if existing is not None:
        # An older client may have sent this item on /events/upload already.
        # Compare normalized columns, since old fingerprints preserved offsets.
        previous = service.EventInput(
            id=existing.id,
            event_type=existing.event_type,
            type_version=existing.type_version,
            device_id=existing.device_id,
            device_time=existing.device_time,
            app_version=existing.app_version,
            correlation=existing.correlation,
            content=existing.content,
        )
        if existing.user_id != owner or previous != item:
            raise WriteFailure("write_id_reused")
    else:
        threshold = float(
            config_service.get(session, "events.device_time_suspicious_threshold_seconds")
        )
        session.add(
            Event(
                id=item.id,
                user_id=owner,
                event_type=item.event_type,
                type_version=item.type_version,
                device_id=item.device_id,
                device_time=item.device_time,
                app_version=item.app_version,
                correlation=item.correlation,
                content=item.content,
                content_fingerprint=service._fingerprint(owner, item),
                received_at=now,
                device_time_suspicious=abs((item.device_time - now).total_seconds()) > threshold,
            )
        )
    result = WriteResourceResult(resource_type="experience.event", resource_id=item.id)
    return WriteApplication(result=result, facts=[result.model_dump(mode="json")])


REGISTERED_WRITES: dict[str, WriteTypeSpec] = {}


def register_write_type(spec: WriteTypeSpec) -> None:
    """Called by a business module at application import, never from client data."""
    if spec.write_type in REGISTERED_WRITES:
        raise ValueError(f"write type already registered: {spec.write_type}")
    REGISTERED_WRITES[spec.write_type] = spec


register_write_type(
    WriteTypeSpec(
        write_type="experience.event",
        conflict_rule="append_only",
        validate=_validate,
        authorize=_authorize,
        resolve_references=_resolve,
        apply=_apply,
    )
)
