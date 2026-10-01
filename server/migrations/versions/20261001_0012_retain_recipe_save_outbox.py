"""Retain recipe-save outbox rows when a recipe is deleted.

Revision ID: 0012
Revises: 0011
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0012"
down_revision: str | None = "0011"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # The IDs remain immutable event payload references after the recipe and
    # version snapshots are removed.  The outbox worker only needs owner_id and
    # these IDs to retry the idempotent experience event.
    op.execute(
        "ALTER TABLE recipe_save_outbox DROP CONSTRAINT IF EXISTS recipe_save_outbox_recipe_id_fkey"
    )
    op.execute(
        "ALTER TABLE recipe_save_outbox "
        "DROP CONSTRAINT IF EXISTS recipe_save_outbox_version_id_fkey"
    )


def downgrade() -> None:
    # Re-adding the constraints is unsafe after retained rows can refer to
    # deleted recipes, so the migration intentionally has no reversible DDL.
    pass
