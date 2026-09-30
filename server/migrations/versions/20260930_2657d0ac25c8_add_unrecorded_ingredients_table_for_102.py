"""Add unrecorded_ingredients table for #102

Revision ID: 2657d0ac25c8
Revises: 0007
Create Date: 2026-09-30 11:49:38.636345
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "2657d0ac25c8"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "unrecorded_ingredients",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("occurrence_count", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("first_seen_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("unrecorded_ingredients_pkey")),
        sa.UniqueConstraint("name", name=op.f("unrecorded_ingredients_name_key")),
    )
    op.create_index(
        op.f("ix_unrecorded_ingredients_occurrence_count"),
        "unrecorded_ingredients",
        ["occurrence_count"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_unrecorded_ingredients_occurrence_count"), table_name="unrecorded_ingredients"
    )
    op.drop_table("unrecorded_ingredients")
