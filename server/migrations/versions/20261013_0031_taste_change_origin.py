"""SPEC-005.3 change origin, traceability and statuses (SPEC-005.1 table).

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
    op.add_column(
        "taste_profiles",
        sa.Column("locked_fields", postgresql.JSONB(), nullable=False, server_default="[]"),
    )
    op.alter_column("taste_profiles", "locked_fields", server_default=None)
    op.drop_constraint("ck_taste_change_status", "taste_profile_changes", type_="check")
    op.add_column(
        "taste_profile_changes",
        sa.Column("origin", sa.String(16), nullable=False, server_default="manual"),
    )
    op.add_column(
        "taste_profile_changes",
        sa.Column(
            "source_record_ids",
            postgresql.JSONB(),
            nullable=False,
            server_default="[]",
        ),
    )
    op.add_column(
        "taste_profile_changes",
        sa.Column("locked_fields", postgresql.JSONB(), nullable=False, server_default="[]"),
    )
    op.add_column(
        "taste_profile_changes",
        sa.Column("reverted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.alter_column("taste_profile_changes", "origin", server_default=None)
    op.alter_column("taste_profile_changes", "source_record_ids", server_default=None)
    op.alter_column("taste_profile_changes", "locked_fields", server_default=None)
    op.create_check_constraint(
        "ck_taste_change_status",
        "taste_profile_changes",
        "status IN ('active', 'reverted', 'pending', 'confirmed')",
    )
    op.create_check_constraint(
        "ck_taste_change_origin",
        "taste_profile_changes",
        "origin IN ('manual', 'auto', 'explicit_save')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_taste_change_origin", "taste_profile_changes", type_="check")
    op.drop_constraint("ck_taste_change_status", "taste_profile_changes", type_="check")
    op.create_check_constraint(
        "ck_taste_change_status", "taste_profile_changes", "status IN ('active', 'reverted')"
    )
    op.drop_column("taste_profile_changes", "reverted_at")
    op.drop_column("taste_profile_changes", "locked_fields")
    op.drop_column("taste_profile_changes", "source_record_ids")
    op.drop_column("taste_profile_changes", "origin")
    op.drop_column("taste_profiles", "locked_fields")
