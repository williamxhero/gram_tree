"""Private imported source records.

Revision ID: 0029
Revises: 0028
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0029"
down_revision = "0028"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "recipe_imports",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "owner_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("recipe_id", sa.Uuid(), sa.ForeignKey("recipes.id", ondelete="SET NULL")),
        sa.Column("mode", sa.String(16), nullable=False),
        sa.Column("source_url", sa.Text()),
        sa.Column("source_platform", sa.String(255), nullable=False),
        sa.Column("original_ciphertext", sa.LargeBinary(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("reason", sa.String(64)),
        sa.Column("field_states", postgresql.JSONB(), nullable=False),
        sa.Column("image_count", sa.Integer(), nullable=False),
        sa.Column("failed_image_count", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_recipe_imports_owner_created", "recipe_imports", ["owner_id", "created_at"])
    op.create_index("ix_recipe_imports_owner_source", "recipe_imports", ["owner_id", "source_url"])


def downgrade() -> None:
    op.drop_table("recipe_imports")
