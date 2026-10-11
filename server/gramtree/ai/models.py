"""Internal AI accounting, generation sessions, and retryable vector indexing."""

import uuid
from datetime import datetime
from typing import Any

from pgvector.sqlalchemy import Vector
from sqlalchemy import ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class AICall(Base):
    __tablename__ = "ai_calls"
    __table_args__ = (Index("ix_ai_calls_quota", "user_id", "capability", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    request_id: Mapped[uuid.UUID] = mapped_column(index=True)
    capability: Mapped[str] = mapped_column(String(32))
    model: Mapped[str] = mapped_column(String(200))
    provider: Mapped[str] = mapped_column(String(200))
    prompt_version: Mapped[str] = mapped_column(String(64))
    content_id: Mapped[uuid.UUID | None] = mapped_column(default=None)
    input_tokens: Mapped[int] = mapped_column(default=0)
    output_tokens: Mapped[int] = mapped_column(default=0)
    cost: Mapped[float] = mapped_column(default=0)
    reserved_cost: Mapped[float] = mapped_column(default=0)
    duration_ms: Mapped[int] = mapped_column(default=0)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    error_code: Mapped[str | None] = mapped_column(String(64), default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class GenerationLog(Base):
    __tablename__ = "ai_generation_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    call_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ai_calls.id", ondelete="CASCADE"))
    input: Mapped[dict[str, Any]] = mapped_column(JSONB)
    output: Mapped[Any | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)


class GenerationRequest(Base):
    __tablename__ = "ai_recipe_requests"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    text: Mapped[str] = mapped_column(Text)
    intent: Mapped[dict[str, Any]] = mapped_column(JSONB)
    questions: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    draft: Mapped[dict[str, Any] | None] = mapped_column(JSONB, default=None)
    saved_recipe_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipes.id", ondelete="SET NULL"), default=None
    )
    selected_recipe_id: Mapped[uuid.UUID | None] = mapped_column(default=None)
    # Versioned owner-checked context receipt for cache invalidation and cleanup.
    # It is metadata only; decrypted sensitive values never enter this column.
    context_dependency: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class RecipeModification(Base):
    """Owned proposal and decision receipt, before any recipe/version is created."""

    __tablename__ = "ai_recipe_modifications"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    recipe_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE"), default=None
    )
    base_version_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="CASCADE"), default=None
    )
    generation_request_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("ai_recipe_requests.id", ondelete="CASCADE"), default=None
    )
    request: Mapped[dict[str, Any]] = mapped_column(JSONB)
    baseline: Mapped[dict[str, Any]] = mapped_column(JSONB)
    proposal: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    decisions: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    revision: Mapped[int] = mapped_column(default=0)
    error: Mapped[str | None] = mapped_column(String(64), default="pending")
    saved_version_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="SET NULL"), default=None
    )
    confirmation: Mapped[dict[str, Any] | None] = mapped_column(JSONB, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class RecipeEmbedding(Base):
    __tablename__ = "recipe_embeddings"

    version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="CASCADE"), primary_key=True
    )
    # Unbounded vector supports replaceable models with different dimensions.
    vector: Mapped[Any | None] = mapped_column(Vector(), nullable=True)
    model: Mapped[str | None] = mapped_column(String(200), default=None)
    text: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(16), default="pending", index=True)
    attempts: Mapped[int] = mapped_column(default=0)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)
