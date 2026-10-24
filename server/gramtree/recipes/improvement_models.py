"""Working copies, immutable creation facts and owner-scoped retry receipts."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class ImprovementDraft(Base):
    __tablename__ = "improvement_drafts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    source_recipe_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("recipes.id"))
    source_version_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("recipe_versions.id"))
    snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB)
    dish_name: Mapped[str] = mapped_column(String(200))
    ai_assisted: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class RecipeImprovementFact(Base):
    """Immutable lineage; erased private branches retain only anonymous statistics."""

    __tablename__ = "recipe_improvement_facts"

    recipe_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    version_id: Mapped[uuid.UUID] = mapped_column()
    owner_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"))
    source_recipe_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("recipes.id"))
    source_version_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("recipe_versions.id"))
    root_recipe_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("recipes.id"))
    source_path: Mapped[list[dict[str, Any]]] = mapped_column(JSONB)
    branch_type: Mapped[str] = mapped_column(String(20))
    conclusion: Mapped[str] = mapped_column(String(20))
    rules_version: Mapped[str] = mapped_column(String(64))
    comparison: Mapped[dict[str, Any]] = mapped_column(JSONB)
    cooking_record_id: Mapped[uuid.UUID | None] = mapped_column(default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class ImprovementReceipt(Base):
    __tablename__ = "improvement_receipts"
    __table_args__ = (UniqueConstraint("owner_id", "request_id", name="uq_improvement_receipt"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    request_id: Mapped[uuid.UUID] = mapped_column()
    fingerprint: Mapped[str] = mapped_column(String(64))
    response: Mapped[dict[str, Any]] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class ImprovementCuration(Base):
    """Only the operator CLI writes this policy input; no user API exists."""

    __tablename__ = "improvement_curation"
    recipe_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE"), primary_key=True
    )
    curated: Mapped[bool] = mapped_column(default=False)
    changed_by: Mapped[str] = mapped_column(String(200))
    reason: Mapped[str] = mapped_column(String(2000))
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)
