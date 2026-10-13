"""Persist privacy-minimized HTTP access records.

Revision ID: 0037
Revises: 0036
"""

import sqlalchemy as sa
from alembic import op

revision = "0037"
down_revision = "0036"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "access_logs",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("request_id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.Uuid(), nullable=True),
        sa.Column("device_id", sa.String(length=64), nullable=True),
        sa.Column("ip_address", sa.String(length=45), nullable=True),
        sa.Column("method", sa.String(length=10), nullable=False),
        sa.Column("endpoint", sa.String(length=255), nullable=False),
        sa.Column("content_ids", sa.JSON(), nullable=False),
        sa.Column("status_code", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_access_logs_created_at", "access_logs", ["created_at"])
    op.create_index("ix_access_logs_request_id", "access_logs", ["request_id"])


def downgrade() -> None:
    op.drop_index("ix_access_logs_request_id", table_name="access_logs")
    op.drop_index("ix_access_logs_created_at", table_name="access_logs")
    op.drop_table("access_logs")
