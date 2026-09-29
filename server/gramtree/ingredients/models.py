"""食材库数据模型。"""

from datetime import datetime
from typing import Optional

from sqlalchemy import (
    TIMESTAMP,
    CheckConstraint,
    ForeignKey,
    Index,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.db import Base


class Ingredient(Base):
    """标准食材表。

    每种食材有唯一的标准 ID,永不删除、不重用。
    """

    __tablename__ = "ingredients"

    # 标准 ID (主键,UUID 格式)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    # 标准名称
    standard_name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)

    # 拼音全拼
    pinyin: Mapped[str] = mapped_column(String(200), nullable=False, index=True)

    # 拼音首字母
    pinyin_initial: Mapped[str] = mapped_column(String(50), nullable=False, index=True)

    # 分类 (肉禽、水产、蔬菜、菌菇、豆制品、蛋奶、主食粮面、调料、香料等)
    category: Mapped[str] = mapped_column(String(50), nullable=False, index=True)

    # 版本号
    version: Mapped[str] = mapped_column(String(20), nullable=False)

    # 创建时间
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_ingredients_pinyin_initial_prefix", "pinyin_initial", postgresql_ops={"pinyin_initial": "text_pattern_ops"}),
        Index("ix_ingredients_pinyin_prefix", "pinyin", postgresql_ops={"pinyin": "text_pattern_ops"}),
    )


class IngredientAlias(Base):
    """食材别名表。

    同一种食材的多种叫法都指向同一个标准 ID。
    """

    __tablename__ = "ingredient_aliases"

    id: Mapped[int] = mapped_column(primary_key=True)

    # 指向的标准食材 ID
    ingredient_id: Mapped[str] = mapped_column(
        ForeignKey("ingredients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # 别名
    alias: Mapped[str] = mapped_column(String(100), nullable=False, index=True)

    # 创建时间
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_ingredient_aliases_alias_prefix", "alias", postgresql_ops={"alias": "text_pattern_ops"}),
        UniqueConstraint("ingredient_id", "alias", name="uq_ingredient_aliases_ingredient_alias"),
    )


class IngredientVersion(Base):
    """食材库版本记录表。

    每次发布记录版本号、发布时间和变更说明。
    """

    __tablename__ = "ingredient_versions"

    # 版本号 (如 "1.0.0")
    version: Mapped[str] = mapped_column(String(20), primary_key=True)

    # 发布时间
    released_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), nullable=False, server_default=func.now()
    )

    # 变更说明
    changelog: Mapped[str] = mapped_column(String(1000), nullable=False)


class IngredientMerge(Base):
    """食材合并记录表。

    两种食材合并时,旧 ID 指向新 ID,读取旧 ID 时自动转到新 ID。
    """

    __tablename__ = "ingredient_merges"

    # 旧的标准 ID (已合并)
    old_id: Mapped[str] = mapped_column(String(64), primary_key=True)

    # 新的标准 ID (合并到)
    new_id: Mapped[str] = mapped_column(
        ForeignKey("ingredients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # 合并时间
    merged_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), nullable=False, server_default=func.now()
    )

    # 合并原因
    reason: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
