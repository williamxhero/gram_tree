"""Original safety evidence, current index and durable recheck jobs.

Revision ID: 0014
Revises: 0013
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0014"
down_revision: str | None = "0013"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("recipe_versions", sa.Column("safety_at_save", postgresql.JSONB(), nullable=True))
    op.add_column("recipe_versions", sa.Column("safety_current", postgresql.JSONB(), nullable=True))
    op.add_column(
        "recipe_versions", sa.Column("safety_rules_version", sa.String(64), nullable=True)
    )
    op.add_column("recipe_versions", sa.Column("safety_context", postgresql.JSONB(), nullable=True))
    op.create_index(
        "ix_recipe_versions_safety_rules_version", "recipe_versions", ["safety_rules_version"]
    )
    op.create_table(
        "food_safety_rule_releases",
        sa.Column("version", sa.String(64), primary_key=True),
        sa.Column("digest", sa.String(64), nullable=False),
        sa.Column("payload", postgresql.JSONB(), nullable=False),
        sa.Column("discovered_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "recipe_safety_rechecks",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "rules_version",
            sa.String(64),
            sa.ForeignKey("food_safety_rule_releases.version"),
            nullable=False,
        ),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("version_id", "rules_version", name="uq_recipe_safety_recheck_target"),
    )
    op.create_index(
        "ix_recipe_safety_rechecks_version_id", "recipe_safety_rechecks", ["version_id"]
    )
    op.create_index(
        "ix_recipe_safety_recheck_status", "recipe_safety_rechecks", ["rules_version", "status"]
    )


def downgrade() -> None:
    op.drop_table("recipe_safety_rechecks")
    op.drop_table("food_safety_rule_releases")
    op.drop_index("ix_recipe_versions_safety_rules_version", table_name="recipe_versions")
    op.drop_column("recipe_versions", "safety_context")
    op.drop_column("recipe_versions", "safety_rules_version")
    op.drop_column("recipe_versions", "safety_current")
    op.drop_column("recipe_versions", "safety_at_save")
