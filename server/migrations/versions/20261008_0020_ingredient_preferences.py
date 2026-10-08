"""Ordinary owner-scoped ingredient preferences.

Revision ID: 0020
Revises: 0019
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0020"
down_revision = "0019"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "taste_profiles",
        sa.Column(
            "ingredient_preferences", postgresql.JSONB(), nullable=False, server_default="[]"
        ),
    )
    op.alter_column("taste_profiles", "ingredient_preferences", server_default=None)


def downgrade() -> None:
    op.drop_column("taste_profiles", "ingredient_preferences")
