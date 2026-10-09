"""Encrypted simplified family members.

Revision ID: 0024
Revises: 0023
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0024"
down_revision = "0023"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "family_members",
        sa.Column("id", postgresql.UUID(), primary_key=True),
        sa.Column(
            "owner_id",
            postgresql.UUID(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("ciphertext", sa.LargeBinary(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_family_members_owner_created", "family_members", ["owner_id", "created_at", "id"]
    )


def downgrade() -> None:
    op.drop_index("ix_family_members_owner_created", table_name="family_members")
    op.drop_table("family_members")
