"""标准食材库（SPEC-002.1 #86）：食材、别名、版本记录。

Revision ID: 0006
Revises: 0005
Create Date: 2026-09-30
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "ingredients",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("standard_name", sa.String(length=100), nullable=False),
        sa.Column("pinyin", sa.String(length=200), nullable=False),
        sa.Column("pinyin_initials", sa.String(length=50), nullable=False),
        sa.Column("category", sa.String(length=20), nullable=False),
        sa.Column("merged_into", sa.Uuid(), nullable=True),
        sa.Column("version", sa.String(length=20), nullable=False),
        sa.ForeignKeyConstraint(["merged_into"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "ingredient_aliases",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("alias", sa.String(length=100), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("ingredient_id", "alias"),
    )
    op.create_index(
        "ix_ingredient_aliases_ingredient_id",
        "ingredient_aliases",
        ["ingredient_id"],
        unique=False,
    )
    op.create_table(
        "ingredient_versions",
        sa.Column("version", sa.String(length=20), nullable=False),
        sa.Column("changelog", sa.String(length=2000), nullable=False),
        sa.Column(
            "imported_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("version"),
    )


def downgrade() -> None:
    op.drop_table("ingredient_versions")
    op.drop_index("ix_ingredient_aliases_ingredient_id", table_name="ingredient_aliases")
    op.drop_table("ingredient_aliases")
    op.drop_table("ingredients")
