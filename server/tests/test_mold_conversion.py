"""Mold conversion and immutable base molds through public HTTP only."""

import json
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input

CASES = json.loads(
    (Path(__file__).parents[2] / "app" / "assets" / "mold_conversion_cases.json").read_text(
        encoding="utf-8"
    )
)
ROUNDING_CASES = json.loads(
    (Path(__file__).parents[2] / "app" / "assets" / "rounding_boundary_cases.json").read_text(
        encoding="utf-8"
    )
)


def test_author_saves_base_mold_and_converts_without_mutating_snapshot(api: Api) -> None:
    headers = bearer(api.login("mold-author@example.com"))
    body = recipe_input("模具蛋糕")
    body["snapshot"]["base_mold"] = {"shape": "round", "unit": "in", "diameter": 6}
    body["snapshot"]["ingredients"] = [
        {"id": "flour", "display_name": "面粉", "quantity": 100, "unit": "g"},
        {"id": "egg", "display_name": "鸡蛋", "quantity": 3, "unit": "个", "scaling_mode": "round"},
    ]
    body["snapshot"]["steps"] = [
        {
            "id": "rest",
            "instruction": "静置面团",
            "action": "静置",
            "cookware": "案板",
            "duration_seconds": 600,
        },
        {
            "id": "bake",
            "instruction": "烤至成熟",
            "action": "烘烤",
            "cookware": "烤箱",
            "duration_seconds": 1800,
            "temperature_celsius": 170,
            "doneness": "竹签插入不粘",
        },
    ]
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    saved = response.json()
    result = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "in", "diameter": 8}},
        headers=headers,
    )
    assert result.status_code == 200, result.text
    conversion = result.json()["conversion"]
    assert conversion["area_ratio"] == 1.78
    assert conversion["ingredients"][0]["display_quantity"] == 177.78
    assert conversion["ingredients"][0]["rule"] == "mold_ratio"
    assert conversion["ingredients"][0]["source"]["source_type"] == "scenario_adjusted"
    assert conversion["ingredients"][0]["source"]["original_value"] == "100 g"
    assert conversion["ingredients"][0]["source"]["basis"]["reason_code"] == "mold_conversion"
    assert conversion["ingredients"][1]["display_quantity"] == 5
    assert conversion["ingredients"][1]["rule"] == "round"
    assert conversion["steps"][0]["doneness_warning"] is False
    assert conversion["steps"][0]["time_advisory"] is None
    assert conversion["steps"][1]["duration_seconds"] == 1800
    assert conversion["steps"][1]["temperature_celsius"] == 170
    assert "成熟判断" in conversion["steps"][1]["time_advisory"]
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved


def test_version_mold_conversion_reads_requested_immutable_snapshot(api: Api) -> None:
    headers = bearer(api.login("mold-version-author@example.com"))
    first_body = recipe_input("版本模具")
    first_body["snapshot"]["base_mold"] = {"shape": "round", "unit": "in", "diameter": 6}
    first_body["snapshot"]["ingredients"] = [
        {"id": "flour", "display_name": "面粉", "quantity": 100, "unit": "g"}
    ]
    first_body["snapshot"]["steps"] = []
    first_response = api.client.post("/v1/recipes", json=first_body, headers=headers)
    assert first_response.status_code == 201, first_response.text
    first = first_response.json()

    second_body = recipe_input("版本模具")
    second_body["snapshot"].update(
        {
            "base_mold": {"shape": "round", "unit": "in", "diameter": 8},
            "ingredients": [{"id": "flour", "display_name": "面粉", "quantity": 200, "unit": "g"}],
            "steps": [],
        }
    )
    second_response = api.client.post(
        f"/v1/recipes/{first['id']}/versions",
        json=second_body,
        headers=headers,
    )
    assert second_response.status_code == 201, second_response.text
    second = second_response.json()

    conversion_response = api.client.post(
        f"/v1/recipes/{first['id']}/versions/{first['version']['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "in", "diameter": 8}},
        headers=headers,
    )
    assert conversion_response.status_code == 200, conversion_response.text
    payload = conversion_response.json()
    assert payload["version_id"] == first["version"]["id"]
    assert payload["conversion"]["original_mold"]["diameter"] == 6
    ingredient = payload["conversion"]["ingredients"][0]
    assert ingredient["original_quantity"] == 100
    assert ingredient["display_quantity"] == 177.78
    assert ingredient["source"]["source_type"] == "scenario_adjusted"
    assert ingredient["source"]["original_value"] == "100 g"

    first_read = api.client.get(
        f"/v1/recipes/{first['id']}/versions/{first['version']['id']}",
        headers=headers,
    )
    assert first_read.status_code == 200, first_read.text
    assert first_read.json()["version"]["snapshot"] == first["version"]["snapshot"]
    current_read = api.client.get(f"/v1/recipes/{first['id']}", headers=headers)
    assert current_read.status_code == 200, current_read.text
    assert current_read.json()["version"]["id"] == second["version"]["id"]
    assert current_read.json()["version"]["snapshot"] == second["version"]["snapshot"]


def test_invalid_target_mold_returns_structured_http_error(api: Api) -> None:
    headers = bearer(api.login("mold-invalid@example.com"))
    body = recipe_input("无效模具")
    body["snapshot"]["base_mold"] = {
        "shape": "round",
        "unit": "in",
        "diameter": 6,
    }
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text

    response = api.client.post(
        f"/v1/recipes/{created.json()['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "in", "diameter": 0}},
        headers=headers,
    )
    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "invalid_request"
    assert error["message"]

    conflict = api.client.post(
        f"/v1/recipes/{created.json()['id']}/mold",
        json={
            "target_mold": {
                "shape": "square",
                "unit": "cm",
                "side": 10,
                "width": 12,
                "length": 10,
            }
        },
        headers=headers,
    )
    assert conflict.status_code == 422
    conflict_error = conflict.json()["error"]
    assert conflict_error["code"] == "invalid_request"
    detail = conflict_error["detail"] or ""
    assert "side" in detail or "width" in detail


@pytest.mark.parametrize(
    ("quantity", "expected_quantity", "expected_warning"),
    [(0, 0, False), (0.001, 1, True)],
)
def test_mold_round_preserves_zero_and_warns_on_tiny_positive(
    api: Api, quantity: float, expected_quantity: float, expected_warning: bool
) -> None:
    headers = bearer(api.login(f"mold-round-zero-{quantity}@example.com"))
    body = recipe_input(f"模具取整边界-{quantity}")
    body["snapshot"].update(
        {
            "base_mold": {"shape": "round", "unit": "cm", "diameter": 4},
            "ingredients": [
                {
                    "id": "counted",
                    "display_name": "计数食材",
                    "quantity": quantity,
                    "unit": "个",
                    "scaling_mode": "round",
                }
            ],
            "steps": [],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "cm", "diameter": 2}},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    conversion = response.json()["conversion"]
    item = conversion["ingredients"][0]
    assert item["display_quantity"] == expected_quantity
    assert item["deviation_warning"] is expected_warning
    assert bool(conversion["warnings"]) is expected_warning


def test_round_back_mold_conversion_remains_scenario_adjusted(api: Api) -> None:
    headers = bearer(api.login("mold-round-back-source@example.com"))
    body = recipe_input("模具取整回原值")
    body["snapshot"].update(
        {
            "base_mold": {"shape": "round", "unit": "cm", "diameter": 4},
            "ingredients": [
                {
                    "id": "counted",
                    "display_name": "计数食材",
                    "quantity": 1,
                    "unit": "个",
                    "scaling_mode": "round",
                }
            ],
            "steps": [],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    response = api.client.post(
        f"/v1/recipes/{created.json()['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "cm", "diameter": 2}},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    item = response.json()["conversion"]["ingredients"][0]
    assert item["display_quantity"] == 1
    assert item["source"]["source_type"] == "scenario_adjusted"
    assert item["source"]["original_value"] == "1 个"
    assert "取整" in item["source"]["basis"]["text"]


def test_identity_mold_conversion_preserves_precision_and_author_provenance(api: Api) -> None:
    headers = bearer(api.login("mold-identity-precision@example.com"))
    body = recipe_input("原模具精度")
    body["snapshot"].update(
        {
            "base_mold": {"shape": "round", "unit": "cm", "diameter": 15},
            "ingredients": [
                {
                    "id": "fixed-small",
                    "display_name": "固定微量",
                    "quantity": 0.004,
                    "unit": "g",
                    "scaling_mode": "unchanged",
                },
                {
                    "id": "precise",
                    "display_name": "精确用量",
                    "quantity": 1.234,
                    "unit": "g",
                    "scaling_mode": "proportional",
                },
            ],
            "steps": [],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "cm", "diameter": 15}},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    items = response.json()["conversion"]["ingredients"]
    assert [item["display_quantity"] for item in items] == [0.004, 1.234]
    assert [item["source"]["source_type"] for item in items] == [
        "author_filled",
        "author_filled",
    ]
    assert [item["source"]["original_value"] for item in items] == [None, None]
    assert items[0]["source"]["value"] == "<0.01 g"
    assert items[1]["source"]["value"] == "1.234 g"


def test_equal_area_mold_change_is_a_scenario_conversion_without_rounding(api: Api) -> None:
    """A different mold with the same bottom area is still a chosen scenario.

    The App marks any structurally different target mold as an active
    conversion, so the server provenance must agree even when the area ratio
    is exactly 1; values keep author precision and no rounding warning appears.
    """
    headers = bearer(api.login("mold-equal-area@example.com"))
    body = recipe_input("等面积换模具")
    body["snapshot"].update(
        {
            "base_mold": {"shape": "square", "unit": "cm", "side": 10},
            "ingredients": [
                {
                    "id": "batter",
                    "display_name": "面糊",
                    "quantity": 100,
                    "unit": "g",
                    "scaling_mode": "proportional",
                },
                {
                    "id": "lemon",
                    "display_name": "柠檬",
                    "quantity": 0.5,
                    "unit": "个",
                    "scaling_mode": "round",
                },
            ],
            "steps": [],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    target = {"shape": "rectangular", "unit": "cm", "width": 5, "length": 20}

    response = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": target},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    conversion = response.json()["conversion"]
    assert conversion["area_ratio"] == 1
    assert conversion["warnings"] == []
    items = conversion["ingredients"]
    assert [item["display_quantity"] for item in items] == [100, 0.5]
    assert [item["deviation_warning"] for item in items] == [False, False]
    assert [item["source"]["source_type"] for item in items] == [
        "scenario_adjusted",
        "scenario_adjusted",
    ]
    assert [item["source"]["original_value"] for item in items] == ["100 g", "0.5 个"]
    assert all("底面积比例为 1" in item["source"]["basis"]["text"] for item in items)

    display = api.client.get(
        f"/v1/recipes/{saved['id']}/display",
        params={"mode": "base", "target_mold": json.dumps(target)},
        headers=headers,
    )
    assert display.status_code == 200, display.text
    shown = display.json()["display"]["ingredients"]
    assert [item["display_quantity"] for item in shown] == [100, 0.5]
    assert [item["source"]["source_type"] for item in shown] == [
        "scenario_adjusted",
        "scenario_adjusted",
    ]


@pytest.mark.parametrize("case", CASES, ids=[case["name"] for case in CASES])
def test_mold_conversion_matches_shared_fixture(api: Api, case: dict) -> None:
    headers = bearer(api.login(f"mold-fixture-{case['name']}@example.com"))
    source = case["input"]
    body = recipe_input(f"模具-{case['name']}")
    body["snapshot"].update(
        {
            "base_mold": source["original_mold"],
            "ingredients": source["ingredients"],
            "steps": source["steps"],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": source["target_mold"]},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    actual = response.json()["conversion"]
    expected = case["expected"]
    assert actual["area_ratio"] == expected["area_ratio"]
    assert [
        {
            "id": item["id"],
            "original_quantity": item["original_quantity"],
            "display_quantity": item["display_quantity"],
            "unit": item["unit"],
            "rule": item["rule"],
        }
        for item in actual["ingredients"]
    ] == expected["ingredients"]
    if "warnings" in expected:
        assert actual["warnings"] == expected["warnings"]
    if expected["step"] is None:
        assert actual["steps"] == []
    else:
        step = actual["steps"][0]
        assert step["duration_seconds"] == expected["step"]["duration_seconds"]
        assert step["temperature_celsius"] == expected["step"]["temperature_celsius"]
        assert bool(step["time_advisory"]) is expected["step"]["has_time_advisory"]
        assert step["doneness_warning"] is expected["step"]["doneness_warning"]


@pytest.mark.parametrize(
    "case",
    [case for case in ROUNDING_CASES if case["kind"] == "mold"],
    ids=[case["name"] for case in ROUNDING_CASES if case["kind"] == "mold"],
)
def test_mold_conversion_matches_decimal_half_up_boundary(api: Api, case: dict) -> None:
    headers = bearer(api.login(f"mold-rounding-{case['name']}@example.com"))
    source = case["input"]
    body = recipe_input(f"边界-{case['name']}")
    body["snapshot"].update(
        {
            "base_mold": source["original_mold"],
            "ingredients": source["ingredients"],
            "steps": source["steps"],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": source["target_mold"]},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    actual = response.json()["conversion"]
    assert actual["area_ratio"] == case["expected"]["area_ratio"]
    assert actual["ingredients"][0]["display_quantity"] == case["expected"]["display_quantity"]
