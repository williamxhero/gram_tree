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
