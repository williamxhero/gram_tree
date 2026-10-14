"""Durable deletion progress and irreversible cooking statistics.

Revision ID: 0035
Revises: 0033 (parent integration chains this after export revision 0034)
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

revision = "0035"
down_revision = "0033"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "account_deletions",
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id"), primary_key=True),
        sa.Column("public_recipe_action", sa.String(32), nullable=True),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("steps", JSONB(), nullable=False),
    )
    op.create_table(
        "anonymous_cooking_statistics",
        sa.Column("bucket", sa.String(64), primary_key=True),
        sa.Column("recipe_version_id", sa.Uuid(), nullable=False),
        sa.Column("week", sa.Date(), nullable=False),
        sa.Column("dimensions", JSONB(), nullable=False),
        sa.Column("contributions", sa.Integer(), nullable=False),
    )
    op.create_index(
        "ix_anonymous_cooking_statistics_recipe_version_id",
        "anonymous_cooking_statistics",
        ["recipe_version_id"],
    )
    op.create_table(
        "cooking_statistic_dedup",
        sa.Column("owner_id", sa.Uuid(), sa.ForeignKey("users.id"), primary_key=True),
        sa.Column("recipe_version_id", sa.Uuid(), primary_key=True),
    )
    op.create_table(
        "pending_object_erasures",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("storage_key", sa.String(500), nullable=False, unique=True),
    )


def downgrade() -> None:
    op.drop_table("pending_object_erasures")
    op.drop_table("cooking_statistic_dedup")
    op.drop_table("anonymous_cooking_statistics")
    op.drop_table("account_deletions")
