"""One private main profile and a shared version/history boundary per account."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import CheckConstraint, ForeignKey, Index, LargeBinary, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class TasteProfile(Base):
    __tablename__ = "taste_profiles"
    __table_args__ = (CheckConstraint("version >= 1", name="ck_taste_profile_version"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True
    )
    version: Mapped[int] = mapped_column(default=1)
    flavors: Mapped[dict[str, Any]] = mapped_column(JSONB)
    local_cuisines: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    ingredient_preferences: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    cooking_constraints: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    sensitive_consent_id: Mapped[uuid.UUID | None] = mapped_column(default=None)
    sensitive_authorization_version: Mapped[int] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)


class OwnerAllergies(Base):
    __tablename__ = "owner_allergies"

    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    ciphertext: Mapped[bytes] = mapped_column(LargeBinary)


class FamilyMember(Base):
    __tablename__ = "family_members"
    __table_args__ = (Index("ix_family_members_owner_created", "owner_id", "created_at", "id"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    ciphertext: Mapped[bytes] = mapped_column(LargeBinary)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class TasteProfileChange(Base):
    __tablename__ = "taste_profile_changes"
    __table_args__ = (
        Index("ix_taste_changes_owner_created", "owner_id", "created_at", "id"),
        CheckConstraint("status IN ('active', 'reverted')", name="ck_taste_change_status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("taste_profiles.id", ondelete="CASCADE")
    )
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    version: Mapped[int]
    field: Mapped[str] = mapped_column(String(100))
    old_value: Mapped[dict[str, Any]] = mapped_column(JSONB)
    new_value: Mapped[dict[str, Any]] = mapped_column(JSONB)
    reason: Mapped[str] = mapped_column(String(200))
    source: Mapped[str] = mapped_column(String(32))
    status: Mapped[str] = mapped_column(String(16), default="active")
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
