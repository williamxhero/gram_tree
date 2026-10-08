"""Account-bound write receipts and transactional fact outbox.

Revision ID: 0018
Revises: 0017
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0018"
down_revision = "0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "write_receipts",
        sa.Column("write_id", sa.Uuid(), primary_key=True),
        sa.Column("owner_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("write_type", sa.String(100), nullable=False),
        sa.Column("fingerprint", sa.String(64), nullable=False),
        sa.Column("dependencies", postgresql.JSONB(), nullable=False),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("reason_code", sa.String(100)),
        sa.Column("result", postgresql.JSONB()),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_write_receipts_owner_id", "write_receipts", ["owner_id"])
    op.create_table(
        "write_fact_outbox",
        sa.Column(
            "write_id", sa.Uuid(), sa.ForeignKey("write_receipts.write_id"), primary_key=True
        ),
        sa.Column("owner_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("facts", postgresql.JSONB(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_write_fact_outbox_owner_id", "write_fact_outbox", ["owner_id"])


def downgrade() -> None:
    op.drop_table("write_fact_outbox")
    op.drop_table("write_receipts")
