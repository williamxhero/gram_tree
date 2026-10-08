"""Directional comparison cache and immutable save-time conclusions.

Revision ID: 0019
Revises: 0018
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0019"
down_revision = "0018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("recipe_versions", sa.Column("base_version_id", sa.Uuid(), nullable=True))
    op.create_foreign_key(
        "fk_recipe_version_base", "recipe_versions", "recipe_versions", ["base_version_id"], ["id"]
    )
    for table in ("recipe_versions", "recipe_save_outbox"):
        op.add_column(table, sa.Column("conclusion", sa.String(16), nullable=True))
        op.add_column(table, sa.Column("rules_version", sa.String(64), nullable=True))
    op.add_column("recipe_save_outbox", sa.Column("base_version_id", sa.Uuid(), nullable=True))
    op.create_table(
        "recipe_comparison_cache",
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
        sa.Column("result", postgresql.JSONB(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("recipe_comparison_cache")
    op.drop_constraint("fk_recipe_version_base", "recipe_versions", type_="foreignkey")
    for table in ("recipe_versions", "recipe_save_outbox"):
        for column in ("base_version_id", "conclusion", "rules_version"):
            op.drop_column(table, column)
