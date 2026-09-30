"""食材详细属性（SPEC-002.1 #97）：一行一个字段，带来源和校对状态。

Revision ID: 0007
Revises: 0006
Create Date: 2026-09-30
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "ingredient_attributes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.Uuid(), nullable=False),
        sa.Column("field", sa.String(length=30), nullable=False),
        sa.Column("value", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("source", sa.String(length=200), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.ForeignKeyConstraint(["ingredient_id"], ["ingredients.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("ingredient_id", "field"),
    )
    op.create_index(
        "ix_ingredient_attributes_ingredient_id",
        "ingredient_attributes",
        ["ingredient_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_ingredient_attributes_ingredient_id", table_name="ingredient_attributes")
    op.drop_table("ingredient_attributes")
