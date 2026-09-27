from alembic.script import ScriptDirectory
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.engine import Engine

from gramtree.main import create_app
from tests.conftest import alembic_config, make_settings


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
