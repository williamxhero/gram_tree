"""Stage private recipe images before creating immutable versions.

Revision ID: 0011
Revises: 0010
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0011"
down_revision: str | None = "0010"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "recipe_image_staging",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("storage_key", sa.String(length=500), nullable=False),
        sa.Column("content_type", sa.String(length=64), nullable=False),
        sa.Column("byte_size", sa.Integer(), nullable=False),
        sa.Column("width", sa.Integer(), nullable=True),
        sa.Column("height", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("storage_key"),
    )
    op.create_index(
        "ix_recipe_image_staging_owner_id", "recipe_image_staging", ["owner_id"], unique=False
    )
    op.create_index(
        "ix_recipe_image_staging_owner_created",
        "recipe_image_staging",
        ["owner_id", "created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_recipe_image_staging_owner_created", table_name="recipe_image_staging")
    op.drop_index("ix_recipe_image_staging_owner_id", table_name="recipe_image_staging")
    op.drop_table("recipe_image_staging")
