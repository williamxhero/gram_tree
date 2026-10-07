"""Immutable reproducibility evidence; legacy versions remain explicitly unchecked.

Revision ID: 0016
Revises: 0015
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0016"
down_revision = "0015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "recipe_versions", sa.Column("reproducibility", postgresql.JSONB(), nullable=True)
    )


def downgrade() -> None:
    op.drop_column("recipe_versions", "reproducibility")
