"""Reusable field adjudication and retained personal-measure tombstones."""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0024_measure_history"
down_revision = "0023"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("personal_measures", sa.Column("deleted_at", sa.DateTime(timezone=True)))
    op.drop_constraint("uq_personal_measures_owner_name", "personal_measures", type_="unique")
    op.create_index(
        "uq_personal_measures_owner_name",
        "personal_measures",
        ["owner_id", "name"],
        unique=True,
        postgresql_where=sa.text("deleted_at IS NULL"),
    )
    op.create_table(
        "field_entities",
        sa.Column("resource_type", sa.String(100), primary_key=True),
        sa.Column("resource_id", sa.Uuid(), primary_key=True),
        sa.Column("owner_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("values", postgresql.JSONB(), nullable=False),
        sa.Column("clocks", postgresql.JSONB(), nullable=False),
        sa.Column("deleted", sa.Boolean(), nullable=False),
    )
    op.create_index("ix_field_entities_owner_id", "field_entities", ["owner_id"])
    op.create_table(
        "field_history",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("owner_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("resource_type", sa.String(100), nullable=False),
        sa.Column("resource_id", sa.Uuid(), nullable=False),
        sa.Column("write_id", sa.Uuid(), nullable=False),
        sa.Column("field", sa.String(100), nullable=False),
        sa.Column("device_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("old_value", postgresql.JSONB()),
        sa.Column("new_value", postgresql.JSONB()),
        sa.Column("outcome", sa.String(32), nullable=False),
        sa.UniqueConstraint("resource_type", "resource_id", "write_id", "field"),
    )
    op.create_index("ix_field_history_owner_id", "field_history", ["owner_id"])


def downgrade():
    op.drop_table("field_history")
    op.drop_table("field_entities")
    # Deleted identities are not user-visible resources and must not collide
    # with names subsequently reused by active identities on downgrade.
    op.execute("DELETE FROM personal_measures WHERE deleted_at IS NOT NULL")
    op.drop_index("uq_personal_measures_owner_name", table_name="personal_measures")
    op.create_unique_constraint(
        "uq_personal_measures_owner_name", "personal_measures", ["owner_id", "name"]
    )
    op.drop_column("personal_measures", "deleted_at")
