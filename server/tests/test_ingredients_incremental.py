"""测试食材增量更新接口 (ticket #101, SPEC-002.1)。

测试增量变化检测和批量读取接口。
"""

import json
import tempfile
from pathlib import Path

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.test_conventions import assert_error_shape

FIXTURES = Path(__file__).parent / "data" / "ingredients"


def test_changes_endpoint_returns_modifications(client: TestClient) -> None:
    """导入基线数据，再导入新版本，增量接口返回变化的 ID。"""
    # 导入基线版本
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    # 导入新版本，修改一个食材的名称
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "1.1.0", "changelog": "修改测试盐的拼音"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-000000000001",
                        "standard_name": "测试酱油",
                        "aliases": ["测试生抽", "测试味极鲜"],
                        "pinyin": "ceshijiangyou",
                        "pinyin_initials": "csjy",
                        "category": "调料",
                    },
                    {
                        "id": "00000000-0000-4000-8000-000000000002",
                        "standard_name": "测试盐",
                        "aliases": ["测试食盐"],
                        "pinyin": "ceshiyan",  # 保持不变
                        "pinyin_initials": "csy",
                        "category": "调料",
                    },
                    {
                        "id": "00000000-0000-4000-8000-000000000003",
                        "standard_name": "测试糖",
                        "aliases": ["测试白糖"],
                        "pinyin": "ceshitangxin",  # 修改了拼音
                        "pinyin_initials": "cstx",
                        "category": "调料",
                    },
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 查询 1.0.0 之后的变化
    resp = client.get("/v1/ingredients/changes?since_version=1.0.0")
    assert resp.status_code == 200
    data = resp.json()
    assert data["current_version"] == "1.1.0"
    # 修改了第三个食材
    assert "00000000-0000-4000-8000-000000000003" in data["modified"]
    # 另外两个没变
    assert "00000000-0000-4000-8000-000000000001" not in data["modified"]
    assert "00000000-0000-4000-8000-000000000002" not in data["modified"]


def test_changes_endpoint_detects_attribute_changes(client: TestClient) -> None:
    """属性变化也能被增量接口检测到。"""
    # 先导入带属性的数据
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "2.0.0", "changelog": "带属性"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-100000000001",
                        "standard_name": "测试西红柿",
                        "aliases": [],
                        "pinyin": "ceshixihongshi",
                        "pinyin_initials": "csxhs",
                        "category": "蔬菜",
                        "attributes": {
                            "base_unit": {"value": "克", "source": "测试", "status": "verified"},
                            "density": {
                                "value": 1.0,
                                "source": "测试",
                                "status": "ai_draft",
                            },
                        },
                    }
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 修改属性
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "2.1.0", "changelog": "修改密度"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-100000000001",
                        "standard_name": "测试西红柿",
                        "aliases": [],
                        "pinyin": "ceshixihongshi",
                        "pinyin_initials": "csxhs",
                        "category": "蔬菜",
                        "attributes": {
                            "base_unit": {"value": "克", "source": "测试", "status": "verified"},
                            "density": {
                                "value": 1.05,  # 修改了密度
                                "source": "测试更新",
                                "status": "verified",  # 改成已验证
                            },
                        },
                    }
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 查询变化
    resp = client.get("/v1/ingredients/changes?since_version=2.0.0")
    assert resp.status_code == 200
    data = resp.json()
    assert data["current_version"] == "2.1.0"
    assert "00000000-0000-4000-8000-100000000001" in data["modified"]


def test_changes_endpoint_detects_merged_ingredients(client: TestClient) -> None:
    """合并的食材出现在 merged 字段。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "3.0.0", "changelog": "基线"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-300000000001",
                        "standard_name": "食材A",
                        "aliases": [],
                        "pinyin": "shicaia",
                        "pinyin_initials": "sca",
                        "category": "调料",
                    },
                    {
                        "id": "00000000-0000-4000-8000-300000000002",
                        "standard_name": "食材B",
                        "aliases": [],
                        "pinyin": "shicaib",
                        "pinyin_initials": "scb",
                        "category": "调料",
                    },
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 合并 A 到 B
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "3.1.0", "changelog": "合并 A 到 B"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-300000000001",
                        "standard_name": "食材A",
                        "aliases": [],
                        "pinyin": "shicaia",
                        "pinyin_initials": "sca",
                        "category": "调料",
                        "merged_into": "00000000-0000-4000-8000-300000000002",
                    },
                    {
                        "id": "00000000-0000-4000-8000-300000000002",
                        "standard_name": "食材B",
                        "aliases": [],
                        "pinyin": "shicaib",
                        "pinyin_initials": "scb",
                        "category": "调料",
                    },
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(tmp)]) == 0

    resp = client.get("/v1/ingredients/changes?since_version=3.0.0")
    assert resp.status_code == 200
    data = resp.json()
    assert data["merged"]["00000000-0000-4000-8000-300000000001"] == "00000000-0000-4000-8000-300000000002"


def test_changes_nonexistent_version(client: TestClient) -> None:
    """查询不存在的版本返回 404。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0
    resp = client.get("/v1/ingredients/changes?since_version=99.99.99")
    assert_error_shape(resp, 404, "not_found")


def test_batch_get_ingredients(client: TestClient) -> None:
    """批量读取接口返回完整数据。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    ids = "00000000-0000-4000-8000-000000000001,00000000-0000-4000-8000-000000000002"
    resp = client.get(f"/v1/ingredients/batch?ids={ids}")
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 2
    assert items[0]["id"] == "00000000-0000-4000-8000-000000000001"
    assert items[0]["standard_name"] == "测试酱油"
    assert "attributes" in items[0]
    assert items[1]["id"] == "00000000-0000-4000-8000-000000000002"


def test_batch_get_follows_merge(client: TestClient) -> None:
    """批量读取时自动跟随合并链。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "4.0.0", "changelog": "合并测试"}), encoding="utf-8"
        )
        (tmp / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-400000000001",
                        "standard_name": "旧名",
                        "aliases": [],
                        "pinyin": "jiuming",
                        "pinyin_initials": "jm",
                        "category": "调料",
                        "merged_into": "00000000-0000-4000-8000-400000000002",
                    },
                    {
                        "id": "00000000-0000-4000-8000-400000000002",
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

    # 请求旧 ID，应返回新食材
    resp = client.get("/v1/ingredients/batch?ids=00000000-0000-4000-8000-400000000001")
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1
    assert items[0]["id"] == "00000000-0000-4000-8000-400000000002"
    assert items[0]["standard_name"] == "新名"


def test_batch_get_skips_nonexistent(client: TestClient) -> None:
    """批量读取时跳过不存在的 ID。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    ids = "00000000-0000-4000-8000-000000000001,00000000-0000-4000-8000-ffffffffffff"
    resp = client.get(f"/v1/ingredients/batch?ids={ids}")
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1  # 只返回存在的
    assert items[0]["id"] == "00000000-0000-4000-8000-000000000001"


def test_batch_get_empty_list(client: TestClient) -> None:
    """空 ID 列表返回空数组。"""
    resp = client.get("/v1/ingredients/batch?ids=")
    assert resp.status_code == 200
    assert resp.json() == []


def test_batch_get_limit(client: TestClient) -> None:
    """超过 100 个 ID 返回错误。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0
    ids = ",".join([f"00000000-0000-4000-8000-{i:012x}" for i in range(101)])
    resp = client.get(f"/v1/ingredients/batch?ids={ids}")
    assert_error_shape(resp, 422, "invalid_request")


def test_batch_get_invalid_id_format(client: TestClient) -> None:
    """无效的 ID 格式返回错误。"""
    resp = client.get("/v1/ingredients/batch?ids=not-a-uuid")
    assert_error_shape(resp, 422, "invalid_request")
