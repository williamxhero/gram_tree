"""Add fail-closed reviewed-public-version metadata and opaque share IDs.

Revision ID: 0035
Revises: 0034
"""

import sqlalchemy as sa
from alembic import op

revision = "0035"
down_revision = "0034"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("recipes", sa.Column("share_id", sa.String(length=64), nullable=True))
    op.create_unique_constraint("uq_recipes_share_id", "recipes", ["share_id"])
    op.add_column(
        "recipes",
        sa.Column("approved_public_version_id", sa.Uuid(), nullable=True),
    )
    op.create_foreign_key(
        "fk_recipes_approved_public_version_id",
        "recipes",
        "recipe_versions",
        ["approved_public_version_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.create_table(
        "share_complaints",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("share_id", sa.String(length=64), nullable=True),
        sa.Column("contact", sa.String(length=320), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reviewed_by", sa.String(length=64), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_share_complaints_status_created", "share_complaints", ["status", "created_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_share_complaints_status_created", table_name="share_complaints")
    op.drop_table("share_complaints")
    op.drop_constraint("fk_recipes_approved_public_version_id", "recipes", type_="foreignkey")
    op.drop_column("recipes", "approved_public_version_id")
    op.drop_constraint("uq_recipes_share_id", "recipes", type_="unique")
    op.drop_column("recipes", "share_id")
