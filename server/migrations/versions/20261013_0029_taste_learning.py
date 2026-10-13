"""SPEC-005.3 taste learning: attribution, signals, evidence and warnings.

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
        "taste_attributions",
        sa.Column("record_id", sa.Uuid(), primary_key=True),
        sa.Column(
            "owner_id",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "profile_id",
            sa.Uuid(),
            sa.ForeignKey("taste_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("recipe_version_id", sa.Uuid(), nullable=True),
        sa.ForeignKeyConstraint(["record_id"], ["cooking_records.id"], ondelete="CASCADE"),
        sa.Column("flavors", postgresql.JSONB(), nullable=False),
        sa.Column("feedback_revision_id", sa.Uuid(), nullable=True),
        sa.Column("verdict", sa.String(16), nullable=False),
        sa.Column("decision_source", sa.String(16), nullable=False),
        sa.Column("reason_code", sa.String(48), nullable=False),
        sa.Column("rules_version", sa.String(48), nullable=False),
        sa.Column("sample_size", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("automatic", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("revision", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "verdict IN ('personal', 'recipe', 'pending')",
            name="ck_taste_attribution_verdict",
        ),
        sa.CheckConstraint(
            "decision_source IN ('rule', 'user', 'unanswered')",
            name="ck_taste_attribution_source",
        ),
    )
    op.create_index("ix_taste_attributions_owner", "taste_attributions", ["owner_id"])
    op.create_index(
        "ix_taste_attributions_version", "taste_attributions", ["recipe_version_id", "verdict"]
    )

    op.create_table(
        "taste_learning_signals",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "owner_id",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "profile_id",
            sa.Uuid(),
            sa.ForeignKey("taste_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "record_id",
            sa.Uuid(),
            sa.ForeignKey("cooking_records.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("signal_key", sa.String(160), nullable=False),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column("field", sa.String(100), nullable=False),
        sa.Column("scope", sa.String(64), nullable=False, server_default="overall"),
        sa.Column("direction", sa.Integer(), nullable=False),
        sa.Column("base_weight", sa.Float(), nullable=False),
        sa.Column("effective_weight", sa.Float(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="active"),
        sa.Column("consumed_by_change_id", sa.Uuid(), nullable=True),
        sa.Column(
            "attribution_record_id",
            sa.Uuid(),
            sa.ForeignKey("cooking_records.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("flavor_key", sa.String(16), nullable=True),
        sa.Column("ingredient_id", sa.Uuid(), nullable=True),
        sa.Column("ingredient_category", sa.String(20), nullable=True),
        sa.Column("observed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('active', 'consumed', 'retracted')", name="ck_taste_signal_status"
        ),
    )
    op.create_index(
        "ix_taste_learning_signals_owner_field",
        "taste_learning_signals",
        ["owner_id", "field", "status"],
    )
    op.create_unique_constraint(
        "uq_taste_learning_signals_owner_key",
        "taste_learning_signals",
        ["owner_id", "signal_key"],
    )

    op.create_table(
        "taste_change_facts",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "owner_id",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("change_id", sa.Uuid(), nullable=False),
        sa.Column("event_type", sa.String(48), nullable=False),
        sa.Column("source", sa.String(24), nullable=False),
        sa.Column("origin_change_id", sa.Uuid(), nullable=True),
        sa.Column("field", sa.String(100), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("owner_id", "change_id", "event_type", name="uq_taste_change_facts"),
    )
    op.create_index("ix_taste_change_facts_owner", "taste_change_facts", ["owner_id", "event_type"])


def downgrade() -> None:
    op.drop_table("taste_change_facts")
    op.drop_table("taste_learning_signals")
    op.drop_table("taste_attributions")
