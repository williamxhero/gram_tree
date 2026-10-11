"""Personal-measure adapter for the shared field adjudication contract."""

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, model_validator
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from gramtree.core.ids import IdV4
from gramtree.events.field_adjudication import FieldEdit, FieldEntity, adjudicate, lock_entity
from gramtree.events.sync_contract import (
    WriteApplication,
    WriteDeferred,
    WriteEnvelope,
    WriteFailure,
    WriteResourceResult,
    WriteTypeSpec,
)
from gramtree.recipes.measure_models import PersonalMeasure

RESOURCE_TYPE = "personal_measure"


class MeasureChange(BaseModel):
    model_config = ConfigDict(extra="forbid")
    resource_id: IdV4
    action: Literal["create", "update", "delete"]
    fields: dict[str, FieldEdit]

    @model_validator(mode="after")
    def validate_fields(self):
        from gramtree.recipes.measure_router import PersonalMeasureInput, PersonalMeasureUpdate

        values = {key: edit.value for key, edit in self.fields.items()}
        if self.action == "delete":
            if set(values) != {"deleted"} or values["deleted"] is not True:
                raise ValueError("delete requires a timestamped true tombstone")
        else:
            if not values or any(value is None for value in values.values()):
                raise ValueError("measure fields are non-null; omit fields not edited")
            parsed = (
                PersonalMeasureInput if self.action == "create" else PersonalMeasureUpdate
            ).model_validate(values)
            normalized = parsed.model_dump(exclude_unset=True)
            self.fields = {
                key: edit.model_copy(update={"value": normalized[key]})
                for key, edit in self.fields.items()
            }
        return self


def validate(payload: dict) -> BaseModel:
    return MeasureChange.model_validate(payload)


def authorize(session: Session, owner: uuid.UUID, payload: BaseModel) -> None:
    parsed = MeasureChange.model_validate(payload)
    row = session.get(PersonalMeasure, parsed.resource_id)
    if row is not None and row.owner_id != owner:
        raise WriteFailure("reference_forbidden")


def resolve(
    session: Session,
    owner: uuid.UUID,
    payload: BaseModel,
    dependencies: dict[uuid.UUID, WriteResourceResult],
) -> BaseModel:
    parsed = MeasureChange.model_validate(payload)
    for result in dependencies.values():
        if result.resource_type == RESOURCE_TYPE and result.resource_id != parsed.resource_id:
            raise WriteFailure("dependency_resource_mismatch")
    return parsed


def lock_owner(session: Session, owner: uuid.UUID) -> None:
    # Serialize snapshot evidence with every measure mutation through commit.
    lock_entity(session, "personal_measure_owner", owner)


def apply(
    session: Session, owner: uuid.UUID, envelope: WriteEnvelope, payload: BaseModel, now: datetime
) -> WriteApplication:
    parsed = MeasureChange.model_validate(payload)
    lock_owner(session, owner)
    lock_entity(session, RESOURCE_TYPE, parsed.resource_id)
    # Authorize again after the entity lock: concurrent creates cannot claim
    # another account's stable identity between the preflight and mutation.
    session.expire_all()
    authorize(session, owner, parsed)
    row = session.get(PersonalMeasure, parsed.resource_id)
    if row is None and parsed.action != "create":
        raise WriteDeferred("reference_not_arrived")
    if row is not None and parsed.action == "create":
        raise WriteFailure("resource_already_exists")
    entity = session.get(FieldEntity, (RESOURCE_TYPE, parsed.resource_id))
    if entity is None:
        entity = FieldEntity(
            resource_type=RESOURCE_TYPE,
            resource_id=parsed.resource_id,
            owner_id=owner,
            values={}
            if row is None
            else {"name": row.name, "kind": row.kind, "capacity_ml": row.capacity_ml},
            clocks={}
            if row is None
            else {
                key: {
                    "time": row.updated_at.isoformat(),
                    "write_id": "00000000-0000-0000-0000-000000000000",
                }
                for key in ("name", "kind", "capacity_ml")
            },
            deleted=row is not None and row.deleted_at is not None,
        )
        session.add(entity)
    decision = adjudicate(session, entity, envelope.write_id, parsed.fields)
    if row is None:
        row = PersonalMeasure(
            id=parsed.resource_id, owner_id=owner, **decision.values, created_at=now, updated_at=now
        )
        session.add(row)
    else:
        for key, value in decision.values.items():
            setattr(row, key, value)
        if decision.changes:
            row.updated_at = now
        if decision.deleted and row.deleted_at is None:
            row.deleted_at = now
    try:
        session.flush()
    except IntegrityError as exc:
        raise WriteFailure("measure_name_taken") from exc
    values = {
        "id": str(row.id),
        "name": row.name,
        "kind": row.kind,
        "capacity_ml": row.capacity_ml,
        "created_at": row.created_at.isoformat(),
        "updated_at": row.updated_at.isoformat(),
        "deleted": decision.deleted,
        "applied": bool(decision.changes),
        "field_outcomes": decision.outcomes,
    }
    result = WriteResourceResult(resource_type=RESOURCE_TYPE, resource_id=row.id, values=values)
    facts = (
        [{"resource_type": RESOURCE_TYPE, "resource_id": str(row.id), "changes": decision.changes}]
        if decision.changes
        else []
    )
    return WriteApplication(result=result, facts=facts)


measure_write_spec = WriteTypeSpec(
    write_type="personal_measure.change",
    conflict_rule="field_last_write_with_history",
    validate=validate,
    authorize=authorize,
    resolve_references=resolve,
    apply=apply,
)
