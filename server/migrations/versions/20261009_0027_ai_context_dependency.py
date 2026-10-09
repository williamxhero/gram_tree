"""Versioned owner context receipt for AI generation.

Revision ID: 0027
Revises: 0026
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0027"
down_revision = "0026"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "ai_recipe_requests",
        sa.Column(
            "context_dependency",
            postgresql.JSONB(),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
    )
    op.alter_column("ai_recipe_requests", "context_dependency", server_default=None)


def downgrade() -> None:
    op.drop_column("ai_recipe_requests", "context_dependency")
