"""Durable delivery metadata for registered writes on the experience pipeline."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.db import Base


class WriteReceipt(Base):
    __tablename__ = "write_receipts"

    write_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    write_type: Mapped[str] = mapped_column(String(100))
    fingerprint: Mapped[str] = mapped_column(String(64))
    dependencies: Mapped[list[str]] = mapped_column(JSONB)
    status: Mapped[str] = mapped_column(String(32))
    reason_code: Mapped[str | None] = mapped_column(String(100))
    result: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    received_at: Mapped[datetime]


class WriteFactOutbox(Base):
    __tablename__ = "write_fact_outbox"

    # Exactly one fact bundle per committed write; redelivery uses the same ID.
    write_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("write_receipts.write_id"), primary_key=True
    )
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    facts: Mapped[list[dict[str, Any]]] = mapped_column(JSONB)
    created_at: Mapped[datetime]
