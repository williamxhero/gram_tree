"""服务端接口测试样板。

- 连真的 PostgreSQL（含 pgvector）：整轮测试开始时重建测试库，从空库跑完全部迁移。
- 每个测试结束后清空所有业务表，测试之间数据互不影响。
- Redis 用单独的库号，每个测试前清空。
- 只通过对外接口（HTTP、命令行）操作和断言，不测内部函数。
- AI 调用的录制回放样板在 SPEC-003.1 加。

连接地址可用环境变量覆盖：GRAMTREE_TEST_DATABASE_URL、GRAMTREE_TEST_REDIS_URL。
"""

import os
from collections.abc import Iterator

TEST_DATABASE_URL = os.environ.get(
    "GRAMTREE_TEST_DATABASE_URL",
    "postgresql+psycopg://postgres:postgres@localhost:5432/gramtree_test_acceptance20",
)
TEST_REDIS_URL = os.environ.get("GRAMTREE_TEST_REDIS_URL", "redis://localhost:6379/8")

# 必须在 import gramtree 之前设好，命令行和任务进程都从环境变量读设置
os.environ["GRAMTREE_ENV"] = "test"
os.environ["GRAMTREE_DATABASE_URL"] = TEST_DATABASE_URL
os.environ["GRAMTREE_REDIS_URL"] = TEST_REDIS_URL

import pytest  # noqa: E402
from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from redis import Redis  # noqa: E402
from sqlalchemy import create_engine, make_url, text  # noqa: E402
from sqlalchemy.engine import Engine  # noqa: E402

from gramtree.main import create_app  # noqa: E402
from gramtree.settings import Settings, get_settings  # noqa: E402

pytest_plugins = ["tests.accounts_support"]

SERVER_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def alembic_config(url: str) -> Config:
    cfg = Config(os.path.join(SERVER_DIR, "alembic.ini"))
    cfg.set_main_option("script_location", os.path.join(SERVER_DIR, "migrations"))
    cfg.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    return cfg


def recreate_database(url: str) -> None:
    target = make_url(url)
    admin = create_engine(target.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text(f'DROP DATABASE IF EXISTS "{target.database}" WITH (FORCE)'))
        conn.execute(text(f'CREATE DATABASE "{target.database}"'))
    admin.dispose()


@pytest.fixture(scope="session")
def database_url() -> str:
    get_settings.cache_clear()
    recreate_database(TEST_DATABASE_URL)
    command.upgrade(alembic_config(TEST_DATABASE_URL), "head")
    return TEST_DATABASE_URL


@pytest.fixture(scope="session")
def engine(database_url: str) -> Iterator[Engine]:
    eng = create_engine(database_url)
    yield eng
    eng.dispose()


@pytest.fixture(autouse=True)
def _clean_state(engine: Engine) -> Iterator[None]:
    Redis.from_url(TEST_REDIS_URL).flushdb()
    yield
    with engine.begin() as conn:
        tables = conn.execute(
            text(
                "SELECT tablename FROM pg_tables WHERE schemaname = 'public' "
                "AND tablename <> 'alembic_version'"
            )
        ).scalars()
        names = ", ".join(f'"{t}"' for t in tables)
        if names:
            conn.execute(text(f"TRUNCATE {names} CASCADE"))


def make_settings(**overrides: object) -> Settings:
    values: dict[str, object] = {
        "env": "test",
        "database_url": TEST_DATABASE_URL,
        "redis_url": TEST_REDIS_URL,
        "health_timeout_seconds": 1.0,
    }
    values.update(overrides)
    return Settings.model_validate(values)


@pytest.fixture
def client(database_url: str) -> Iterator[TestClient]:
    with TestClient(create_app(make_settings()), raise_server_exceptions=False) as c:
        yield c
