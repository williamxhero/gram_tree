"""Encrypted owner allergies and consent authorization projection.

Revision ID: 0021
Revises: 0020
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0021"
down_revision = "0020"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("taste_profiles", sa.Column("sensitive_consent_id", postgresql.UUID(), nullable=True))
    op.add_column("taste_profiles", sa.Column("sensitive_authorization_version", sa.Integer(), nullable=False, server_default="0"))
    op.alter_column("taste_profiles", "sensitive_authorization_version", server_default=None)
    op.create_table(
        "owner_allergies",
        sa.Column("owner_id", postgresql.UUID(), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("ciphertext", sa.LargeBinary(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("owner_allergies")
    op.drop_column("taste_profiles", "sensitive_authorization_version")
    op.drop_column("taste_profiles", "sensitive_consent_id")
