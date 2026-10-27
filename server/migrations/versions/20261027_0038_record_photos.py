"""Store explicit private cooking-record photos."""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0038"
down_revision = "0037"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "cooking_records",
        sa.Column("photos", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default="[]"),
    )
    op.alter_column("cooking_records", "photos", server_default=None)


def downgrade() -> None:
    op.drop_column("cooking_records", "photos")
