"""Add ingredient flavor profiles (ticket 97)

Revision ID: c0580405f258
Revises: 0006
Create Date: 2026-09-30 09:22:13.285561
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = 'c0580405f258'
down_revision: str | None = '0006'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "ingredient_flavor_profiles",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("flavor_type", sa.String(length=20), nullable=False),
        sa.Column("strength", sa.Integer(), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.CheckConstraint("strength >= 0 AND strength <= 3", name="flavor_strength_range"),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_ingredient_flavor_profiles_ingredient_id",
        "ingredient_flavor_profiles",
        ["ingredient_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_ingredient_flavor_profiles_ingredient_id", table_name="ingredient_flavor_profiles")
    op.drop_table("ingredient_flavor_profiles")
