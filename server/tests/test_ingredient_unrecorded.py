"""测试未收录食材统计功能 (#102)"""

from fastapi.testclient import TestClient


def test_normalize_records_unrecorded_ingredient(client: TestClient):
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
    response = client.get("/v1/ingredients/unrecorded")
    assert response.status_code == 200
    unrecorded = response.json()
    assert len(unrecorded) == 1
    assert unrecorded[0]["name"] == "火星土豆"
    assert unrecorded[0]["occurrence_count"] == 1

    # 第二次调用同一个未收录食材
    response = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "火星土豆"}]},
    )
    assert response.status_code == 200

    # 查询未收录列表，次数应该变成 2
    response = client.get("/v1/ingredients/unrecorded")
    assert response.status_code == 200
    unrecorded = response.json()
    assert len(unrecorded) == 1
    assert unrecorded[0]["name"] == "火星土豆"
    assert unrecorded[0]["occurrence_count"] == 2


def test_unrecorded_list_ordering(client: TestClient):
    """测试未收录列表按出现次数降序排列"""
    # 调用多个未收录食材，次数不同
    for _ in range(5):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "食材A"}]})
    for _ in range(3):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "食材B"}]})
    for _ in range(7):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": "食材C"}]})

    # 查询列表
    response = client.get("/v1/ingredients/unrecorded")
    assert response.status_code == 200
    unrecorded = response.json()

    # 应该按次数降序排列：C(7) > A(5) > B(3)
    assert len(unrecorded) == 3
    assert unrecorded[0]["name"] == "食材C"
    assert unrecorded[0]["occurrence_count"] == 7
    assert unrecorded[1]["name"] == "食材A"
    assert unrecorded[1]["occurrence_count"] == 5
    assert unrecorded[2]["name"] == "食材B"
    assert unrecorded[2]["occurrence_count"] == 3


def test_unrecorded_list_limit(client: TestClient):
    """测试未收录列表的 limit 参数"""
    # 调用 10 个不同的未收录食材
    for i in range(10):
        client.post("/v1/ingredients/normalize", json={"items": [{"name": f"食材{i}"}]})

    # 默认 limit=50，应该返回全部 10 个
    response = client.get("/v1/ingredients/unrecorded")
    assert response.status_code == 200
    assert len(response.json()) == 10

    # limit=5，应该返回 5 个
    response = client.get("/v1/ingredients/unrecorded?limit=5")
    assert response.status_code == 200
    assert len(response.json()) == 5


def test_normalized_ingredient_not_recorded_as_unrecorded(client: TestClient):
    """测试已归一化的食材不会被记录为未收录"""
    # 先调用一个未收录的食材
    response = client.post(
        "/v1/ingredients/normalize",
        json={"items": [{"name": "月球奶酪"}]},
    )
    assert response.status_code == 200

    # 查询未收录列表，应该有这个食材
    response = client.get("/v1/ingredients/unrecorded")
    assert response.status_code == 200
    unrecorded = response.json()
    assert len(unrecorded) == 1
    assert unrecorded[0]["name"] == "月球奶酪"
