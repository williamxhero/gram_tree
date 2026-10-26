"""Immutable improvement ancestry, working drafts and retry receipts."""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0035_improvements"
down_revision = "0034_publication"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_constraint("ck_modification_target", "ai_recipe_modifications", type_="check")
    op.create_check_constraint(
        "ck_modification_target",
        "ai_recipe_modifications",
        "(((recipe_id IS NOT NULL AND base_version_id IS NOT NULL "
        "AND generation_request_id IS NULL) OR (recipe_id IS NULL "
        "AND base_version_id IS NULL AND generation_request_id IS NOT NULL)) "
        "AND request->>'improvement_draft_id' IS NULL) OR "
        "(recipe_id IS NULL AND base_version_id IS NULL AND generation_request_id IS NULL "
        "AND request->>'improvement_draft_id' IS NOT NULL)",
    )
    op.create_table(
        "improvement_drafts",
        sa.Column("id", sa.UUID(), primary_key=True),
        sa.Column(
            "owner_id", sa.UUID(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("source_recipe_id", sa.UUID(), sa.ForeignKey("recipes.id"), nullable=False),
        sa.Column(
            "source_version_id", sa.UUID(), sa.ForeignKey("recipe_versions.id"), nullable=False
        ),
        sa.Column("snapshot", postgresql.JSONB(), nullable=False),
        sa.Column("dish_name", sa.String(200), nullable=False),
        sa.Column("ai_assisted", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "recipe_improvement_facts",
        sa.Column("recipe_id", sa.UUID(), primary_key=True),
        sa.Column("version_id", sa.UUID(), nullable=False),
        sa.Column("owner_id", sa.UUID(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("source_recipe_id", sa.UUID(), sa.ForeignKey("recipes.id"), nullable=False),
        sa.Column(
            "source_version_id", sa.UUID(), sa.ForeignKey("recipe_versions.id"), nullable=False
        ),
        sa.Column("root_recipe_id", sa.UUID(), sa.ForeignKey("recipes.id"), nullable=False),
        sa.Column("source_path", postgresql.JSONB(), nullable=False),
        sa.Column("branch_type", sa.String(20), nullable=False),
        sa.Column("conclusion", sa.String(20), nullable=False),
        sa.Column("rules_version", sa.String(64), nullable=False),
        sa.Column("comparison", postgresql.JSONB(), nullable=False),
        sa.Column("cooking_record_id", sa.UUID()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "improvement_receipts",
        sa.Column("id", sa.UUID(), primary_key=True),
        sa.Column(
            "owner_id", sa.UUID(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("request_id", sa.UUID(), nullable=False),
        sa.Column("fingerprint", sa.String(64), nullable=False),
        sa.Column("response", postgresql.JSONB(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("owner_id", "request_id", name="uq_improvement_receipt"),
    )
    op.create_table(
        "improvement_curation",
        sa.Column(
            "recipe_id",
            sa.UUID(),
            sa.ForeignKey("recipes.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("curated", sa.Boolean(), nullable=False),
        sa.Column("changed_by", sa.String(200), nullable=False),
        sa.Column("reason", sa.String(2000), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    # No service endpoint updates facts; guard this invariant at the storage boundary too.
    op.execute("""CREATE FUNCTION reject_improvement_fact_mutation() RETURNS trigger AS $$
        BEGIN RAISE EXCEPTION 'improvement ancestry is immutable'; END;
        $$ LANGUAGE plpgsql""")
    op.execute("""CREATE TRIGGER immutable_improvement_fact BEFORE UPDATE OR DELETE
        ON recipe_improvement_facts FOR EACH ROW
        EXECUTE FUNCTION reject_improvement_fact_mutation()""")


def downgrade() -> None:
    op.execute("DROP TRIGGER immutable_improvement_fact ON recipe_improvement_facts")
    op.execute("DROP FUNCTION reject_improvement_fact_mutation()")
    op.drop_table("improvement_curation")
    op.drop_table("improvement_receipts")
    op.drop_table("recipe_improvement_facts")
    op.drop_table("improvement_drafts")
    op.drop_constraint("ck_modification_target", "ai_recipe_modifications", type_="check")
    op.create_check_constraint(
        "ck_modification_target",
        "ai_recipe_modifications",
        "(recipe_id IS NOT NULL AND base_version_id IS NOT NULL "
        "AND generation_request_id IS NULL) OR (recipe_id IS NULL "
        "AND base_version_id IS NULL AND generation_request_id IS NOT NULL)",
    )
