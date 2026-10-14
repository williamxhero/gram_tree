"""Index active risk actions for the account/device ban boundary.

Revision ID: 0036
Revises: 0035
"""

from alembic import op

revision = "0036"
down_revision = "0035"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_index(
        "ix_risk_actions_active_subject",
        "risk_actions",
        ["subject_type", "subject_key_hash", "level", "lifted_at", "ends_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_risk_actions_active_subject", table_name="risk_actions")
