"""恢复演练：写入数据 → 备份 → 恢复到新库 → 健康检查通过且能读到备份前的数据。"""

import os
import uuid
from collections.abc import Iterator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import make_url

from gramtree.cli import main as cli
from gramtree.main import create_app
from gramtree.ops import backup
from gramtree.settings import get_settings
from tests.conftest import TEST_DATABASE_URL, make_settings

pytestmark = pytest.mark.skipif(not backup.tools_available(), reason="需要 pg_dump/pg_restore")


@pytest.fixture
def backup_dir(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Iterator[Path]:
    monkeypatch.setenv("GRAMTREE_BACKUP_DIR", str(tmp_path))
    monkeypatch.setenv("GRAMTREE_BACKUP_REMOTE", "")
    get_settings.cache_clear()
    yield tmp_path
    get_settings.cache_clear()


def test_backup_then_restore_drill(client: TestClient, backup_dir: Path) -> None:
    sample_id = str(uuid.uuid4())
    client.put("/v1/examples/samples", json={"id": sample_id, "title": "备份前写入"})

    assert cli(["backup", "run"]) == 0
    dumps = list(backup_dir.glob("gramtree-*.dump"))
    assert len(dumps) == 1

    restored_url = make_url(TEST_DATABASE_URL).set(database="gramtree_restore_drill")
    restored = restored_url.render_as_string(hide_password=False)
    assert cli(["backup", "restore", str(dumps[0]), "--to", restored]) == 0

    with TestClient(create_app(make_settings(database_url=restored))) as c:
        assert c.get("/v1/health").json()["status"] == "ok"
        assert c.get(f"/v1/examples/samples/{sample_id}").json()["title"] == "备份前写入"


def test_old_local_backups_pruned_by_retention(client: TestClient, backup_dir: Path) -> None:
    old = backup_dir / "gramtree-20200101T000000Z.dump"
    old.write_bytes(b"old")
    assert (
        cli(["config", "set", "ops.backup_retention_days", "7", "--by", "t", "--reason", "r"]) == 0
    )
    assert cli(["backup", "run"]) == 0
    names = sorted(p.name for p in backup_dir.iterdir())
    assert old.name not in names
    assert len(names) == 1
    assert os.path.getsize(backup_dir / names[0]) > 0
