"""Owner cooking settings, sharing the main profile's version/history.

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
    op.add_column(
        "taste_profiles",
        sa.Column(
            "cooking_constraints",
            postgresql.JSONB(),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
    )
    op.alter_column("taste_profiles", "cooking_constraints", server_default=None)


def downgrade() -> None:
    op.drop_column("taste_profiles", "cooking_constraints")
