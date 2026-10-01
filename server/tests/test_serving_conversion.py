"""Serving conversion contract through the public HTTP API."""

import json
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape
from tests.test_recipes import recipe_input

FIXTURE_PATH = Path(__file__).parents[2] / "app" / "assets" / "serving_conversion_cases.json"
CASES = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def _recipe_body(case: dict) -> dict:
    source = case["input"]
    return {
        **recipe_input(f"换算-{case['name']}"),
        "snapshot": {
            "format_version": 1,
            "servings": source["original_servings"],
            "ingredients": source["ingredients"],
            "steps": source["steps"],
        },
    }


def _assert_conversion(actual: dict, expected: dict) -> None:
    assert actual["original_servings"] == expected["original_servings"]
    assert actual["target_servings"] == expected["target_servings"]
    assert actual["min_servings"] == expected["min_servings"]
    assert actual["max_servings"] == expected["max_servings"]
    assert actual["ingredients"] == expected["ingredients"]
    assert actual["steps"] == expected["steps"]
    assert actual["warnings"] == expected["warnings"]
    assert actual["total_time_seconds"] == expected["total_time_seconds"]
    assert actual["active_time_seconds"] == expected["active_time_seconds"]


@pytest.mark.parametrize("case", CASES, ids=[case["name"] for case in CASES])
def test_serving_conversion_matches_shared_fixture(api: Api, case: dict) -> None:
    headers = bearer(api.login(f"serving-{case['name']}@example.com"))
    created = api.client.post("/v1/recipes", json=_recipe_body(case), headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()

    response = api.client.get(
        f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}/servings",
        params={"target_servings": case["input"]["target_servings"]},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    payload = response.json()
    assert payload["recipe_id"] == saved["id"]
    assert payload["version_id"] == saved["version"]["id"]
    _assert_conversion(payload["conversion"], case["expected"])


def test_serving_conversion_accepts_current_recipe_endpoint(api: Api) -> None:
    headers = bearer(api.login("serving-current@example.com"))
    created = api.client.post("/v1/recipes", json=_recipe_body(CASES[2]), headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()

    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 4},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["version_id"] == saved["version"]["id"]
    assert response.json()["conversion"]["target_servings"] == 4


def test_serving_conversion_rejects_values_outside_configured_bounds(api: Api) -> None:
    headers = bearer(api.login("serving-bounds@example.com"))
    created = api.client.post("/v1/recipes", json=_recipe_body(CASES[1]), headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()

    for target in (0, 21):
        response = api.client.get(
            f"/v1/recipes/{saved['id']}/servings",
            params={"target_servings": target},
            headers=headers,
        )
        error = assert_error_shape(response, 422, "invalid_servings")
        assert error["detail"]


def test_serving_conversion_keeps_private_recipe_scope(api: Api) -> None:
    owner_headers = bearer(api.login("serving-owner@example.com"))
    created = api.client.post("/v1/recipes", json=_recipe_body(CASES[1]), headers=owner_headers)
    assert created.status_code == 201, created.text

    other_headers = bearer(api.login("serving-other@example.com"))
    response = api.client.get(
        f"/v1/recipes/{created.json()['id']}/servings",
        params={"target_servings": 2},
        headers=other_headers,
    )
    assert_error_shape(response, 404, "not_found")
