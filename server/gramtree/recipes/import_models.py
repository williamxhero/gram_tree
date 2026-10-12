"""Private owner-scoped source records for imported recipes."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class RecipeImport(Base):
    __tablename__ = "recipe_imports"
    __table_args__ = (
        Index("ix_recipe_imports_owner_created", "owner_id", "created_at"),
        Index("ix_recipe_imports_owner_source", "owner_id", "source_url"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    recipe_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipes.id", ondelete="SET NULL"), default=None
    )
    mode: Mapped[str] = mapped_column(String(16))
    source_url: Mapped[str | None] = mapped_column(Text, default=None)
    source_platform: Mapped[str] = mapped_column(String(255), default="unknown")
    original_ciphertext: Mapped[bytes] = mapped_column(nullable=False)
    status: Mapped[str] = mapped_column(String(16))
    reason: Mapped[str | None] = mapped_column(String(64), default=None)
    field_states: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    image_count: Mapped[int] = mapped_column(default=0)
    failed_image_count: Mapped[int] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
