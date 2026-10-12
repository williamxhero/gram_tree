"""做菜记录的最小服务端模型（SPEC-004.2 #186）。"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class CookingRecord(Base):
    __tablename__ = "cooking_records"
    __table_args__ = (
        UniqueConstraint("owner_id", "client_id", name="uq_cooking_records_owner_client"),
        Index("ix_cooking_records_owner_created", "owner_id", "created_at", "id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    client_id: Mapped[uuid.UUID] = mapped_column()
    recipe_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)
    recipe_version_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)
    dish_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    source: Mapped[str] = mapped_column(String(32), default="cooking_session")
    verification: Mapped[str] = mapped_column(String(32), default="unverified")
    # Only server-trusted cooking-session writes may set verification to
    # cooking_mode.  The public create API currently records all accepted
    # writes as unverified and derives this projection from the source.
    counts_as_cooked: Mapped[bool] = mapped_column(default=False)
    meal: Mapped[str | None] = mapped_column(String(16), nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(default=utcnow)
    snapshot: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)
    adjustments: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    source_context: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class CookingRecordRevision(Base):
    __tablename__ = "cooking_record_revisions"
    __table_args__ = (
        UniqueConstraint("owner_id", "revision_id", name="uq_cooking_record_revisions_owner_id"),
        Index("ix_cooking_record_revisions_record_created", "record_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    record_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cooking_records.id", ondelete="CASCADE")
    )
    revision_id: Mapped[uuid.UUID] = mapped_column(default=new_id)
    revision: Mapped[int] = mapped_column(Integer)
    field: Mapped[str] = mapped_column(String(32))
    value: Mapped[dict[str, Any]] = mapped_column(JSONB)
    note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
