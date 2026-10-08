"""Reproducibility behavior exclusively through authenticated public HTTP."""

import pytest

from tests.accounts_support import Api, bearer


def draft() -> dict:
    return {
        "dish_name": "盐水",
        "snapshot": {
            "servings": 2,
            "ingredients": [
                {"id": "salt", "display_name": "盐", "quantity": 0, "unit": "少许"},
                {"id": "water", "display_name": "水", "quantity": 1, "unit": "碗"},
            ],
            "steps": [{"id": "mix", "action": "拌", "instruction": "混合盐和水"}],
        },
    }


def test_incomplete_private_save_retains_check_on_immutable_version(api: Api) -> None:
    headers = bearer(api.login("reproducibility@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=draft())
    assert response.status_code == 201, response.text
    saved = response.json()
    result = saved["version"]["reproducibility"]
    assert saved["visibility"] == "private"
    assert result["rules_version"] == "reproducibility-v1"
    assert result["state"] == "incomplete"
    assert result["remaining_count"] == 2
    assert result["required_field_count"] == 3
    assert result["concrete_field_count"] == 1
    assert result["field_completeness"] == 1 / 3
    assert [(p["position"]["item_id"], p["position"]["field"]) for p in result["problems"]] == [
        ("salt", "quantity"),
        ("water", "quantity"),
    ]
    assert all(p["status"] == "unresolved" for p in result["problems"])
    assert saved["version"]["snapshot"]["ingredients"][1]["base_quantity"] is None
    old_id = saved["version"]["id"]
    complete = draft()["snapshot"]
    complete["ingredients"][0].update(quantity=3, unit="g")
    complete["ingredients"][1].update(quantity=300, unit="ml")
    update = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        headers=headers,
        json={"snapshot": complete},
    )
    assert update.status_code == 201, update.text
    new_result = update.json()["version"]["reproducibility"]
    assert new_result["state"] == "reproducible"
    assert new_result["remaining_count"] == 0
    assert new_result["field_completeness"] == 1
    old = api.client.get(f"/v1/recipes/{saved['id']}/versions/{old_id}", headers=headers)
    assert old.json()["version"]["reproducibility"] == result


@pytest.mark.parametrize(
    ("ingredient_name", "step", "expected"),
    [
        ("黄瓜", {"action": "切块", "instruction": "处理黄瓜"}, {"instruction"}),
        ("黄瓜", {"action": "切块", "instruction": "处理成 2 厘米块"}, set()),
        ("黄瓜", {"action": "切成 2 厘米块", "instruction": "处理黄瓜"}, set()),
        ("黄瓜", {"instruction": "处理黄瓜", "heat": "中火", "duration_seconds": 120}, {"heat"}),
        (
            "黄瓜",
            {"instruction": "处理黄瓜", "heat": "中火，油面出现细纹", "duration_seconds": 120},
            set(),
        ),
        (
            "鸡肉",
            {"instruction": "煮鸡肉", "heat": "100℃", "duration_seconds": 600, "doneness": "   "},
            {"doneness"},
        ),
        (
            "鸡肉",
            {
                "instruction": "煮鸡肉",
                "heat": "100℃",
                "duration_seconds": 600,
                "doneness": "煮到熟透",
            },
            {"doneness"},
        ),
        (
            "鸡肉",
            {
                "instruction": "煮鸡肉",
                "heat": "100℃",
                "duration_seconds": 600,
                "doneness": "煮到熟透，食品温度计测中心达到 74℃",
            },
            set(),
        ),
        (
            "鸡肉",
            {
                "instruction": "煮鸡肉",
                "heat": "100℃",
                "duration_seconds": 600,
                "doneness": "煮到熟透，肉内无粉红色且没有血水",
            },
            set(),
        ),
    ],
)
def test_structured_execution_and_doneness_in_preview_and_immutable_save(
    api: Api, ingredient_name, step, expected
):
    headers = bearer(api.login("structured-execution@example.com"))
    snapshot = {
        "servings": 2,
        "ingredients": [
            {
                "id": "food",
                "display_name": ingredient_name,
                "quantity": 300 if ingredient_name == "鸡肉" else 100,
                "unit": "g",
            }
        ],
        "steps": [{"id": "process", **step}],
    }
    preview = api.client.post(
        "/v1/recipes/reproducibility/check", headers=headers, json={"snapshot": snapshot}
    )
    assert preview.status_code == 200, preview.text
    created = api.client.post(
        "/v1/recipes", headers=headers, json={"dish_name": "结构化执行验收", "snapshot": snapshot}
    )
    assert created.status_code == 201, created.text
    detail = created.json()
    result = preview.json()["result"]
    assert {p["position"]["field"] for p in result["problems"]} == expected
    assert result["state"] == ("incomplete" if expected else "reproducible")
    assert result["field_completeness"] < 1 if expected else result["field_completeness"] == 1
    assert detail["version"]["reproducibility"] == result
    saved = api.client.post(
        f"/v1/recipes/{detail['id']}/versions",
        headers=headers,
        json={"snapshot": snapshot, "base_version_id": detail["version"]["id"]},
    )
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["id"] != detail["version"]["id"]
    assert saved.json()["version"]["reproducibility"] == result
    history = api.client.get(
        f"/v1/recipes/{detail['id']}/versions/{detail['version']['id']}", headers=headers
    )
    assert history.json()["version"]["reproducibility"] == result


@pytest.mark.parametrize(
    ("ingredient", "step", "expected"),
    [
        ({"quantity": 0, "unit": "少许"}, {}, {("salt", "quantity")}),
        ({"display_name": "水", "quantity": 1, "unit": "碗"}, {}, {("salt", "quantity")}),
        ({"quantity": 1, "unit": "勺"}, {}, {("salt", "quantity")}),
        (
            {},
            {"action": "炒", "instruction": "中火炒", "duration_seconds": 120, "heat": "中火"},
            {("mix", "heat")},
        ),
        (
            {},
            {
                "action": "炒",
                "instruction": "中火，油面出现细纹时炒一会儿",
                "heat": "中火，油面出现细纹",
            },
            {("mix", "duration_seconds"), ("mix", "instruction")},
        ),
        (
            {"display_name": "鸡肉"},
            {"action": "炖", "instruction": "炖到软烂", "duration_seconds": 1200, "heat": "100℃"},
            {("mix", "instruction"), ("mix", "doneness")},
        ),
        ({}, {"action": "切", "instruction": "切块"}, {("mix", "instruction")}),
        (
            {"display_name": "鸡肉"},
            {"action": "煮", "instruction": "煮鸡肉", "duration_seconds": 600, "heat": "100℃"},
            {("mix", "doneness")},
        ),
        (
            {"display_name": "四季豆"},
            {
                "action": "煮",
                "instruction": "煮四季豆",
                "duration_seconds": 600,
                "temperature_celsius": 100,
            },
            {("mix", "doneness")},
        ),
        ({"preparation": "切段"}, {}, {("salt", "preparation")}),
        (
            {
                "quantity_source": {
                    "source": "ai_estimated",
                    "original": "盐少许",
                    "basis": "按主料估算",
                    "confidence": 0.7,
                }
            },
            {},
            set(),
        ),
        ({"quantity": 1, "unit": "tsp"}, {}, set()),
        ({"display_name": "水", "quantity": 1, "unit": "碗（300 ml）"}, {}, set()),
        (
            {"preparation": "切成 3 厘米见方的块"},
            {"action": "切", "instruction": "切成 3 cm 见方的块"},
            set(),
        ),
        (
            {},
            {
                "action": "炒",
                "instruction": "油面出现细纹后，中火炒 2 分钟",
                "heat": "中火；油面出现细纹",
                "duration_seconds": 120,
            },
            set(),
        ),
        (
            {"display_name": "鸡肉"},
            {
                "action": "煮",
                "instruction": "煮 10 分钟",
                "duration_seconds": 600,
                "temperature_celsius": 100,
                "doneness": "中心温度达到 74℃，肉内无粉红色",
            },
            set(),
        ),
        ({"display_name": "熟鸡肉"}, {"action": "拌", "instruction": "拌匀"}, set()),
        ({}, {"action": "切", "instruction": "切去根部，洗净"}, set()),
        (
            {"display_name": "鸡肉"},
            {
                "action": "炖",
                "instruction": "炖鸡肉",
                "duration_seconds": 1200,
                "heat": "100℃",
                "doneness": "炖到软烂",
            },
            {("mix", "doneness")},
        ),
    ],
)
def test_ambiguity_and_concrete_writing_table(
    api: Api, ingredient: dict, step: dict, expected: set
) -> None:
    body = draft()
    body["snapshot"]["ingredients"] = [
        {"id": "salt", "display_name": "盐", "quantity": 3, "unit": "g", **ingredient}
    ]
    body["snapshot"]["steps"] = [
        {"id": "mix", "action": "拌", "instruction": "拌匀", "ingredient_ids": ["salt"], **step}
    ]
    headers = bearer(api.login("check-table@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=body)
    assert response.status_code == 201, response.text
    result = response.json()["version"]["reproducibility"]
    assert {
        (p["position"]["item_id"], p["position"]["field"]) for p in result["problems"]
    } == expected
    assert result["state"] == ("incomplete" if expected else "reproducible")


@pytest.mark.parametrize(
    "path",
    [
        ("text_source",),
        ("servings_source",),
        ("ingredients", 0, "quantity_source"),
        ("ingredients", 0, "preparation_source"),
        ("steps", 0, "duration_source"),
        ("steps", 0, "heat_source"),
        ("steps", 0, "temperature_source"),
        ("steps", 0, "instruction_source"),
        ("steps", 0, "doneness_source"),
    ],
)
@pytest.mark.parametrize("endpoint", ["create", "version", "generated", "safety", "check"])
def test_client_verified_refused_at_every_source_path(api: Api, path: tuple, endpoint: str) -> None:
    headers = bearer(api.login("verified-refusal@example.com"))
    body = draft()
    body["snapshot"]["ingredients"][0].update(quantity=3, unit="g")
    saved = api.client.post("/v1/recipes", json=body, headers=headers).json()
    node = body["snapshot"]
    for key in path[:-1]:
        node = node[key]
    node[path[-1]] = {"source": "verified"}
    urls = {
        "create": "/v1/recipes",
        "version": f"/v1/recipes/{saved['id']}/versions",
        "generated": "/v1/ai/recipes/requests/11111111-1111-4111-8111-111111111111/save",
        "safety": "/v1/recipes/safety/check",
        "check": "/v1/recipes/reproducibility/check",
    }
    response = api.client.post(
        urls[endpoint],
        json=body if endpoint != "check" else {"snapshot": body["snapshot"]},
        headers=headers,
    )
    assert response.status_code == 422, response.text
    assert "已验证" in response.text


def test_server_sets_author_source_on_changed_estimates_and_defaults(api: Api) -> None:
    headers = bearer(api.login("author-sources@example.com"))
    body = draft()
    source = {
        "source": "ai_estimated",
        "original": "盐少许",
        "basis": "一般经验",
        "confidence": 0.6,
    }
    body["snapshot"]["ingredients"][0].update(
        quantity=3, unit="g", quantity_source=source, preparation="拌匀", preparation_source=source
    )
    body["snapshot"]["steps"][0].update(
        duration_seconds=120,
        duration_source=source,
        instruction_source=source,
        doneness="拌匀",
        doneness_source=source,
    )
    saved_response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()
    assert saved["version"]["snapshot"]["servings_source"]["source"] == "author_filled"
    snapshot = saved["version"]["snapshot"]
    snapshot["ingredients"][0]["quantity"] = 4
    snapshot["ingredients"][0]["preparation"] = "溶于水"
    snapshot["steps"][0]["duration_seconds"] = 180
    snapshot["steps"][0]["doneness"] = "盐全部溶解"
    result = api.client.post(
        f"/v1/recipes/{saved['id']}/versions", json={"snapshot": snapshot}, headers=headers
    )
    assert result.status_code == 201, result.text
    out = result.json()["version"]["snapshot"]
    for field in ("quantity_source", "preparation_source"):
        assert out["ingredients"][0][field]["source"] == "author_filled"
        assert out["ingredients"][0][field]["confidence"] is None
        assert out["ingredients"][0][field]["basis"] is None
    for field in ("duration_source", "doneness_source"):
        assert out["steps"][0][field]["source"] == "author_filled"
    assert out["steps"][0]["instruction_source"]["source"] == "ai_estimated"


def test_unknown_household_unit_remains_an_unresolved_private_draft(api: Api) -> None:
    headers = bearer(api.login("household-unit@example.com"))
    body = draft()
    body["snapshot"]["ingredients"][0].update(quantity=1, unit="瓢")
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    saved = response.json()
    assert saved["version"]["snapshot"]["ingredients"][0]["unit"] == "瓢"
    assert saved["version"]["snapshot"]["ingredients"][0]["base_quantity"] is None
    assert saved["version"]["reproducibility"]["remaining_count"] == 2


@pytest.mark.parametrize("field", ["quantity", "confidence"])
@pytest.mark.parametrize("value", ["NaN", "Infinity", "-Infinity"])
def test_nonfinite_execution_and_confidence_are_refused(api: Api, field: str, value: str) -> None:
    headers = bearer(api.login("finite-input@example.com"))
    body = draft()
    item = body["snapshot"]["ingredients"][0]
    if field == "quantity":
        item["quantity"] = value
    else:
        item["quantity_source"] = {"source": "ai_estimated", "confidence": value}
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 422, response.text


def test_preview_positions_and_unique_field_completeness_match_save(api: Api) -> None:
    headers = bearer(api.login("preview-positions@example.com"))
    body = draft()
    body["snapshot"]["ingredients"][0].update(quantity=3, unit="g")
    body["snapshot"]["ingredients"][1].update(quantity=300, unit="ml")
    body["snapshot"]["steps"][0].update(instruction="加少许盐和适量水，拌匀")
    preview = api.client.post(
        "/v1/recipes/reproducibility/check", json={"snapshot": body["snapshot"]}, headers=headers
    )
    assert preview.status_code == 200, preview.text
    result = preview.json()["result"]
    assert result["remaining_count"] == 2
    assert result["required_field_count"] == 3
    assert result["concrete_field_count"] == 2
    assert result["field_completeness"] == 2 / 3
    assert [(p["position"]["start"], p["position"]["end"]) for p in result["problems"]] == [
        (1, 3),
        (5, 7),
    ]
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []
    saved = api.client.post("/v1/recipes", json=body, headers=headers)
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["reproducibility"] == result


def test_verification_conditions_are_configurable_placeholders(api: Api) -> None:
    result = api.client.get("/v1/client-config")
    assert result.status_code == 200
    params = result.json()["params"]
    assert params["recipe.verification_min_distinct_cooks"] == 5
    assert params["recipe.verification_max_one_sided_feedback_ratio"] == 0.3
