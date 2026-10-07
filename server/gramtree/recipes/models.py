"""菜、菜谱、不可变版本和成品图的数据表（SPEC-002.2）。"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class Dish(Base):
    """一道菜的稳定身份；同一道菜可以有多个作者的原创菜谱。"""

    __tablename__ = "dishes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    name: Mapped[str] = mapped_column(String(200), unique=True)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class DishAlias(Base):
    """菜的精确别名。别名在全库唯一，避免同一个叫法指向两道菜。"""

    __tablename__ = "dish_aliases"
    __table_args__ = (
        UniqueConstraint("alias", name="uq_dish_aliases_alias"),
        Index("ix_dish_aliases_dish_id", "dish_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    dish_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("dishes.id", ondelete="CASCADE"))
    alias: Mapped[str] = mapped_column(String(200))


class Recipe(Base):
    """一位作者的一份私有菜谱。"""

    __tablename__ = "recipes"
    __table_args__ = (Index("ix_recipes_owner_updated_at", "owner_id", "updated_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    dish_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("dishes.id"), index=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    visibility: Mapped[str] = mapped_column(String(16), default="private")
    current_version_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="SET NULL"), default=None
    )
    # 为后续公开改良版预留；本阶段始终为空且只允许私有菜谱。
    source_version_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="SET NULL"), default=None
    )
    root_recipe_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("recipes.id"), default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)


class RecipeVersion(Base):
    """菜谱的完整快照；保存后不提供修改接口。"""

    __tablename__ = "recipe_versions"
    __table_args__ = (
        UniqueConstraint("recipe_id", "version_number", name="uq_recipe_versions_recipe_number"),
        Index("ix_recipe_versions_recipe_created_at", "recipe_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    recipe_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE"), index=True
    )
    version_number: Mapped[int] = mapped_column(Integer)
    previous_version_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("recipe_versions.id"), default=None
    )
    snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB)
    derived: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    reproducibility: Mapped[dict[str, Any] | None] = mapped_column(JSONB, default=None)
    # Only the current safety index changes on recheck; original evidence stays immutable.
    safety_at_save: Mapped[dict[str, Any] | None] = mapped_column(JSONB, default=None)
    safety_current: Mapped[dict[str, Any] | None] = mapped_column(JSONB, default=None)
    safety_rules_version: Mapped[str | None] = mapped_column(String(64), default=None, index=True)
    # Preserve title/aliases checked at save; global dish metadata can later change.
    safety_context: Mapped[dict[str, Any] | None] = mapped_column(JSONB, default=None)
    edit_operations: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    change_note: Mapped[str] = mapped_column(Text, default="")
    ai_assisted: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class FoodSafetyRuleRelease(Base):
    """Immutable policy fingerprint; reusing a version for changed policy is rejected."""

    __tablename__ = "food_safety_rule_releases"

    version: Mapped[str] = mapped_column(String(64), primary_key=True)
    digest: Mapped[str] = mapped_column(String(64))
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB)
    discovered_at: Mapped[datetime] = mapped_column(default=utcnow)


class RecipeSafetyRecheck(Base):
    """Durable retry record, claimed with a database row lock by workers."""

    __tablename__ = "recipe_safety_rechecks"
    __table_args__ = (
        UniqueConstraint("version_id", "rules_version", name="uq_recipe_safety_recheck_target"),
        Index("ix_recipe_safety_recheck_status", "rules_version", "status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="CASCADE"), index=True
    )
    rules_version: Mapped[str] = mapped_column(ForeignKey("food_safety_rule_releases.version"))
    status: Mapped[str] = mapped_column(String(16), default="pending")
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    last_error: Mapped[str | None] = mapped_column(Text, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    attempted_at: Mapped[datetime | None] = mapped_column(default=None)
    completed_at: Mapped[datetime | None] = mapped_column(default=None)


class RecipeSaveOutbox(Base):
    """Durable handoff from a committed recipe save to the experience pipeline."""

    __tablename__ = "recipe_save_outbox"
    __table_args__ = (
        UniqueConstraint("version_id", name="uq_recipe_save_outbox_version"),
        Index("ix_recipe_save_outbox_recipe_id", "recipe_id"),
        Index("ix_recipe_save_outbox_version_id", "version_id"),
        Index("ix_recipe_save_outbox_owner_id", "owner_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    # Keep these identifiers as immutable event payload references.  They must
    # survive recipe deletion so a delayed experience event can still be
    # delivered; the owner foreign key remains cascading for account erasure.
    recipe_id: Mapped[uuid.UUID] = mapped_column()
    version_id: Mapped[uuid.UUID] = mapped_column()
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    previous_version_id: Mapped[uuid.UUID | None] = mapped_column(default=None)
    edit_operations: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    ai_assisted: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    delivered_at: Mapped[datetime | None] = mapped_column(default=None)


class RecipeImage(Base):
    """私有对象存储中的成品图元数据；公开地址永不落库。"""

    __tablename__ = "recipe_images"
    __table_args__ = (Index("ix_recipe_images_version_created", "version_id", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    recipe_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE"), index=True
    )
    version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("recipe_versions.id", ondelete="CASCADE"), index=True
    )
    storage_key: Mapped[str] = mapped_column(String(500))
    content_type: Mapped[str] = mapped_column(String(64))
    byte_size: Mapped[int] = mapped_column(Integer)
    width: Mapped[int | None] = mapped_column(Integer, default=None)
    height: Mapped[int | None] = mapped_column(Integer, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class RecipeImageStaging(Base):
    """An owner-scoped image uploaded before its immutable recipe version exists."""

    __tablename__ = "recipe_image_staging"
    __table_args__ = (Index("ix_recipe_image_staging_owner_created", "owner_id", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    storage_key: Mapped[str] = mapped_column(String(500), unique=True)
    content_type: Mapped[str] = mapped_column(String(64))
    byte_size: Mapped[int] = mapped_column(Integer)
    width: Mapped[int | None] = mapped_column(Integer, default=None)
    height: Mapped[int | None] = mapped_column(Integer, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
