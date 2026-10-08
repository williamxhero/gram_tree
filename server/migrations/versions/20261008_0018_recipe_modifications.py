"""Owned finite modification proposals and confirmation receipts.

Revision ID: 0018
Revises: 0017
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0018"
down_revision = "0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "ai_recipe_modifications",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("recipe_id", sa.Uuid(), sa.ForeignKey("recipes.id", ondelete="CASCADE")),
        sa.Column(
            "base_version_id", sa.Uuid(), sa.ForeignKey("recipe_versions.id", ondelete="CASCADE")
        ),
        sa.Column(
            "generation_request_id",
            sa.Uuid(),
            sa.ForeignKey("ai_recipe_requests.id", ondelete="CASCADE"),
        ),
        sa.Column("request", postgresql.JSONB(), nullable=False),
        sa.Column("baseline", postgresql.JSONB(), nullable=False),
        sa.Column("proposal", postgresql.JSONB(), nullable=False),
        sa.Column("decisions", postgresql.JSONB(), nullable=False),
        sa.Column("revision", sa.Integer(), nullable=False),
        sa.Column("error", sa.String(64)),
        sa.Column(
            "saved_version_id", sa.Uuid(), sa.ForeignKey("recipe_versions.id", ondelete="SET NULL")
        ),
        sa.Column("confirmation", postgresql.JSONB()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ai_recipe_modifications_user_id", "ai_recipe_modifications", ["user_id"])
    op.create_check_constraint(
        "ck_modification_target",
        "ai_recipe_modifications",
        "(recipe_id IS NOT NULL AND base_version_id IS NOT NULL "
        "AND generation_request_id IS NULL) OR (recipe_id IS NULL "
        "AND base_version_id IS NULL AND generation_request_id IS NOT NULL)",
    )


def downgrade() -> None:
    op.drop_table("ai_recipe_modifications")
