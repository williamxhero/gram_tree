"""测试未收录食材统计功能 (#102)"""

import json
import tempfile
from pathlib import Path

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from gramtree.ingredients.router import get_unrecorded_statistics_writer
from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape


def test_normalize_records_unrecorded_ingredient(api: Api) -> None:
    client = api.client
    headers = bearer(api.login("operator@example.com"))
    """测试归一化接口在返回 unrecorded 时自动记录"""
    # 第一次调用未收录食材
    response = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "火星土豆"}]},
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data["results"]) == 1
    assert data["results"][0]["confidence"] == "unrecorded"
    assert data["results"][0]["name"] == "火星土豆"

    # 查询未收录列表，应该有这个食材，次数为 1
    response = client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    unrecorded = response.json()
    assert unrecorded["next_cursor"] is None
    assert len(unrecorded["items"]) == 1
    assert unrecorded["items"][0]["name"] == "火星土豆"
    assert unrecorded["items"][0]["occurrence_count"] == 1

    # 第二次调用同一个未收录食材
    response = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "火星土豆"}]},
    )
    assert response.status_code == 200

    # 查询未收录列表，次数应该变成 2
    response = client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    unrecorded = response.json()
    assert len(unrecorded["items"]) == 1
    assert unrecorded["items"][0]["name"] == "火星土豆"
    assert unrecorded["items"][0]["occurrence_count"] == 2


def test_unrecorded_list_ordering(api: Api) -> None:
    client = api.client
    headers = bearer(api.login("operator@example.com"))
    """测试未收录列表按出现次数降序排列"""
    # 调用多个未收录食材，次数不同
    for _ in range(5):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "食材A"}]})
    for _ in range(3):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "食材B"}]})
    for _ in range(7):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "食材C"}]})

    # 查询列表
    response = client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    unrecorded = response.json()

    # 应该按次数降序排列：C(7) > A(5) > B(3)
    assert len(unrecorded["items"]) == 3
    assert unrecorded["items"][0]["name"] == "食材C"
    assert unrecorded["items"][0]["occurrence_count"] == 7
    assert unrecorded["items"][1]["name"] == "食材A"
    assert unrecorded["items"][1]["occurrence_count"] == 5
    assert unrecorded["items"][2]["name"] == "食材B"
    assert unrecorded["items"][2]["occurrence_count"] == 3


def test_unrecorded_list_limit(api: Api) -> None:
    client = api.client
    headers = bearer(api.login("operator@example.com"))
    """测试未收录列表的 limit 参数"""
    # 调用 10 个不同的未收录食材
    for i in range(10):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": f"食材{i}"}]})

    # 默认 limit=50，应该返回全部 10 个
    response = client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    assert len(response.json()["items"]) == 10

    # limit=5，应该返回 5 个
    response = client.get("/v1/ingredients/unrecorded?limit=5", headers=headers)
    assert response.status_code == 200
    assert len(response.json()["items"]) == 5


def test_normalized_ingredient_not_recorded_as_unrecorded(api: Api) -> None:
    client = api.client
    headers = bearer(api.login("operator@example.com"))
    """测试已归一化的食材不会被记录为未收录"""
    # 先调用一个未收录的食材
    response = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "月球奶酪"}]},
    )
    assert response.status_code == 200

    # 查询未收录列表，应该有这个食材
    response = client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    unrecorded = response.json()
    assert len(unrecorded["items"]) == 1
    assert unrecorded["items"][0]["name"] == "月球奶酪"


def test_unrecorded_names_are_trimmed(api: Api) -> None:
    """统计只做与归一规则一致的轻度 trim，不擅自改变名称含义。"""
    headers = bearer(api.login("operator@example.com"))
    for name in ("  火星香料  ", "火星香料"):
        response = api.client.post("/v1/ingredients/normalize", json={"items": [{"name": name}]})
        assert response.status_code == 200
        assert response.json()["results"][0]["name"] == name

    response = api.client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    items = response.json()["items"]
    assert len(items) == 1
    assert items[0]["name"] == "火星香料"
    assert items[0]["occurrence_count"] == 2
    assert items[0]["first_seen_at"] <= items[0]["last_seen_at"]


def test_unrecorded_list_requires_authentication(client: TestClient) -> None:
    response = client.get("/v1/ingredients/unrecorded")
    assert_error_shape(response, 401, "unauthorized")


def test_unrecorded_pagination_is_count_descending_and_deterministic(api: Api) -> None:
    headers = bearer(api.login("operator@example.com"))
    for name, count in (("同数乙", 2), ("同数甲", 2), ("更常见", 3)):
        for _ in range(count):
            response = api.client.post(
                "/v1/ingredients/normalize", json={"items": [{"name": name}]}
            )
            assert response.status_code == 200

    first = api.client.get("/v1/ingredients/unrecorded?limit=2", headers=headers)
    assert first.status_code == 200
    page = first.json()
    assert [item["name"] for item in page["items"]] == ["更常见", "同数乙"]
    assert page["next_cursor"]

    second = api.client.get(
        "/v1/ingredients/unrecorded?limit=2",
        params={"cursor": page["next_cursor"]},
        headers=headers,
    )
    assert second.status_code == 200
    assert [item["name"] for item in second.json()["items"]] == ["同数甲"]


def test_unrecorded_name_disappears_after_library_import(api: Api) -> None:
    headers = bearer(api.login("operator@example.com"))
    response = api.client.post("/v1/ingredients/normalize", json={"items": [{"name": "后来收录"}]})
    assert response.status_code == 200
    assert api.client.get("/v1/ingredients/unrecorded", headers=headers).json()["items"]

    with tempfile.TemporaryDirectory() as tmpdir:
        root = Path(tmpdir)
        (root / "manifest.json").write_text(
            json.dumps({"version": "9.9.9", "changelog": "测试补录"}), encoding="utf-8"
        )
        (root / "data.json").write_text(
            json.dumps(
                [
                    {
                        "id": "00000000-0000-4000-8000-000000000901",
                        "standard_name": "后来收录",
                        "aliases": [],
                        "pinyin": "houlailu",
                        "pinyin_initials": "hll",
                        "category": "调料",
                    }
                ]
            ),
            encoding="utf-8",
        )
        assert cli(["ingredients", "import", str(root)]) == 0

    response = api.client.get("/v1/ingredients/unrecorded", headers=headers)
    assert response.status_code == 200
    assert response.json()["items"] == []


def test_statistics_write_failure_does_not_break_normalization(api: Api) -> None:
    def failed_writer(_db, _counts) -> None:
        raise RuntimeError("statistics disabled")

    api.client.app.dependency_overrides[get_unrecorded_statistics_writer] = lambda: failed_writer
    try:
        response = api.client.post(
            "/v1/ingredients/normalize", json={"items": [{"name": "写入失败但仍返回"}]}
        )
    finally:
        api.client.app.dependency_overrides.pop(get_unrecorded_statistics_writer, None)

    assert response.status_code == 200
    assert response.json()["results"][0]["confidence"] == "unrecorded"
