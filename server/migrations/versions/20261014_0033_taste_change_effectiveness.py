"""Track actual application time/version independently of pending suggestion creation.

Revision ID: 0033
Revises: 0032
"""

import sqlalchemy as sa
from alembic import op

revision = "0033"
down_revision = "0032"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("taste_profile_changes", sa.Column("effective_at", sa.DateTime(timezone=True)))
    op.add_column("taste_profile_changes", sa.Column("effective_version", sa.Integer()))
    # Numeric changes and manual changes apply at creation. Old confirmed automatic
    # ingredient suggestions have no trustworthy application timestamp: leave unknown.
    op.execute("""
        UPDATE taste_profile_changes
        SET effective_at = created_at, effective_version = version
        WHERE status != 'pending'
          AND NOT (origin = 'auto' AND field LIKE 'ingredient_preferences.%')
    """)


def downgrade() -> None:
    op.drop_column("taste_profile_changes", "effective_version")
    op.drop_column("taste_profile_changes", "effective_at")
