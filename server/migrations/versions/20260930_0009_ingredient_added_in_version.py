"""食材首次出现的版本（SPEC-002.1 #101）：增量接口用它区分新增和修改。

Revision ID: 0009
Revises: 0008
Create Date: 2026-09-30
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("ingredients", sa.Column("added_in_version", sa.String(length=20), nullable=True))
    # #101 之前的记录没有可靠的首次出现版本，保留 NULL；增量接口会把它们按“修改”报出。


def downgrade() -> None:
    op.drop_column("ingredients", "added_in_version")
