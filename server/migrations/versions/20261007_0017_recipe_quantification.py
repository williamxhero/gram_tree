"""Server-owned quantification proposals and idempotent decisions.

Revision ID: 0017
Revises: 0016
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0017"
down_revision = "0016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "recipe_quantifications",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "recipe_id", sa.Uuid(), sa.ForeignKey("recipes.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "base_version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("proposals", postgresql.JSONB(), nullable=False),
        sa.Column("decisions", postgresql.JSONB(), nullable=True),
        sa.Column(
            "saved_version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_recipe_quantifications_recipe_id", "recipe_quantifications", ["recipe_id"])


def downgrade() -> None:
    op.drop_table("recipe_quantifications")
