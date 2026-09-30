"""标准食材库的数据表（SPEC-002.1 #19、#97）。

数据的唯一来源是仓库里的数据文件（`server/data/ingredients/`），这几张表只由
`gramtree ingredients import` 写入，接口只读。
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.db import Base


class Ingredient(Base):
    """一种标准食材。标准 ID 永不删除、不重用；合并后旧记录保留，`merged_into` 指向新 ID。"""

    __tablename__ = "ingredients"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    standard_name: Mapped[str] = mapped_column(String(100))
    pinyin: Mapped[str] = mapped_column(String(200))
    pinyin_initials: Mapped[str] = mapped_column(String(50))
    category: Mapped[str] = mapped_column(String(20))
    merged_into: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("ingredients.id"))
    # 这条记录最后一次内容有变化的食材库版本
    version: Mapped[str] = mapped_column(String(20))


class IngredientAlias(Base):
    __tablename__ = "ingredient_aliases"
    __table_args__ = (UniqueConstraint("ingredient_id", "alias"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    alias: Mapped[str] = mapped_column(String(100))


class IngredientAttribute(Base):
    """食材的一个详细属性（#97）：一行一个字段，带字段级来源和校对状态。

    字段名和值的格式见 `gramtree/ingredients/attributes.py`；值的形状因字段而异，所以存 JSONB，
    导入时已按模型校验过。
    """

    __tablename__ = "ingredient_attributes"
    __table_args__ = (UniqueConstraint("ingredient_id", "field"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    field: Mapped[str] = mapped_column(String(30))
    value: Mapped[Any] = mapped_column(JSONB)
    source: Mapped[str] = mapped_column(String(200))
    # ai_draft：AI 起草；verified：人工校对过
    status: Mapped[str] = mapped_column(String(20))


class IngredientVersion(Base):
    """每次导入的食材库版本和变更说明。"""

    __tablename__ = "ingredient_versions"

    version: Mapped[str] = mapped_column(String(20), primary_key=True)
    changelog: Mapped[str] = mapped_column(String(2000))
    imported_at: Mapped[datetime] = mapped_column(server_default=func.now())


class UnrecordedIngredient(Base):
    """未收录食材统计（#102）：归一化接口返回 unrecorded 时自动记录。"""

    __tablename__ = "unrecorded_ingredients"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(200), unique=True)
    occurrence_count: Mapped[int] = mapped_column(default=1, index=True)
    first_seen_at: Mapped[datetime] = mapped_column(server_default=func.now())
    last_seen_at: Mapped[datetime] = mapped_column(server_default=func.now())
