"""Shared display-only comparison assistance.

Revision ID: 0025
Revises: 0024
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0025"
down_revision = "0024"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "recipe_comparison_assistance_cache",
        sa.Column(
            "from_version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "to_version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("rules_version", sa.String(64), primary_key=True),
        sa.Column("assistance_version", sa.String(64), primary_key=True),
        sa.Column("result", postgresql.JSONB(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("recipe_comparison_assistance_cache")
