"""Reusable field clocks/history. Call under lock in the business transaction.

Missing fields mean no edit; explicit null is a value (adapters decide whether
it is allowed). Aware device times normalize to UTC; no arrival-time ordering.
Tombstones are terminal: an ordinary field update never resurrects an identity.
"""

import hashlib
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict
from sqlalchemy import ForeignKey, String, UniqueConstraint, select, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, Session, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import Timestamp
from gramtree.db import Base


class FieldEdit(BaseModel):
    model_config = ConfigDict(extra="forbid")
    value: Any
    device_time: Timestamp


class FieldEntity(Base):
    __tablename__ = "field_entities"
    resource_type: Mapped[str] = mapped_column(String(100), primary_key=True)
    resource_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    values: Mapped[dict] = mapped_column(JSONB)
    clocks: Mapped[dict] = mapped_column(JSONB)
    deleted: Mapped[bool] = mapped_column(default=False)


class FieldHistory(Base):
    __tablename__ = "field_history"
    __table_args__ = (UniqueConstraint("resource_type", "resource_id", "write_id", "field"),)
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    resource_type: Mapped[str] = mapped_column(String(100))
    resource_id: Mapped[uuid.UUID]
    write_id: Mapped[uuid.UUID]
    field: Mapped[str] = mapped_column(String(100))
    device_time: Mapped[datetime]
    old_value: Mapped[Any] = mapped_column(JSONB, nullable=True)
    new_value: Mapped[Any] = mapped_column(JSONB, nullable=True)
    outcome: Mapped[str] = mapped_column(String(32))


def lock_entity(session: Session, resource_type: str, resource_id: uuid.UUID) -> None:
    key = int.from_bytes(
        hashlib.sha256(f"field:{resource_type}:{resource_id}".encode()).digest()[:8],
        "big",
        signed=True,
    )
    session.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": key})


@dataclass(frozen=True)
class FieldDecision:
    values: dict[str, Any]
    outcomes: dict[str, str]
    changes: dict[str, Any]
    deleted: bool


def adjudicate(
    session: Session, entity: FieldEntity, write_id: uuid.UUID, edits: dict[str, FieldEdit]
) -> FieldDecision:
    values, clocks = dict(entity.values), dict(entity.clocks)
    outcomes, changes = {}, {}
    # A winning tombstone fences every other field in the same envelope, too;
    # dictionary key order must not change the entity's final projection.
    for field in sorted(edits, key=lambda name: (name != "deleted", name)):
        edit = edits[field]
        previous = session.scalar(
            select(FieldHistory).where(
                FieldHistory.resource_type == entity.resource_type,
                FieldHistory.resource_id == entity.resource_id,
                FieldHistory.write_id == write_id,
                FieldHistory.field == field,
            )
        )
        if previous is not None:
            outcomes[field] = previous.outcome
            continue
        old = entity.deleted if field == "deleted" else values.get(field)
        clock = clocks.get(field)
        wins = clock is None or (edit.device_time, str(write_id)) > (
            datetime.fromisoformat(clock["time"]),
            clock["write_id"],
        )
        if entity.deleted and (field != "deleted" or edit.value is not True):
            outcome = "tombstoned"
        elif not wins:
            outcome = "lost"
        else:
            exists = field == "deleted" or field in values
            outcome = "unchanged" if exists and old == edit.value else "won"
            clocks[field] = {"time": edit.device_time.isoformat(), "write_id": str(write_id)}
            if field == "deleted":
                entity.deleted = bool(edit.value)
            else:
                values[field] = edit.value
            if outcome == "won":
                changes[field] = edit.value
        outcomes[field] = outcome
        session.add(
            FieldHistory(
                owner_id=entity.owner_id,
                resource_type=entity.resource_type,
                resource_id=entity.resource_id,
                write_id=write_id,
                field=field,
                device_time=edit.device_time,
                old_value=old,
                new_value=edit.value,
                outcome=outcome,
            )
        )
    entity.values, entity.clocks = values, clocks
    return FieldDecision(values, outcomes, changes, entity.deleted)
