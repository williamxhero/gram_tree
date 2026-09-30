"""测试食材库基础功能 (ticket #86, SPEC-002.1)。

按 CLAUDE.md 规则只通过外部接口测试:CLI 导入命令和 HTTP 接口。
"""

import json
import tempfile
from pathlib import Path

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.test_conventions import assert_error_shape

FIXTURES = Path(__file__).parent / "data" / "ingredients"


def test_import_and_read(client: TestClient) -> None:
    """导入测试数据,通过 HTTP 读取验证。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.get("/v1/ingredients/00000000-0000-4000-8000-000000000001")
    assert resp.status_code == 200
    ing = resp.json()
    assert ing["id"] == "00000000-0000-4000-8000-000000000001"
    assert ing["standard_name"] == "测试酱油"
    assert set(ing["aliases"]) == {"测试生抽", "测试味极鲜"}
    assert ing["pinyin"] == "ceshijiangyou"
    assert ing["pinyin_initials"] == "csjy"
    assert ing["category"] == "调料"
    assert ing["version"] == "1.0.0"


def test_import_is_idempotent(client: TestClient) -> None:
    """重复导入同一份数据是幂等的。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.get("/v1/ingredients/00000000-0000-4000-8000-000000000002")
    assert resp.status_code == 200
    assert resp.json()["standard_name"] == "测试盐"


def test_merged_ingredient_follows_chain(client: TestClient) -> None:
    """读取已合并的食材 ID,自动跟随到新 ID。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "1.1.0", "changelog": "测试合并"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-000000000001",
                        "standard_name": "旧名",
                        "aliases": [],
                        "pinyin": "jiuming",
                        "pinyin_initials": "jm",
                        "category": "调料",
                        "merged_into": "00000000-0000-4000-8000-000000000002",
                    },
                    {
                        "id": "00000000-0000-4000-8000-000000000002",
                        "standard_name": "新名",
                        "aliases": [],
                        "pinyin": "xinming",
                        "pinyin_initials": "xm",
                        "category": "调料",
                    },
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 读旧 ID,应返回新食材
    resp = client.get("/v1/ingredients/00000000-0000-4000-8000-000000000001")
    assert resp.status_code == 200
    assert resp.json()["id"] == "00000000-0000-4000-8000-000000000002"
    assert resp.json()["standard_name"] == "新名"


def test_ingredient_not_found(client: TestClient) -> None:
    """读取不存在的食材返回 404。"""
    resp = client.get("/v1/ingredients/00000000-0000-4000-8000-ffffffffffff")
    assert_error_shape(resp, 404, "not_found")


def test_import_refuses_to_delete_ids() -> None:
    """导入时拒绝删除已有的 ID (ID 永不删除)。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "1.2.0", "changelog": "测试"}), encoding="utf-8"
        )
        # 只有第一个,缺少第二个
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-000000000001",
                        "standard_name": "测试酱油",
                        "aliases": [],
                        "pinyin": "ceshijiangyou",
                        "pinyin_initials": "csjy",
                        "category": "调料",
                    }
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 1


def test_import_invalid_category_fails() -> None:
    """分类不在白名单里,导入失败。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "1.0.0", "changelog": "测试"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-000000000099",
                        "standard_name": "测试",
                        "aliases": [],
                        "pinyin": "ceshi",
                        "pinyin_initials": "cs",
                        "category": "不存在的分类",
                    }
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 1


def test_import_duplicate_name_fails() -> None:
    """同一个名称指向两种食材,导入失败。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "1.0.0", "changelog": "测试"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-000000000011",
                        "standard_name": "重名",
                        "aliases": [],
                        "pinyin": "chongming",
                        "pinyin_initials": "cm",
                        "category": "调料",
                    },
                    {
                        "id": "00000000-0000-4000-8000-000000000012",
                        "standard_name": "重名",
                        "aliases": [],
                        "pinyin": "chongming",
                        "pinyin_initials": "cm",
                        "category": "调料",
                    },
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 1
