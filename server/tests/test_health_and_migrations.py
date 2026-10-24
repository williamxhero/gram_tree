import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest
from alembic.script import ScriptDirectory
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.engine import Engine

from gramtree.main import create_app
from tests.accounts_support import Api, bearer, new_uuid
from tests.conftest import alembic_config, make_settings
from tests.cooking_completion_support import complete_recipe
from tests.test_recipe_improvements import improvement_body, post_save, public_source
from tests.test_sync_writes import envelope, submit


def test_health_ok(client: TestClient) -> None:
    resp = client.get("/v1/health")
    assert resp.status_code == 200
    assert resp.json() == {
        "status": "ok",
        "checks": {"api": "ok", "database": "ok", "redis": "ok"},
    }


def test_health_reports_database_down() -> None:
    settings = make_settings(database_url="postgresql+psycopg://postgres:x@127.0.0.1:1/none")
    with TestClient(create_app(settings), raise_server_exceptions=False) as c:
        resp = c.get("/v1/health")
    assert resp.status_code == 503
    assert resp.json()["status"] == "unhealthy"
    assert resp.json()["checks"]["database"] == "fail"
    assert resp.json()["checks"]["redis"] == "ok"


def test_health_reports_redis_down(database_url: str) -> None:
    settings = make_settings(redis_url="redis://127.0.0.1:1/0")
    with TestClient(create_app(settings), raise_server_exceptions=False) as c:
        resp = c.get("/v1/health")
    assert resp.status_code == 503
    assert resp.json()["checks"] == {"api": "ok", "database": "ok", "redis": "fail"}


def test_migrations_have_single_head(database_url: str) -> None:
    script = ScriptDirectory.from_config(alembic_config(database_url))
    assert len(script.get_heads()) == 1


def test_pgvector_available_after_migrations(engine: Engine) -> None:
    with engine.connect() as conn:
        distance = conn.execute(text("SELECT '[1,2,3]'::vector <-> '[1,2,4]'::vector")).scalar()
    assert distance == 1.0


def test_models_match_migrations(engine: Engine) -> None:
    """模型改了却没写迁移时失败。"""
    from alembic.autogenerate import compare_metadata
    from alembic.runtime.migration import MigrationContext

    from gramtree.models import metadata

    with engine.connect() as conn:
        ctx = MigrationContext.configure(conn, opts={"compare_type": True})
        assert compare_metadata(ctx, metadata) == []


def _psql(database_url: str, sql: str) -> subprocess.CompletedProcess[str]:
    executable = shutil.which("psql")
    assert executable is not None, "PostgreSQL CLI is required for migration-boundary verification"
    return subprocess.run(
        [
            executable,
            "-X",
            "-v",
            "ON_ERROR_STOP=1",
            "-d",
            database_url.replace("postgresql+psycopg://", "postgresql://"),
            "-c",
            sql,
        ],
        env={**os.environ, "PGCLIENTENCODING": "UTF8"},
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def _migration(database_url: str, action: str, target: str) -> None:
    server = Path(__file__).resolve().parents[1]
    result = subprocess.run(
        [sys.executable, "-m", "alembic", action, target],
        cwd=server,
        env={**os.environ, "GRAMTREE_DATABASE_URL": database_url},
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize("queued", [False, True])
def test_0036_orphan_upgrade_redacts_history_and_prevents_receipt_replay(
    api: Api, database_url: str, queued
):
    """Migration boundary: psql models historical erasure; behavior is observed via HTTP."""
    _, reader, source = public_source(api)
    body = improvement_body(source)
    write: dict = {}
    if queued:
        record = complete_recipe(
            api, reader, source, adjustments=[{"step_id": "cook", "fields": {"heat": "大火"}}]
        )
        write = envelope(
            reader["user"]["id"],
            write_type="record_improvement.save",
            payload={
                "record_id": record["id"],
                "recipe_id": source["id"],
                "source_version_id": source["version"]["id"],
            },
        )
        first = submit(api, reader, write)[0]
        assert first["status"] == "confirmed", first
        branch = first["result"]["values"]["response"]["recipe"]
    else:
        first = post_save(api, reader, source, body)
        assert first.status_code == 201, first.text
        branch = first.json()["recipe"]
    try:
        _migration(database_url, "downgrade", "0036")
        # Reproduce only the old schema's private-delete residue, without
        # disabling its immutable trigger or touching the public source.
        legacy = _psql(
            database_url,
            f"""BEGIN;
            DELETE FROM recipe_save_outbox WHERE recipe_id = '{branch["id"]}';
            DELETE FROM events WHERE user_id = '{reader["user"]["id"]}'
                AND correlation->>'recipe_version_id' = '{branch["version"]["id"]}';
            UPDATE recipes SET current_version_id = NULL WHERE id = '{branch["id"]}';
            DELETE FROM recipe_versions WHERE recipe_id = '{branch["id"]}';
            DELETE FROM recipes WHERE id = '{branch["id"]}';
            COMMIT;""",
        )
        assert legacy.returncode == 0, legacy.stderr
        _migration(database_url, "upgrade", "head")
        observed = api.client.get("/v1/dev/deletion-storage", headers=bearer(reader))
        assert observed.status_code == 200, observed.text
        stored = observed.json()
        assert stored["orphan_improvement_private_payloads"] == 0
        assert stored["owned_counts"]["improvement_receipt_payloads"] == 0
        assert stored["owned_counts"]["recipe_improvement_facts"] == 0
        assert len(stored["anonymous_improvement_statistics"]) == 1
        if queued:
            replay = submit(api, reader, write)[0]
            assert replay["status"] == "failed", replay
            assert replay["reason_code"] == "resource_deleted"
            assert replay["result"] is None
        else:
            replay = post_save(api, reader, source, body)
            assert replay.status_code == 404, replay.text
        assert api.client.get("/v1/recipes", headers=bearer(reader)).json()["items"] == []
        assert (
            api.client.get(f"/v1/recipes/{source['id']}", headers=bearer(reader)).status_code == 200
        )
    finally:
        _migration(database_url, "upgrade", "head")


def test_improvement_storage_guard_rejects_live_mutation_and_erased_reidentification(
    api: Api, database_url: str
):
    """PostgreSQL constraint/CLI boundary, separate from ordinary service API coverage."""
    _, reader, source = public_source(api)
    saved = post_save(api, reader, source, improvement_body(source))
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    target = f"WHERE recipe_id = '{branch['id']}'"
    for sql in (
        f"DELETE FROM recipe_improvement_facts {target}",
        f"UPDATE recipe_improvement_facts SET root_recipe_id = '{new_uuid()}' {target}",
        f"""UPDATE recipe_improvement_facts SET owner_id=NULL, comparison='{{}}'::jsonb,
            cooking_record_id=NULL,
            created_at=date_trunc('week', created_at AT TIME ZONE 'UTC') AT TIME ZONE 'UTC',
            source_path=(SELECT jsonb_agg(jsonb_build_object('recipe_id',node->'recipe_id',
                'version_id',node->'version_id')) FROM jsonb_array_elements(source_path) node)
            {target}""",
    ):
        rejected = _psql(database_url, sql)
        assert rejected.returncode != 0
        assert "improvement ancestry is immutable" in rejected.stderr
    assert (
        api.client.delete(f"/v1/recipes/{branch['id']}", headers=bearer(reader)).status_code == 204
    )
    for sql in (
        f"DELETE FROM recipe_improvement_facts {target}",
        f"UPDATE recipe_improvement_facts SET owner_id = '{reader['user']['id']}' {target}",
        f"UPDATE recipe_improvement_facts SET comparison = '{{\"private\":true}}'::jsonb {target}",
        f"UPDATE recipe_improvement_facts SET root_recipe_id = '{new_uuid()}' {target}",
        "UPDATE recipe_improvement_facts SET source_path = "
        f"jsonb_build_array(jsonb_build_object('author_id','private')) {target}",
        f"UPDATE recipe_improvement_facts SET created_at = now() {target}",
    ):
        rejected = _psql(database_url, sql)
        assert rejected.returncode != 0
        assert "improvement ancestry is immutable" in rejected.stderr
    stored = api.client.get("/v1/dev/deletion-storage", headers=bearer(reader)).json()
    assert stored["orphan_improvement_private_payloads"] == 0
    assert len(stored["anonymous_improvement_statistics"]) == 1
