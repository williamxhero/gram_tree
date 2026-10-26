"""Redact erased private improvement payloads without reopening immutable lineage."""

from alembic import op

revision = "0037"
down_revision = "0036"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column("recipe_improvement_facts", "owner_id", nullable=True)
    op.execute("""CREATE OR REPLACE FUNCTION reject_improvement_fact_mutation()
        RETURNS trigger AS $$
        BEGIN
            IF TG_OP = 'UPDATE' THEN
                IF OLD.owner_id IS NOT NULL AND NEW.owner_id IS NULL
                    AND NOT EXISTS (SELECT 1 FROM recipes WHERE id = OLD.recipe_id)
                    AND ROW(NEW.recipe_id, NEW.version_id, NEW.source_recipe_id,
                        NEW.source_version_id, NEW.root_recipe_id, NEW.branch_type,
                        NEW.conclusion, NEW.rules_version)
                        IS NOT DISTINCT FROM
                        ROW(OLD.recipe_id, OLD.version_id, OLD.source_recipe_id,
                        OLD.source_version_id, OLD.root_recipe_id, OLD.branch_type,
                        OLD.conclusion, OLD.rules_version)
                    AND NEW.comparison = '{}'::jsonb
                    AND NEW.cooking_record_id IS NULL
                    AND NEW.created_at = date_trunc('week', OLD.created_at AT TIME ZONE 'UTC')
                        AT TIME ZONE 'UTC'
                    AND NEW.source_path = (
                        SELECT coalesce(jsonb_agg(jsonb_build_object(
                            'recipe_id', node.value->'recipe_id',
                            'version_id', node.value->'version_id') ORDER BY node.position),
                            '[]'::jsonb)
                        FROM jsonb_array_elements(OLD.source_path)
                            WITH ORDINALITY AS node(value, position)
                    )
                THEN
                    RETURN NEW;
                END IF;
            END IF;
            RAISE EXCEPTION 'improvement ancestry is immutable';
        END;
        $$ LANGUAGE plpgsql""")
    # Earlier private deletions left immutable rows; apply the same one-way
    # transition without changing any surviving recipe's source identity.
    op.execute("""UPDATE recipe_improvement_facts AS fact SET
        owner_id = NULL,
        comparison = '{}'::jsonb,
        cooking_record_id = NULL,
        created_at = date_trunc('week', fact.created_at AT TIME ZONE 'UTC') AT TIME ZONE 'UTC',
        source_path = (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'recipe_id', node.value->'recipe_id',
                'version_id', node.value->'version_id') ORDER BY node.position), '[]'::jsonb)
            FROM jsonb_array_elements(fact.source_path) WITH ORDINALITY AS node(value, position)
        )
        WHERE fact.owner_id IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM recipes WHERE id = fact.recipe_id)""")
    op.execute("""UPDATE improvement_receipts AS receipt
        SET response = '{"resource_deleted": true}'::jsonb
        WHERE receipt.response->'recipe'->>'id' IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM recipes
                WHERE id::text = receipt.response->'recipe'->>'id')""")
    erased_write = """SELECT receipt.write_id FROM write_receipts AS receipt
        WHERE receipt.write_type = 'record_improvement.save'
        AND receipt.result->>'resource_type' = 'record.improvement'
        AND ((receipt.result #>> '{values,response,recipe,id}' IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM recipes
                WHERE id::text = receipt.result #>> '{values,response,recipe,id}'))
            OR NOT EXISTS (SELECT 1 FROM cooking_records
                WHERE id::text = receipt.result->>'resource_id'))"""
    op.execute(f"DELETE FROM write_fact_outbox WHERE write_id IN ({erased_write})")
    op.execute(f"""UPDATE write_receipts SET status = 'failed',
        reason_code = 'resource_deleted', result = NULL, dependencies = '[]'::jsonb
        WHERE write_id IN ({erased_write})""")
    for table in ("improvement_drafts", "improvement_receipts"):
        op.execute(
            f"DELETE FROM {table} WHERE owner_id IN (SELECT id FROM users WHERE status = 'deleted')"
        )


def downgrade() -> None:
    # Restoring a NOT NULL owner intentionally refuses if anonymized rows exist;
    # no downgrade can reconstruct erased personal information.
    op.alter_column("recipe_improvement_facts", "owner_id", nullable=False)
    op.execute("""CREATE OR REPLACE FUNCTION reject_improvement_fact_mutation()
        RETURNS trigger AS $$
        BEGIN RAISE EXCEPTION 'improvement ancestry is immutable'; END;
        $$ LANGUAGE plpgsql""")
