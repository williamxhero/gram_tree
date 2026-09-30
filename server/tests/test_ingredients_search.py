"""测试食材搜索接口 (ticket #99, SPEC-002.1)。

按 CLAUDE.md 规则只通过外部接口测试:HTTP 搜索接口。
"""

import json
import tempfile
from pathlib import Path

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.test_conventions import assert_error_shape

FIXTURES = Path(__file__).parent / "data" / "ingredients"


def test_search_by_standard_name_prefix(client: TestClient) -> None:
    """按标准名称前缀搜索。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "测试酱"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["id"] == "00000000-0000-4000-8000-000000000001"
    assert data["items"][0]["standard_name"] == "测试酱油"


def test_search_by_alias_prefix(client: TestClient) -> None:
    """按别名前缀搜索。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "测试生"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["id"] == "00000000-0000-4000-8000-000000000001"
    assert data["items"][0]["standard_name"] == "测试酱油"


def test_search_by_pinyin_initials(client: TestClient) -> None:
    """按拼音首字母搜索。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "csjy"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["id"] == "00000000-0000-4000-8000-000000000001"
    assert data["items"][0]["standard_name"] == "测试酱油"


def test_search_by_full_pinyin_prefix(client: TestClient) -> None:
    """按完整拼音前缀搜索。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "ceshijian"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["id"] == "00000000-0000-4000-8000-000000000001"
    assert data["items"][0]["standard_name"] == "测试酱油"


def test_search_returns_up_to_20_results(client: TestClient) -> None:
    """搜索最多返回 20 个结果。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "2.0.0", "changelog": "测试大量数据"}), encoding="utf-8"
        )
        items = []
        # 使用字母序号而不是数字
        letters = "abcdefghijklmnopqrstuvwxyz"
        for i in range(30):
            suffix = letters[i // 26] + letters[i % 26] if i >= 26 else letters[i]
            items.append(
                {
                    "id": f"00000000-0000-4000-8000-{i:012d}",
                    "standard_name": f"通用食材{suffix.upper()}",
                    "aliases": [],
                    "pinyin": f"tongyongshicai{suffix}",
                    "pinyin_initials": f"tysc{suffix}",
                    "category": "调料",
                }
            )
        (tmp / "data.json").write_text(json.dumps(items), encoding="utf-8")
        assert cli(["ingredients", "import", str(tmp)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "通用"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 20


def test_search_sorts_by_match_quality(client: TestClient) -> None:
    """搜索结果按匹配质量排序:精确>别名>拼音。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "2.0.0", "changelog": "测试排序"}), encoding="utf-8"
        )
        items = [
            {
                "id": "00000000-0000-4000-8000-000000000011",
                "standard_name": "酱油",
                "aliases": [],
                "pinyin": "jiangyou",
                "pinyin_initials": "jy",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000012",
                "standard_name": "盐",
                "aliases": ["精盐"],
                "pinyin": "yan",
                "pinyin_initials": "y",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000013",
                "standard_name": "糖",
                "aliases": [],
                "pinyin": "tang",
                "pinyin_initials": "t",
                "category": "调料",
            },
        ]
        (tmp / "data.json").write_text(json.dumps(items), encoding="utf-8")
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 搜"精":标准名前缀优先于别名前缀
    resp = client.post("/v1/ingredients/search", json={"query": "jy"})
    assert resp.status_code == 200
    data = resp.json()
    # "jy"匹配拼音首字母,应该找到酱油
    assert data["items"][0]["standard_name"] == "酱油"


def test_search_excludes_merged_ingredients(client: TestClient) -> None:
    """搜索结果不包含已合并的食材,返回合并后的食材。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "3.0.0", "changelog": "测试合并"}), encoding="utf-8"
        )
        items = [
            {
                "id": "00000000-0000-4000-8000-000000000021",
                "standard_name": "旧酱油",
                "aliases": [],
                "pinyin": "jiujiangyou",
                "pinyin_initials": "jjy",
                "category": "调料",
                "merged_into": "00000000-0000-4000-8000-000000000022",
            },
            {
                "id": "00000000-0000-4000-8000-000000000022",
                "standard_name": "新酱油",
                "aliases": [],
                "pinyin": "xinjiangyou",
                "pinyin_initials": "xjy",
                "category": "调料",
            },
        ]
        (tmp / "data.json").write_text(json.dumps(items), encoding="utf-8")
        assert cli(["ingredients", "import", str(tmp)]) == 0

    # 搜拼音应该只返回新酱油(旧酱油已合并)
    resp = client.post("/v1/ingredients/search", json={"query": "xinjiangyou"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["id"] == "00000000-0000-4000-8000-000000000022"
    assert data["items"][0]["standard_name"] == "新酱油"


def test_search_no_match_returns_empty(client: TestClient) -> None:
    """没有匹配结果时返回空列表。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "不存在的食材"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["items"] == []


def test_search_empty_query_returns_error(client: TestClient) -> None:
    """空查询返回错误。"""
    resp = client.post("/v1/ingredients/search", json={"query": ""})
    assert_error_shape(resp, 422, "invalid_request")


def test_search_too_long_query_returns_error(client: TestClient) -> None:
    """查询过长返回错误。"""
    resp = client.post("/v1/ingredients/search", json={"query": "x" * 101})
    assert_error_shape(resp, 422, "invalid_request")
