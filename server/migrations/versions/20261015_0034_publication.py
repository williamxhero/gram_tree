"""Separate mutable publication facts from immutable version snapshots.

Revision ID: 0034_publication
Revises: 0033
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0034_publication"
down_revision = "0033"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "recipes", sa.Column("ever_public", sa.Boolean(), nullable=False, server_default=sa.false())
    )
    op.add_column(
        "recipes", sa.Column("withdrawn", sa.Boolean(), nullable=False, server_default=sa.false())
    )
    op.add_column(
        "recipes", sa.Column("lifecycle_sequence", sa.Integer(), nullable=False, server_default="0")
    )
    op.drop_constraint("fk_recipes_source_version_id", "recipes", type_="foreignkey")
    op.create_foreign_key(
        "fk_recipes_source_version_id",
        "recipes",
        "recipe_versions",
        ["source_version_id"],
        ["id"],
        ondelete="RESTRICT",
    )
    op.create_table(
        "recipe_publications",
        sa.Column(
            "version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("state", sa.String(32), nullable=False, server_default="draft"),
        sa.Column("published_at", sa.DateTime(timezone=True)),
        sa.Column("verified_at", sa.DateTime(timezone=True)),
        sa.Column("verification_record_id", sa.Uuid()),
        sa.Column("derived_record_id", sa.Uuid()),
        sa.Column("baseline_version_id", sa.Uuid()),
        sa.Column("baseline_record_id", sa.Uuid()),
        sa.Column("cumulative_conclusion", sa.String(16)),
        sa.Column("rules_version", sa.String(64)),
        sa.Column("risk_confirmed_rules_version", sa.String(64)),
        sa.Column("review_level", sa.String(16), nullable=False, server_default="standard"),
        sa.Column("eligibility", postgresql.JSONB(), nullable=False, server_default="{}"),
    )
    op.create_index("ix_recipe_publications_state", "recipe_publications", ["state"])
    op.create_table(
        "recipe_publication_notices",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "owner_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
        sa.Column("version_id", sa.Uuid(), nullable=False, unique=True),
        sa.Column("version_number", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("seen_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "recipe_publication_licenses",
        sa.Column(
            "owner_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("seen_at", sa.DateTime(timezone=True)),
    )


def downgrade() -> None:
    op.drop_table("recipe_publication_licenses")
    op.drop_table("recipe_publication_notices")
    op.drop_table("recipe_publications")
    op.drop_constraint("fk_recipes_source_version_id", "recipes", type_="foreignkey")
    op.create_foreign_key(
        "fk_recipes_source_version_id",
        "recipes",
        "recipe_versions",
        ["source_version_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.drop_column("recipes", "lifecycle_sequence")
    op.drop_column("recipes", "withdrawn")
    op.drop_column("recipes", "ever_public")
