"""工程骨架：启用 pgvector；配置项、示例表

Revision ID: 0001
Revises:
Create Date: 2026-09-27
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 第一次迁移就启用 pgvector，后面的相似检索不用再改部署
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.create_table(
        "config_values",
        sa.Column("key", sa.String(length=128), nullable=False),
        sa.Column("value", postgresql.JSONB(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("key"),
    )
    op.create_table(
        "config_changes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("key", sa.String(length=128), nullable=False),
        sa.Column("old_value", postgresql.JSONB(), nullable=True),
        sa.Column("new_value", postgresql.JSONB(), nullable=False),
        sa.Column("changed_by", sa.String(length=128), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("changed_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_config_changes_changed_at", "config_changes", ["changed_at"])
    op.create_index("ix_config_changes_key", "config_changes", ["key"])

    op.create_table(
        "example_samples",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_example_samples_created_at", "example_samples", ["created_at"])

    op.create_table(
        "task_heartbeats",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_task_heartbeats_created_at", "task_heartbeats", ["created_at"])


def downgrade() -> None:
    op.drop_table("task_heartbeats")
    op.drop_table("example_samples")
    op.drop_table("config_changes")
    op.drop_table("config_values")
    op.execute("DROP EXTENSION IF EXISTS vector")
