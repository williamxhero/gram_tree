"""标准食材库的数据表（SPEC-002.1 #19, #97）。

数据的唯一来源是仓库里的数据文件（`server/data/ingredients/`），这几张表只由
`gramtree ingredients import` 写入，接口只读。
"""

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, Numeric, String, UniqueConstraint, func
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


class IngredientFlavorProfile(Base):
    """食材的味型贡献（票 #97）。七项：咸甜酸辣鲜麻油，每项 0～3 强度。"""

    __tablename__ = "ingredient_flavor_profiles"
    __table_args__ = (
        CheckConstraint("strength >= 0 AND strength <= 3", name="flavor_strength_range"),
        Index("ix_ingredient_flavor_profiles_ingredient_id", "ingredient_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    flavor_type: Mapped[str] = mapped_column(String(20))  # salty, sweet, sour, spicy, umami, numbing, oily
    strength: Mapped[int] = mapped_column(Integer)  # 0-3
    source: Mapped[str] = mapped_column(String(20))  # manual, ai_estimate
    verified: Mapped[bool] = mapped_column(default=False)


class IngredientAttribute(Base):
    """食材的单值详细属性（票 #97）：功能性食材、缩放方式、密度、个体重量、超市分区、常备调料等。

    用 JSONB 存储属性值，支持不同数据类型（布尔、字符串、数值）。
    """

    __tablename__ = "ingredient_attributes"
    __table_args__ = (Index("ix_ingredient_attributes_ingredient_id", "ingredient_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    attr_key: Mapped[str] = mapped_column(String(50))  # is_functional, default_scaling, density_g_ml, etc.
    value: Mapped[dict] = mapped_column(JSONB)  # {"value": ..., "source": ..., "verified": ...}


class IngredientCountingUnit(Base):
    """食材的计数单位（票 #97）：个、瓣、根、片等，及对应的数量。"""

    __tablename__ = "ingredient_counting_units"
    __table_args__ = (Index("ix_ingredient_counting_units_ingredient_id", "ingredient_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    unit: Mapped[str] = mapped_column(String(20))
    count: Mapped[int] = mapped_column(Integer)
    source: Mapped[str] = mapped_column(String(20))
    verified: Mapped[bool] = mapped_column(default=False)


class IngredientAllergen(Base):
    """食材的过敏原标记（票 #97）：GB 7718 八类过敏原，可多选。"""

    __tablename__ = "ingredient_allergens"
    __table_args__ = (Index("ix_ingredient_allergens_ingredient_id", "ingredient_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    allergen_class: Mapped[str] = mapped_column(String(50))
    source: Mapped[str] = mapped_column(String(20))
    verified: Mapped[bool] = mapped_column(default=False)


class IngredientNutrition(Base):
    """食材的营养成分（票 #97）：每 100 克的能量、蛋白质、脂肪、碳水、钠。"""

    __tablename__ = "ingredient_nutrition"
    __table_args__ = (Index("ix_ingredient_nutrition_ingredient_id", "ingredient_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    nutrient_key: Mapped[str] = mapped_column(String(20))  # energy_kj, protein_g, fat_g, carbohydrate_g, sodium_mg
    value: Mapped[float] = mapped_column(Numeric(10, 2))
    source: Mapped[str] = mapped_column(String(20))
    verified: Mapped[bool] = mapped_column(default=False)


class IngredientPurchaseUnit(Base):
    """食材的购买单位（票 #97）：盒、袋、瓶等及大约重量。"""

    __tablename__ = "ingredient_purchase_units"
    __table_args__ = (Index("ix_ingredient_purchase_units_ingredient_id", "ingredient_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    unit: Mapped[str] = mapped_column(String(20))
    approx_weight_g: Mapped[float] = mapped_column(Numeric(10, 2))
    source: Mapped[str] = mapped_column(String(20))
    verified: Mapped[bool] = mapped_column(default=False)


class IngredientStorage(Base):
    """食材的存储方式（票 #97）：常温/冷藏/冷冻 + 建议天数。"""

    __tablename__ = "ingredient_storage"
    __table_args__ = (Index("ix_ingredient_storage_ingredient_id", "ingredient_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    method: Mapped[str] = mapped_column(String(20))  # room_temp, refrigerated, frozen
    days: Mapped[int] = mapped_column(Integer)
    source: Mapped[str] = mapped_column(String(20))
    verified: Mapped[bool] = mapped_column(default=False)


class IngredientAlias(Base):
    __tablename__ = "ingredient_aliases"
    __table_args__ = (UniqueConstraint("ingredient_id", "alias"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("ingredients.id"), index=True)
    alias: Mapped[str] = mapped_column(String(100))


class IngredientVersion(Base):
    """每次导入的食材库版本和变更说明。"""

    __tablename__ = "ingredient_versions"

    version: Mapped[str] = mapped_column(String(20), primary_key=True)
    changelog: Mapped[str] = mapped_column(String(2000))
    imported_at: Mapped[datetime] = mapped_column(server_default=func.now())
