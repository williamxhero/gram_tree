"""Erasure receipts and irreversible, allowlisted statistical buckets.

Anonymous buckets never retain source event/record IDs or account identifiers.
Active-account dedup receipts only prevent repeat contributions; they have no
pointer to a bucket and are erased with the account.
"""

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.db import Base


class AccountDeletion(Base):
    __tablename__ = "account_deletions"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    public_recipe_action: Mapped[str | None] = mapped_column(String(32), nullable=True)
    requested_at: Mapped[datetime]
    due_at: Mapped[datetime]
    completed_at: Mapped[datetime | None] = mapped_column(nullable=True, default=None)
    # Fixed step codes and completion timestamps, never deleted payloads/errors.
    steps: Mapped[dict[str, str]] = mapped_column(JSONB, default=dict)


class AnonymousCookingStatistic(Base):
    __tablename__ = "anonymous_cooking_statistics"

    # Digest of the allowlisted statistical dimensions only, not original content.
    bucket: Mapped[str] = mapped_column(String(64), primary_key=True)
    recipe_version_id: Mapped[uuid.UUID] = mapped_column(index=True)
    week: Mapped[date]
    dimensions: Mapped[dict[str, Any]] = mapped_column(JSONB)
    contributions: Mapped[int] = mapped_column(Integer, default=1)


class CookingStatisticDedup(Base):
    __tablename__ = "cooking_statistic_dedup"

    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    recipe_version_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)


class PendingObjectErasure(Base):
    """Durable storage deletion retry; removed as soon as the object is gone."""

    __tablename__ = "pending_object_erasures"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    storage_key: Mapped[str] = mapped_column(String(500), unique=True)
