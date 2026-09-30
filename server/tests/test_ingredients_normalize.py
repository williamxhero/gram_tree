"""测试食材归一接口 (ticket #100, SPEC-002.1)。

按 CLAUDE.md 规则只通过外部接口测试：CLI 导入命令和 HTTP 接口。
"""

import json
import tempfile
from collections.abc import Mapping, Sequence
from pathlib import Path

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.test_conventions import assert_error_shape

FIXTURES = Path(__file__).parent / "data" / "ingredients_normalize"

SOY = "00000000-0000-4000-8000-000000000101"
SALT = "00000000-0000-4000-8000-000000000102"
GINGER = "00000000-0000-4000-8000-000000000103"
SCALLION = "00000000-0000-4000-8000-000000000104"
LEEK = "00000000-0000-4000-8000-000000000105"
VERMICELLI = "00000000-0000-4000-8000-000000000106"
TOMATO = "00000000-0000-4000-8000-000000000107"


def _record(id_suffix: str, name: str, aliases: list[str]) -> dict[str, object]:
    return {
        "id": f"00000000-0000-4000-8000-{id_suffix:0>12}",
        "standard_name": name,
        "aliases": aliases,
        "pinyin": "ceshi",
        "pinyin_initials": "cs",
        "category": "调料",
    }


def _import(manifest: Mapping[str, object], records: Sequence[Mapping[str, object]]) -> int:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        (tmp / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
        (tmp / "data.json").write_text(json.dumps(records), encoding="utf-8")
        return cli(["ingredients", "import", str(tmp)])


# 输入名称 → (期望把握程度, 期望标准 ID, 期望标准名, 期望候选)
CASES: list[tuple[str, str, str | None, str | None, list[str]]] = [
    ("酱油", "exact", SOY, "酱油", []),
    (" 盐 ", "exact", SALT, "盐", []),
    ("粉丝", "exact", VERMICELLI, "粉丝", []),
    ("生抽", "alias", SOY, "酱油", []),
    ("精盐", "alias", SALT, "盐", []),
    ("香葱", "alias", SCALLION, "小葱", []),
    # 模糊匹配：去掉常见修饰词，或者本来就是拼音
    ("新鲜姜", "fuzzy", GINGER, "姜", []),
    ("姜丝", "fuzzy", GINGER, "姜", []),
    ("盐适量", "fuzzy", SALT, "盐", []),
    ("生抽（李锦记）", "fuzzy", SOY, "酱油", []),
    ("小葱 花", "fuzzy", SCALLION, "小葱", []),
    ("jiangyou", "fuzzy", SOY, "酱油", []),
    ("生姜末", "fuzzy", GINGER, "姜", []),
    ("JIANGYOU", "fuzzy", SOY, "酱油", []),
    # 标准名本身以“丝”结尾也不能被拆掉：别名整体命中
    ("龙口粉丝", "alias", VERMICELLI, "粉丝", []),
    # 模糊匹配只在唯一候选时才认：去掉修饰词后落到歧义名上，算未收录
    ("葱丝", "unrecorded", None, None, []),
    # 已合并食材：旧标准名和旧别名都归到新 ID
    ("洋柿子", "alias", TOMATO, "番茄", []),
    ("洋柿", "alias", TOMATO, "番茄", []),
    ("番茄", "exact", TOMATO, "番茄", []),
    # 登记过的歧义名：返回候选列表，不挑一个
    ("葱", "ambiguous", None, None, [LEEK, SCALLION]),
    # 未收录：保留原文
    ("龙涎香", "unrecorded", None, None, []),
    ("新鲜", "unrecorded", None, None, []),
]


def test_normalize_table(client: TestClient) -> None:
    """一次提交整张表，按输入顺序逐条核对标准 ID 和把握程度。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": name} for name, *_ in CASES]},
    )
    assert resp.status_code == 200
    results = resp.json()["results"]
    assert len(results) == len(CASES)
    for case, got in zip(CASES, results, strict=True):
        name, confidence, ingredient_id, standard_name, candidates = case
        assert got["name"] == name, name
        assert got["confidence"] == confidence, name
        assert got["ingredient_id"] == ingredient_id, name
        assert got["standard_name"] == standard_name, name
        assert [c["ingredient_id"] for c in got["candidates"]] == candidates, name
        for candidate in got["candidates"]:
            assert candidate["standard_name"], name


def test_normalize_keeps_input_order(client: TestClient) -> None:
    """结果顺序和输入顺序一致，重复名称各占一条。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "盐"}, {"name": "不存在"}, {"name": "盐"}]},
    )
    assert resp.status_code == 200
    results = resp.json()["results"]
    assert [r["name"] for r in results] == ["盐", "不存在", "盐"]
    assert [r["confidence"] for r in results] == ["exact", "unrecorded", "exact"]


def test_normalize_accepts_context(client: TestClient) -> None:
    """每个名称可以带上下文（如所在菜名），不影响按名称匹配的结果。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    resp = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "生抽", "context": "凉拌黄瓜"}]},
    )
    assert resp.status_code == 200
    assert resp.json()["results"][0]["ingredient_id"] == SOY


def test_normalize_rejects_too_many_names(client: TestClient) -> None:
    """一次的名称数量有上限，超出按 ADR 0002 返回 422。"""
    resp = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": f"食材{i}"} for i in range(101)]},
    )
    assert_error_shape(resp, 422, "invalid_request")

    resp = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": f"食材{i}"} for i in range(100)]},
    )
    assert resp.status_code == 200
    assert len(resp.json()["results"]) == 100


def test_normalize_rejects_empty_and_blank_names(client: TestClient) -> None:
    """空的批次和空名称都返回参数错误。"""
    assert_error_shape(
        client.post("/v1/ingredients/normalize", json={"items": []}), 422, "invalid_request"
    )
    assert_error_shape(
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "  "}]}),
        422,
        "invalid_request",
    )


def test_import_accepts_registered_ambiguous_name(client: TestClient) -> None:
    """manifest 里登记过的歧义名可以同时指向多种食材。"""
    assert cli(["ingredients", "import", str(FIXTURES)]) == 0

    for ingredient_id in (SCALLION, LEEK):
        resp = client.get(f"/v1/ingredients/{ingredient_id}")
        assert resp.status_code == 200
        assert "葱" in resp.json()["aliases"]


def test_import_rejects_unregistered_shared_name() -> None:
    """没登记成歧义名的名称仍然不能指向两种食材。"""
    manifest = {"version": "1.0.0", "changelog": "测试"}
    records = [_record("1", "甲", ["共用"]), _record("2", "乙", ["共用"])]
    assert _import(manifest, records) == 1


def test_import_rejects_ambiguous_name_used_only_once() -> None:
    """登记了歧义名却只有一种食材在用，说明登记过期了，导入失败。"""
    manifest = {"version": "1.0.0", "changelog": "测试", "ambiguous_names": ["共用"]}
    records = [_record("1", "甲", ["共用"]), _record("2", "乙", [])]
    assert _import(manifest, records) == 1


def test_import_rejects_standard_name_registered_as_ambiguous() -> None:
    """标准名必须唯一，不能登记成歧义名。"""
    manifest = {"version": "1.0.0", "changelog": "测试", "ambiguous_names": ["甲"]}
    records = [_record("1", "甲", []), _record("2", "乙", ["甲"])]
    assert _import(manifest, records) == 1
