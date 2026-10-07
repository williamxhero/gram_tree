"""AI accounting, private generation requests, and pgvector retrieval queue.

Revision ID: 0015
Revises: 0014
"""

import sqlalchemy as sa
from alembic import op
from pgvector.sqlalchemy import Vector
from sqlalchemy.dialects import postgresql

revision = "0015"
down_revision = "0014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "ai_calls",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("request_id", sa.Uuid(), nullable=False),
        sa.Column("capability", sa.String(32), nullable=False),
        sa.Column("model", sa.String(200), nullable=False),
        sa.Column("provider", sa.String(200), nullable=False),
        sa.Column("prompt_version", sa.String(64), nullable=False),
        sa.Column("content_id", sa.Uuid()),
        sa.Column("input_tokens", sa.Integer(), nullable=False),
        sa.Column("output_tokens", sa.Integer(), nullable=False),
        sa.Column("cost", sa.Float(), nullable=False),
        sa.Column("reserved_cost", sa.Float(), nullable=False),
        sa.Column("duration_ms", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("error_code", sa.String(64)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ai_calls_quota", "ai_calls", ["user_id", "capability", "created_at"])
    op.create_index("ix_ai_calls_request_id", "ai_calls", ["request_id"])
    op.create_table(
        "ai_generation_logs",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "call_id", sa.Uuid(), sa.ForeignKey("ai_calls.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("input", postgresql.JSONB(), nullable=False),
        sa.Column("output", postgresql.JSONB()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ai_generation_logs_created_at", "ai_generation_logs", ["created_at"])
    op.create_table(
        "ai_recipe_requests",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("intent", postgresql.JSONB(), nullable=False),
        sa.Column("questions", postgresql.JSONB(), nullable=False),
        sa.Column("draft", postgresql.JSONB()),
        sa.Column("saved_recipe_id", sa.Uuid(), sa.ForeignKey("recipes.id", ondelete="SET NULL")),
        sa.Column("selected_recipe_id", sa.Uuid()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "recipe_embeddings",
        sa.Column(
            "version_id",
            sa.Uuid(),
            sa.ForeignKey("recipe_versions.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("vector", Vector()),
        sa.Column("model", sa.String(200)),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_recipe_embeddings_status", "recipe_embeddings", ["status"])
    # Existing versions are indexed lazily by the worker, without touching snapshots.
    op.execute(
        "INSERT INTO recipe_embeddings (version_id, text, status, attempts, updated_at) "
        "SELECT v.id, d.name || ' ' || v.snapshot::text, 'pending', 0, now() "
        "FROM recipe_versions v JOIN recipes r ON r.id = v.recipe_id "
        "JOIN dishes d ON d.id = r.dish_id"
    )


def downgrade() -> None:
    op.drop_table("recipe_embeddings")
    op.drop_table("ai_recipe_requests")
    op.drop_table("ai_generation_logs")
    op.drop_table("ai_calls")
