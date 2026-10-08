"""Versioned public envelopes and registered handler protocol for all offline writes."""

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp

ConflictRule = Literal["append_only", "field_last_write_with_history", "preserve_both"]


class WriteEnvelope(BaseModel):
    model_config = ConfigDict(extra="forbid")

    format_version: Literal[1] = Field(
        description="Immutable envelope format, independent of business version"
    )
    write_type: str = Field(min_length=1, max_length=100)
    write_id: IdV4 = Field(
        description="UUID v4 delivery ID, not the referenced business resource ID"
    )
    owner_id: IdV4 = Field(
        description="Bound at local creation; must equal the authenticated account"
    )
    device_time: Timestamp
    payload: dict[str, Any]
    dependencies: list[IdV4] = Field(default_factory=list, max_length=100)


class WriteResourceResult(BaseModel):
    resource_type: str
    resource_id: IdV4


class WriteResult(BaseModel):
    write_id: IdV4
    status: Literal["confirmed", "already_processed", "deferred", "conflict", "failed"]
    reason_code: str | None = None
    result: WriteResourceResult | None = None
    # preserve_both handlers supply both copies here; never overwrite on conflict.
    conflict: dict[str, Any] | None = None


@dataclass(frozen=True)
class WriteApplication:
    result: WriteResourceResult
    facts: list[dict[str, Any]]


@dataclass(frozen=True)
class WriteTypeSpec:
    """Handlers never commit: business change, receipt and facts commit together.

    validate handles the business version/content; authorize is also called on
    replays BEFORE revealing a receipt; resolve_references receives only confirmed
    same-owner dependency results, not arbitrary client-declared resource IDs.
    apply runs under the per-write transaction lock. A future conflict handler can
    raise WriteConflict carrying both copies without committing a mutation.
    """

    write_type: str
    conflict_rule: ConflictRule
    validate: Callable[[dict[str, Any]], BaseModel]
    authorize: Callable[[Session, uuid.UUID, BaseModel], None]
    resolve_references: Callable[
        [Session, uuid.UUID, BaseModel, dict[uuid.UUID, WriteResourceResult]], BaseModel
    ]
    apply: Callable[[Session, uuid.UUID, WriteEnvelope, BaseModel, datetime], WriteApplication]


class WriteFailure(Exception):
    def __init__(self, code: str) -> None:
        self.code = code


class WriteDeferred(WriteFailure):
    pass


class WriteConflict(Exception):
    def __init__(self, copies: dict[str, Any]) -> None:
        self.copies = copies
