"""做菜记录与追加修订。

Revision ID: 0028
Revises: 0027
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0028"
down_revision = "0027"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "cooking_records",
        sa.Column("id", postgresql.UUID(), primary_key=True),
        sa.Column(
            "owner_id",
            postgresql.UUID(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("client_id", postgresql.UUID(), nullable=False),
        sa.Column("recipe_id", postgresql.UUID(), nullable=True),
        sa.Column("recipe_version_id", postgresql.UUID(), nullable=True),
        sa.Column("dish_name", sa.String(200), nullable=True),
        sa.Column("source", sa.String(32), nullable=False),
        sa.Column("verification", sa.String(32), nullable=False),
        sa.Column("counts_as_cooked", sa.Boolean(), nullable=False),
        sa.Column("meal", sa.String(16), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("snapshot", postgresql.JSONB(), nullable=True),
        sa.Column("adjustments", postgresql.JSONB(), nullable=False),
        sa.Column("source_context", postgresql.JSONB(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("owner_id", "client_id", name="uq_cooking_records_owner_client"),
    )
    op.create_index(
        "ix_cooking_records_owner_created", "cooking_records", ["owner_id", "created_at", "id"]
    )
    op.create_table(
        "cooking_record_revisions",
        sa.Column("id", postgresql.UUID(), primary_key=True),
        sa.Column(
            "owner_id",
            postgresql.UUID(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "record_id",
            postgresql.UUID(),
            sa.ForeignKey("cooking_records.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("revision_id", postgresql.UUID(), nullable=False),
        sa.Column("revision", sa.Integer(), nullable=False),
        sa.Column("field", sa.String(32), nullable=False),
        sa.Column("value", postgresql.JSONB(), nullable=False),
        sa.Column("note", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("owner_id", "revision_id", name="uq_cooking_record_revisions_owner_id"),
    )
    op.create_index(
        "ix_cooking_record_revisions_record_created",
        "cooking_record_revisions",
        ["record_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_cooking_record_revisions_record_created", table_name="cooking_record_revisions"
    )
    op.drop_table("cooking_record_revisions")
    op.drop_index("ix_cooking_records_owner_created", table_name="cooking_records")
    op.drop_table("cooking_records")
