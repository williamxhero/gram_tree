"""Add all ingredient attributes (ticket 97)

Revision ID: 8ae138602f4a
Revises: c0580405f258
Create Date: 2026-09-30 09:27:41.576127
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = '8ae138602f4a'
down_revision: str | None = 'c0580405f258'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # IngredientAttribute: 单值属性（功能性食材、缩放方式、密度、个体重量、超市分区、常备调料）
    op.create_table(
        "ingredient_attributes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("attr_key", sa.String(length=50), nullable=False),
        sa.Column("value", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ingredient_attributes_ingredient_id", "ingredient_attributes", ["ingredient_id"])

    # IngredientCountingUnit: 计数单位（个、瓣、根、片）
    op.create_table(
        "ingredient_counting_units",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("unit", sa.String(length=20), nullable=False),
        sa.Column("count", sa.Integer(), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ingredient_counting_units_ingredient_id", "ingredient_counting_units", ["ingredient_id"])

    # IngredientAllergen: 过敏原（GB 7718 八类）
    op.create_table(
        "ingredient_allergens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("allergen_class", sa.String(length=50), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ingredient_allergens_ingredient_id", "ingredient_allergens", ["ingredient_id"])

    # IngredientNutrition: 营养成分（每 100g）
    op.create_table(
        "ingredient_nutrition",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("nutrient_key", sa.String(length=20), nullable=False),
        sa.Column("value", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ingredient_nutrition_ingredient_id", "ingredient_nutrition", ["ingredient_id"])

    # IngredientPurchaseUnit: 购买单位
    op.create_table(
        "ingredient_purchase_units",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("unit", sa.String(length=20), nullable=False),
        sa.Column("approx_weight_g", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ingredient_purchase_units_ingredient_id", "ingredient_purchase_units", ["ingredient_id"])

    # IngredientStorage: 存储方式
    op.create_table(
        "ingredient_storage",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("method", sa.String(length=20), nullable=False),
        sa.Column("days", sa.Integer(), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ingredient_storage_ingredient_id", "ingredient_storage", ["ingredient_id"])


def downgrade() -> None:
    op.drop_index("ix_ingredient_storage_ingredient_id", table_name="ingredient_storage")
    op.drop_table("ingredient_storage")
    op.drop_index("ix_ingredient_purchase_units_ingredient_id", table_name="ingredient_purchase_units")
    op.drop_table("ingredient_purchase_units")
    op.drop_index("ix_ingredient_nutrition_ingredient_id", table_name="ingredient_nutrition")
    op.drop_table("ingredient_nutrition")
    op.drop_index("ix_ingredient_allergens_ingredient_id", table_name="ingredient_allergens")
    op.drop_table("ingredient_allergens")
    op.drop_index("ix_ingredient_counting_units_ingredient_id", table_name="ingredient_counting_units")
    op.drop_table("ingredient_counting_units")
    op.drop_index("ix_ingredient_attributes_ingredient_id", table_name="ingredient_attributes")
    op.drop_table("ingredient_attributes")
