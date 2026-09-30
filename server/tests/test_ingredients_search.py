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


def test_search_is_case_insensitive_trimmed_and_returns_matched_name(client: TestClient) -> None:
    """搜索会规范首尾空格和大小写，并返回实际命中的叫法。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "  CsjY  "})
    assert resp.status_code == 200
    item = resp.json()["items"][0]
    assert item["standard_name"] == "测试酱油"
    assert item["matched_name"] == "csjy"


def test_search_old_merged_name_returns_current_identity_and_old_spelling(
    client: TestClient,
) -> None:
    """已合并食材的旧标准名仍可搜索，但结果身份是当前标准食材。"""
    fixture = Path(__file__).parent / "data" / "ingredients_normalize"
    assert cli(["ingredients", "import", str(fixture)]) == 0

    resp = client.post("/v1/ingredients/search", json={"query": "  洋柿子  "})
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 1
    assert items[0]["id"] == "00000000-0000-4000-8000-000000000107"
    assert items[0]["standard_name"] == "番茄"
    assert items[0]["matched_name"] == "洋柿子"


def test_search_cursor_is_opaque_stable_and_bound_to_query(client: TestClient) -> None:
    """搜索游标按稳定排序键续页，且不能拿去请求另一种查询。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "2.1.0", "changelog": "测试游标"}), encoding="utf-8"
        )
        items = [
            {
                "id": f"00000000-0000-4000-8000-{i:012d}",
                "standard_name": f"分页食材{i}",
                "aliases": [],
                "pinyin": f"fenyeshicai{chr(97 + i)}",
                "pinyin_initials": f"fys{chr(97 + i)}",
                "category": "调料",
            }
            for i in range(3)
        ]
        (tmp / "data.json").write_text(json.dumps(items), encoding="utf-8")
        assert cli(["ingredients", "import", str(tmp)]) == 0

    first = client.post("/v1/ingredients/search?limit=1", json={"query": "分页"})
    assert first.status_code == 200
    page = first.json()
    assert len(page["items"]) == 1
    cursor = page["next_cursor"]
    assert cursor and "分页" not in cursor

    second = client.post(f"/v1/ingredients/search?limit=1&cursor={cursor}", json={"query": "分页"})
    assert second.status_code == 200
    assert second.json()["items"][0]["id"] != page["items"][0]["id"]

    bad_query = client.post(
        f"/v1/ingredients/search?limit=1&cursor={cursor}", json={"query": "其他"}
    )
    assert_error_shape(bad_query, 422, "invalid_cursor")

    invalid = client.post("/v1/ingredients/search?cursor=not-a-cursor", json={"query": "分页"})
    assert_error_shape(invalid, 422, "invalid_cursor")


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
    """搜索按标准名精确、别名精确、名称前缀、拼音的质量排序。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(
            json.dumps({"version": "2.0.0", "changelog": "测试排序"}), encoding="utf-8"
        )
        items = [
            {
                "id": "00000000-0000-4000-8000-000000000011",
                "standard_name": "j",
                "aliases": [],
                "pinyin": "j",
                "pinyin_initials": "j",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000012",
                "standard_name": "jam",
                "aliases": [],
                "pinyin": "jam",
                "pinyin_initials": "j",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000013",
                "standard_name": "调味料",
                "aliases": ["x"],
                "pinyin": "tiaoweiliao",
                "pinyin_initials": "twl",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000014",
                "standard_name": "xylophone",
                "aliases": [],
                "pinyin": "xylophone",
                "pinyin_initials": "x",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000016",
                "standard_name": "香料",
                "aliases": [],
                "pinyin": "jiangliao",
                "pinyin_initials": "jl",
                "category": "调料",
            },
            {
                "id": "00000000-0000-4000-8000-000000000017",
                "standard_name": "香草",
                "aliases": [],
                "pinyin": "xiangcao",
                "pinyin_initials": "xc",
                "category": "调料",
            },
        ]
        (tmp / "data.json").write_text(json.dumps(items), encoding="utf-8")
        assert cli(["ingredients", "import", str(tmp)]) == 0

    standard_first = client.post("/v1/ingredients/search", json={"query": "j"})
    assert standard_first.status_code == 200
    assert [item["id"] for item in standard_first.json()["items"]] == [
        "00000000-0000-4000-8000-000000000011",
        "00000000-0000-4000-8000-000000000012",
        "00000000-0000-4000-8000-000000000016",
    ]
    assert [item["matched_name"] for item in standard_first.json()["items"]] == ["j", "jam", "jl"]

    alias_first = client.post("/v1/ingredients/search", json={"query": "x"})
    assert alias_first.status_code == 200
    assert [item["id"] for item in alias_first.json()["items"]] == [
        "00000000-0000-4000-8000-000000000013",
        "00000000-0000-4000-8000-000000000014",
        "00000000-0000-4000-8000-000000000017",
    ]
    assert [item["matched_name"] for item in alias_first.json()["items"]] == [
        "x",
        "xylophone",
        "xc",
    ]


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
