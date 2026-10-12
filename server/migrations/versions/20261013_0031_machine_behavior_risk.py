"""Rule-based machine behaviour risk and graduated enforcement.

Revision ID: 0031
Revises: 0030
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0031"
down_revision = "0030"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "risk_events",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_key_hash", sa.String(length=64), nullable=False),
        sa.Column("rule", sa.String(length=64), nullable=False),
        sa.Column("evidence", postgresql.JSONB(), nullable=False),
        sa.Column("points", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_risk_events_subject_created",
        "risk_events",
        ["subject_type", "subject_key_hash", "created_at"],
    )
    op.create_index("ix_risk_events_created_at", "risk_events", ["created_at"])
    op.create_table(
        "risk_actions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_key_hash", sa.String(length=64), nullable=False),
        sa.Column("rule", sa.String(length=64), nullable=False),
        sa.Column("evidence", postgresql.JSONB(), nullable=False),
        sa.Column("level", sa.String(length=16), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("lifted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("lift_reason", sa.String(length=32), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_risk_actions_subject_started",
        "risk_actions",
        ["subject_type", "subject_key_hash", "started_at"],
    )
    op.create_index("ix_risk_actions_started_at", "risk_actions", ["started_at"])


def downgrade() -> None:
    op.drop_index("ix_risk_actions_started_at", table_name="risk_actions")
    op.drop_index("ix_risk_actions_subject_started", table_name="risk_actions")
    op.drop_table("risk_actions")
    op.drop_index("ix_risk_events_created_at", table_name="risk_events")
    op.drop_index("ix_risk_events_subject_created", table_name="risk_events")
    op.drop_table("risk_events")
