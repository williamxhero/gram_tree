"""Join publication/improvement and upstream export/deletion migration branches.

Revision ID: 0036
Revises: 0035, 0035_improvements
"""

revision = "0036"
down_revision = ("0035", "0035_improvements")
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
