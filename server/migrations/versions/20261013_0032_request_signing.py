"""Store per-session request signing verifiers.

Revision ID: 0032
Revises: 0031
"""

import sqlalchemy as sa
from alembic import op

revision = "0032"
down_revision = "0031"
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
