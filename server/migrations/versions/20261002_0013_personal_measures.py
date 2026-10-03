"""Personal measuring tools (SPEC-002.3 #117).

Revision ID: 0013
Revises: 0012
Create Date: 2026-10-02
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0013"
down_revision: str | None = "0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "personal_measures",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=64), nullable=False),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("capacity_ml", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("owner_id", "name", name="uq_personal_measures_owner_name"),
        sa.CheckConstraint("capacity_ml > 0 AND capacity_ml <= 10000", name="ck_measure_capacity"),
        sa.CheckConstraint("kind IN ('spoon', 'bowl', 'cup')", name="ck_measure_kind"),
    )
    op.create_index(
        "ix_personal_measures_owner_created", "personal_measures", ["owner_id", "created_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_personal_measures_owner_created", table_name="personal_measures")
    op.drop_table("personal_measures")
