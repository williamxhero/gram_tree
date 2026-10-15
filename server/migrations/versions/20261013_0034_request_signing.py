"""Store per-session request signing verifiers.

Revision ID: 0034
Revises: 0033
"""

import sqlalchemy as sa
from alembic import op

revision = "0034"
down_revision = "0033"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "device_sessions",
        sa.Column("signing_secret_hash", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "device_sessions",
        sa.Column("previous_signing_secret_hash", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "device_sessions",
        sa.Column("previous_signing_secret_expires_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("device_sessions", "previous_signing_secret_expires_at")
    op.drop_column("device_sessions", "previous_signing_secret_hash")
    op.drop_column("device_sessions", "signing_secret_hash")
