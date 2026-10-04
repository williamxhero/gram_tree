"""Serving conversion contract through the public HTTP API."""

import json
from pathlib import Path

import pytest
from sqlalchemy import text

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape
from tests.test_recipes import recipe_input

FIXTURE_PATH = Path(__file__).parents[2] / "app" / "assets" / "serving_conversion_cases.json"
CASES = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
ROUNDING_CASES = json.loads(
    (Path(__file__).parents[2] / "app" / "assets" / "rounding_boundary_cases.json").read_text(
        encoding="utf-8"
    )
)
SEED_PATH = Path(__file__).parents[1] / "data" / "ingredients"


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
    legacy_ingredient_fields = (
        "id",
        "display_name",
        "original_quantity",
        "display_quantity",
        "unit",
        "rule",
        "deviation_ratio",
        "deviation_warning",
    )
    assert [
        {key: item[key] for key in legacy_ingredient_fields} for item in actual["ingredients"]
    ] == expected["ingredients"]
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


@pytest.mark.parametrize(
    "case",
    [case for case in ROUNDING_CASES if case["kind"] == "serving"],
    ids=[case["name"] for case in ROUNDING_CASES if case["kind"] == "serving"],
)
def test_serving_conversion_matches_decimal_half_up_boundary(api: Api, case: dict) -> None:
    headers = bearer(api.login(f"serving-rounding-{case['name']}@example.com"))
    body = recipe_input(f"边界-{case['name']}")
    body["snapshot"].update(
        {
            "servings": case["input"]["original_servings"],
            "ingredients": case["input"]["ingredients"],
            "steps": case["input"]["steps"],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": case["input"]["target_servings"]},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    actual = response.json()["conversion"]["ingredients"][0]["display_quantity"]
    assert actual == case["expected"]["display_quantity"]


def test_omitted_scaling_mode_uses_ingredient_default_but_explicit_mode_wins(api: Api) -> None:
    assert cli(["ingredients", "import", str(SEED_PATH)]) == 0
    ingredient_id = "b097f5a9-0641-4f00-9666-dad68756638c"
    headers = bearer(api.login("scaling-default@example.com"))

    omitted = recipe_input("默认阶梯")
    omitted["snapshot"]["ingredients"] = [
        {
            "id": "egg",
            "ingredient_id": ingredient_id,
            "display_name": "鸡蛋",
            "quantity": 3,
            "unit": "个",
        }
    ]
    omitted["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=omitted, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    saved_ingredient = saved["version"]["snapshot"]["ingredients"][0]
    assert saved_ingredient["scaling_mode"] == "round"
    conversion = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 1},
        headers=headers,
    )
    assert conversion.status_code == 200, conversion.text
    assert conversion.json()["conversion"]["ingredients"][0]["display_quantity"] == 2

    explicit = recipe_input("显式线性")
    explicit["snapshot"]["ingredients"] = [
        {
            "id": "egg",
            "ingredient_id": ingredient_id,
            "display_name": "鸡蛋",
            "quantity": 3,
            "unit": "个",
            "scaling_mode": "proportional",
        }
    ]
    explicit["snapshot"]["steps"] = []
    explicit_created = api.client.post("/v1/recipes", json=explicit, headers=headers)
    assert explicit_created.status_code == 201, explicit_created.text
    explicit_saved = explicit_created.json()
    assert explicit_saved["version"]["snapshot"]["ingredients"][0]["scaling_mode"] == "proportional"
    explicit_conversion = api.client.get(
        f"/v1/recipes/{explicit_saved['id']}/servings",
        params={"target_servings": 1},
        headers=headers,
    )
    assert explicit_conversion.status_code == 200, explicit_conversion.text
    assert explicit_conversion.json()["conversion"]["ingredients"][0]["display_quantity"] == 1.5


def test_original_serving_outside_adjustment_bounds_still_opens(api: Api) -> None:
    headers = bearer(api.login("serving-original-outside-bounds@example.com"))
    body = recipe_input("超范围原方")
    body["snapshot"]["servings"] = 30
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 30},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    conversion = response.json()["conversion"]
    assert conversion["target_servings"] == 30
    assert conversion["min_servings"] == 1
    assert conversion["max_servings"] == 30


def test_display_keeps_count_units_for_library_ingredients(api: Api) -> None:
    assert cli(["ingredients", "import", str(SEED_PATH)]) == 0
    headers = bearer(api.login("display-count@example.com"))
    body = recipe_input("计数显示")
    body["snapshot"]["ingredients"] = [
        {
            "id": "egg",
            "ingredient_id": "b097f5a9-0641-4f00-9666-dad68756638c",
            "display_name": "鸡蛋",
            "quantity": 3,
            "unit": "个",
            "scaling_mode": "round",
        }
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    snapshot_item = saved["version"]["snapshot"]["ingredients"][0]
    assert snapshot_item["base_quantity"] == 3
    assert snapshot_item["base_unit"] == "count"
    assert saved["version"]["derived"]["nutrition_per_serving"] == {
        "energy_kcal": 107.25,
        "protein_g": 9.45,
        "fat_g": 7.12,
        "carbohydrate_g": 0.53,
        "sodium_mg": 106.5,
        "estimated": True,
        "incomplete": False,
    }
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 1},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    conversion_item = response.json()["conversion"]["ingredients"][0]
    assert conversion_item["display_quantity"] == 2
    assert conversion_item["unit"] == "个"
    assert conversion_item["source"]["source_type"] == "scenario_adjusted"
    assert conversion_item["source"]["original_value"] == "3 个"
    assert conversion_item["source"]["basis"]["reason_code"] == "serving_conversion"

    response = api.client.get(
        f"/v1/recipes/{saved['id']}/display",
        params={"mode": "base", "target_servings": 1},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    item = response.json()["display"]["ingredients"][0]
    assert item["text"] == "2 个"
    assert item["display_quantity"] == 2
    assert item["display_unit"] == "个"
    assert item["source"]["source_type"] == "scenario_adjusted"
    assert item["source"]["original_value"] == "3 个"
    assert item["source"]["basis"]["text"]


@pytest.mark.parametrize(
    ("quantity", "expected_quantity", "expected_warning"),
    [(0, 0, False), (0.01, 1, True)],
)
def test_serving_round_preserves_zero_and_warns_on_tiny_positive(
    api: Api, quantity: float, expected_quantity: float, expected_warning: bool
) -> None:
    headers = bearer(api.login(f"serving-round-zero-{quantity}@example.com"))
    body = recipe_input(f"份数取整边界-{quantity}")
    body["snapshot"]["ingredients"] = [
        {
            "id": "counted",
            "display_name": "计数食材",
            "quantity": quantity,
            "unit": "个",
            "scaling_mode": "round",
        }
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 1},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    item = response.json()["conversion"]["ingredients"][0]
    assert item["display_quantity"] == expected_quantity
    assert item["deviation_warning"] is expected_warning
    assert bool(response.json()["conversion"]["warnings"]) is expected_warning


def test_proportional_tiny_quantity_has_stable_display_text(api: Api) -> None:
    headers = bearer(api.login("serving-proportional-tiny@example.com"))
    body = recipe_input("比例微量")
    body["snapshot"]["ingredients"] = [
        {
            "id": "tiny",
            "display_name": "微量食材",
            "quantity": 0.004,
            "unit": "g",
            "scaling_mode": "proportional",
        }
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/display",
        params={"mode": "base", "target_servings": 1},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    item = response.json()["display"]["ingredients"][0]
    assert item["converted_quantity"] == 0
    assert item["display_quantity"] == 0.002
    assert item["text"] == "<0.01 克"


def test_identity_conversion_preserves_precision_and_author_provenance(api: Api) -> None:
    headers = bearer(api.login("serving-identity-precision@example.com"))
    body = recipe_input("原方精度")
    body["snapshot"]["ingredients"] = [
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
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 2},
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


def test_legacy_null_scaling_mode_uses_stable_proportional_fallback(api: Api, engine) -> None:
    assert cli(["ingredients", "import", str(SEED_PATH)]) == 0
    headers = bearer(api.login("legacy-scaling-null@example.com"))
    body = recipe_input("旧版本空缩放方式")
    body["snapshot"]["ingredients"] = [
        {
            "id": "egg",
            "ingredient_id": "b097f5a9-0641-4f00-9666-dad68756638c",
            "display_name": "鸡蛋",
            "quantity": 3,
            "unit": "个",
            "scaling_mode": "round",
        }
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    with engine.begin() as connection:
        connection.execute(
            text(
                "UPDATE recipe_versions "
                "SET snapshot = jsonb_set(snapshot, '{ingredients,0,scaling_mode}', 'null'::jsonb) "
                "WHERE id = :version_id"
            ),
            {"version_id": saved["version"]["id"]},
        )

    response = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 1},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["conversion"]["ingredients"][0]["display_quantity"] == 1.5


def test_null_scaling_mode_means_unset(api: Api) -> None:
    """A null mode is the same as omitting it: library default, else proportional."""
    assert cli(["ingredients", "import", str(SEED_PATH)]) == 0
    headers = bearer(api.login("scaling-null@example.com"))
    body = recipe_input("空缩放方式")
    body["snapshot"]["ingredients"] = [
        {
            "id": "egg",
            "ingredient_id": "b097f5a9-0641-4f00-9666-dad68756638c",
            "display_name": "鸡蛋",
            "quantity": 3,
            "unit": "个",
            "scaling_mode": None,
        },
        {
            "id": "custom",
            "display_name": "自制酱",
            "quantity": 30,
            "unit": "g",
            "scaling_mode": None,
        },
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    modes = [item["scaling_mode"] for item in saved["version"]["snapshot"]["ingredients"]]
    assert modes == ["round", "proportional"]
