"""Freeze a minimal taste summary and private co-diner links on records.

Revision ID: 0030
Revises: 0029
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0032"
down_revision = "0031"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "cooking_records",
        sa.Column("taste_summary", postgresql.JSONB(), nullable=False, server_default="{}"),
    )
    op.add_column(
        "cooking_records",
        sa.Column("co_diner_ids", postgresql.JSONB(), nullable=False, server_default="[]"),
    )
    op.alter_column("cooking_records", "taste_summary", server_default=None)
    op.alter_column("cooking_records", "co_diner_ids", server_default=None)


def downgrade() -> None:
    op.drop_column("cooking_records", "co_diner_ids")
    op.drop_column("cooking_records", "taste_summary")
