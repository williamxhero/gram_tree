"""Personal measure CRUD and deterministic display conversion through public HTTP."""

import json
from pathlib import Path

import pytest

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape
from tests.test_recipes import recipe_input

FIXTURE_PATH = Path(__file__).parents[2] / "app" / "assets" / "measure_display_cases.json"
CASES = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def test_personal_measures_are_account_scoped_and_syncable(api: Api) -> None:
    owner = bearer(api.login("measures-owner@example.com", device="device-a"))
    owner_other_device = bearer(api.login("measures-owner@example.com", device="device-b"))
    other = bearer(api.login("measures-other@example.com", device="device-c"))

    created = api.client.post(
        "/v1/me/measures",
        json={"name": "白瓷勺", "kind": "spoon", "capacity_ml": 12.0},
        headers=owner,
    )
    assert created.status_code == 201, created.text
    measure = created.json()
    assert measure["name"] == "白瓷勺"
    assert measure["kind"] == "spoon"
    assert measure["capacity_ml"] == 12.0

    listed_on_other_device = api.client.get("/v1/me/measures", headers=owner_other_device)
    assert listed_on_other_device.status_code == 200
    assert listed_on_other_device.json()["items"] == [measure]
    first_page = api.client.get("/v1/me/measures", params={"limit": 1}, headers=owner_other_device)
    assert first_page.status_code == 200
    assert first_page.json()["items"] == [measure]
    read_on_other_device = api.client.get(
        f"/v1/me/measures/{measure['id']}", headers=owner_other_device
    )
    assert read_on_other_device.status_code == 200
    assert read_on_other_device.json() == measure

    listed_for_other_account = api.client.get("/v1/me/measures", headers=other)
    assert listed_for_other_account.status_code == 200
    assert listed_for_other_account.json()["items"] == []

    updated = api.client.patch(
        f"/v1/me/measures/{measure['id']}",
        json={"name": "大白瓷勺", "capacity_ml": 15},
        headers=owner,
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["name"] == "大白瓷勺"
    assert updated.json()["capacity_ml"] == 15

    hidden = api.client.get(
        f"/v1/me/measures/{measure['id']}",
        headers=other,
    )
    assert_error_shape(hidden, 404, "not_found")

    deleted = api.client.delete(f"/v1/me/measures/{measure['id']}", headers=owner)
    assert deleted.status_code == 204, deleted.text
    assert api.client.get("/v1/me/measures", headers=owner).json()["items"] == []


def test_recipe_display_reflects_updated_same_id_measure(api: Api) -> None:
    headers = bearer(api.login("measure-refresh@example.com"))
    body = recipe_input("同一量具刷新")
    body["snapshot"]["ingredients"] = [
        {
            "id": "display-ingredient",
            "display_name": "水",
            "quantity": 100,
            "unit": "ml",
            "scaling_mode": "proportional",
        }
    ]
    body["snapshot"]["steps"] = []
    created_measure = api.client.post(
        "/v1/me/measures",
        json={"name": "同一把勺", "kind": "spoon", "capacity_ml": 10},
        headers=headers,
    )
    assert created_measure.status_code == 201, created_measure.text
    measure = created_measure.json()
    created_recipe = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created_recipe.status_code == 201, created_recipe.text
    saved = created_recipe.json()
    path = f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}/display"
    params = {"mode": "home", "measure_id": measure["id"]}

    before = api.client.get(path, params=params, headers=headers)
    assert before.status_code == 200, before.text
    before_item = before.json()["display"]["ingredients"][0]
    assert before_item["text"] == "约 10 同一把勺（100 毫升）"

    updated = api.client.patch(
        f"/v1/me/measures/{measure['id']}",
        json={"capacity_ml": 20},
        headers=headers,
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["id"] == measure["id"]
    assert updated.json()["capacity_ml"] == 20
    assert updated.json()["updated_at"] != measure["updated_at"]

    after = api.client.get(path, params=params, headers=headers)
    assert after.status_code == 200, after.text
    after_item = after.json()["display"]["ingredients"][0]
    assert after_item["text"] == "约 5 同一把勺（100 毫升）"
    assert after_item["text"] != before_item["text"]


def test_personal_measure_validation_and_duplicate_names(api: Api) -> None:
    headers = bearer(api.login("measures-validation@example.com"))
    for body in (
        {"name": "", "kind": "spoon", "capacity_ml": 10},
        {"name": "勺", "kind": "plate", "capacity_ml": 10},
        {"name": "勺", "kind": "spoon", "capacity_ml": 0},
        {"name": "勺", "kind": "spoon", "capacity_ml": 10001},
    ):
        response = api.client.post("/v1/me/measures", json=body, headers=headers)
        assert_error_shape(response, 422, "invalid_request")

    first = api.client.post(
        "/v1/me/measures",
        json={"name": "同名量具", "kind": "bowl", "capacity_ml": 300},
        headers=headers,
    )
    assert first.status_code == 201, first.text
    duplicate = api.client.post(
        "/v1/me/measures",
        json={"name": "同名量具", "kind": "cup", "capacity_ml": 250},
        headers=headers,
    )
    assert_error_shape(duplicate, 409, "measure_name_taken")


DENSITY_ID = "00000000-0000-4000-8000-000000000099"


def _import_density_ingredient(tmp_path: Path, density: float) -> None:
    (tmp_path / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "display fixture"}),
        encoding="utf-8",
    )
    (tmp_path / "ingredients.json").write_text(
        json.dumps(
            [
                {
                    "id": DENSITY_ID,
                    "standard_name": "显示测试食材",
                    "aliases": [],
                    "pinyin": "xianshiceshishicai",
                    "pinyin_initials": "xscsc",
                    "category": "调料",
                    "attributes": {
                        "density": {
                            "value": density,
                            "source": "display fixture",
                            "status": "verified",
                        }
                    },
                }
            ]
        ),
        encoding="utf-8",
    )
    assert cli(["ingredients", "import", str(tmp_path)]) == 0


def test_measure_display_preserves_tiny_base_quantity_over_http(api: Api) -> None:
    headers = bearer(api.login("measure-tiny-base@example.com"))
    response = api.client.post(
        "/v1/me/measures/display",
        json={
            "base_quantity": 0.002,
            "base_unit": "g",
            "density": None,
            "mode": "base",
        },
        headers=headers,
    )
    assert response.status_code == 200, response.text
    payload = response.json()
    assert payload["display_quantity"] == 0.002
    assert payload["text"] == "<0.01 克"
    assert payload["rule"] == "base"


def test_measure_display_no_density_is_self_describing_over_http(api: Api) -> None:
    headers = bearer(api.login("measure-no-density@example.com"))
    for base_quantity, base_unit, expected_text in (
        (30, "ml", "30 毫升"),
        (20, "g", "20 克"),
    ):
        response = api.client.post(
            "/v1/me/measures/display",
            json={
                "base_quantity": base_quantity,
                "base_unit": base_unit,
                "density": None,
                "mode": "standard",
            },
            headers=headers,
        )
        assert response.status_code == 200, response.text
        payload = response.json()
        assert payload["text"] == expected_text
        assert payload["rule"] == "no_density"
        assert payload["source"]["source_type"] == "author_filled"
        assert payload["source"]["basis"]["reason_code"] == "no_density"
        assert "缺少密度数据" in payload["source"]["basis"]["text"]


@pytest.mark.parametrize("case", CASES, ids=[case["name"] for case in CASES])
def test_recipe_display_matches_shared_fixture_through_http(
    api: Api, case: dict, tmp_path: Path
) -> None:
    headers = bearer(
        api.login(
            f"recipe-display-{case['input']['mode']}-{case['input']['base_quantity']}@example.com"
        )
    )
    source = case["input"]
    measure = source.get("measure")
    density = source.get("density")
    if density is not None:
        _import_density_ingredient(tmp_path, density)
    ingredient = {
        "id": "display-ingredient",
        "display_name": "显示测试食材",
        "quantity": source["base_quantity"],
        "unit": source["base_unit"],
        "scaling_mode": "proportional",
    }
    if density is not None:
        ingredient["ingredient_id"] = DENSITY_ID
    body = recipe_input(f"显示-{case['name']}")
    body["snapshot"]["ingredients"] = [ingredient]
    body["snapshot"]["steps"] = []
    created_measure_id = None
    if measure is not None:
        created_measure = api.client.post("/v1/me/measures", json=measure, headers=headers)
        assert created_measure.status_code == 201, created_measure.text
        created_measure_id = created_measure.json()["id"]

    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    params = {"mode": source["mode"]}
    if created_measure_id is not None:
        params["measure_id"] = created_measure_id
    response = api.client.get(
        f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}/display",
        params=params,
        headers=headers,
    )
    assert response.status_code == 200, response.text
    display = response.json()["display"]
    assert display["recipe_id"] == saved["id"]
    assert display["version_id"] == saved["version"]["id"]
    assert display["mode"] == source["mode"]
    assert display["measure_id"] == created_measure_id
    actual = display["ingredients"][0]
    expected = case["expected"]
    assert {
        key: actual[key] for key in ("text", "display_quantity", "display_unit", "grams", "rule")
    } == expected
    assert actual["original_quantity"] == source["base_quantity"]
    assert actual["original_unit"] == source["base_unit"]
    assert actual["source"]["source_type"] in {
        "author_filled",
        "scenario_adjusted",
        "ai_estimated",
        "verified",
    }
    assert actual["source"]["basis"]["text"]

    current = api.client.get(
        f"/v1/recipes/{saved['id']}/display",
        params=params,
        headers=headers,
    )
    assert current.status_code == 200, current.text
    assert current.json() == response.json()
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved


def test_recipe_display_keeps_private_recipe_and_measure_scope(api: Api) -> None:
    owner = bearer(api.login("recipe-display-owner@example.com", device="device-a"))
    other_device = bearer(api.login("recipe-display-owner@example.com", device="device-b"))
    other_account = bearer(api.login("recipe-display-other@example.com", device="device-c"))
    body = recipe_input("显示权限")
    body["snapshot"]["ingredients"] = [
        {
            "id": "display-ingredient",
            "display_name": "水",
            "quantity": 30,
            "unit": "ml",
            "scaling_mode": "proportional",
        }
    ]
    body["snapshot"]["steps"] = []
    created = api.client.post("/v1/recipes", json=body, headers=owner)
    assert created.status_code == 201, created.text
    saved = created.json()
    measure = api.client.post(
        "/v1/me/measures",
        json={"name": "权限勺", "kind": "spoon", "capacity_ml": 15},
        headers=owner,
    )
    assert measure.status_code == 201, measure.text
    measure_id = measure.json()["id"]
    path = f"/v1/recipes/{saved['id']}/display"
    assert api.client.get(path, params={"mode": "base"}, headers=other_account).status_code == 404
    assert (
        api.client.get(
            path,
            params={"mode": "home", "measure_id": measure_id},
            headers=other_device,
        ).status_code
        == 200
    )
    assert (
        api.client.get(
            path,
            params={"mode": "home", "measure_id": measure_id},
            headers=other_account,
        ).status_code
        == 404
    )


def test_recipe_display_composes_serving_and_mold_conversion(api: Api) -> None:
    headers = bearer(api.login("recipe-display-conversion@example.com"))
    body = recipe_input("显示换算组合")
    body["snapshot"].update(
        {
            "servings": 2,
            "base_mold": {"shape": "round", "unit": "in", "diameter": 6},
            "ingredients": [
                {
                    "id": "display-ingredient",
                    "display_name": "面粉",
                    "quantity": 100,
                    "unit": "g",
                    "base_quantity": 100,
                    "base_unit": "g",
                    "scaling_mode": "proportional",
                }
            ],
            "steps": [],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    path = f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}/display"

    serving = api.client.get(
        path,
        params={"mode": "base", "target_servings": 4},
        headers=headers,
    )
    assert serving.status_code == 200, serving.text
    serving_item = serving.json()["display"]["ingredients"][0]
    assert serving_item["converted_quantity"] == 200
    assert serving_item["conversion_rule"] == "proportional"
    assert serving_item["display_quantity"] == 200
    assert serving_item["source"]["source_type"] == "scenario_adjusted"
    assert serving_item["source"]["original_value"] == "100 g"
    serving_conversion = api.client.get(
        f"/v1/recipes/{saved['id']}/servings",
        params={"target_servings": 4},
        headers=headers,
    )
    assert serving_conversion.status_code == 200, serving_conversion.text
    assert (
        serving_item["display_quantity"]
        == serving_conversion.json()["conversion"]["ingredients"][0]["display_quantity"]
    )

    mold = api.client.get(
        path,
        params={
            "mode": "base",
            "target_mold": json.dumps(
                {"shape": "round", "unit": "in", "diameter": 8},
                separators=(",", ":"),
            ),
        },
        headers=headers,
    )
    assert mold.status_code == 200, mold.text
    mold_item = mold.json()["display"]["ingredients"][0]
    assert mold_item["converted_quantity"] == 177.78
    assert mold_item["conversion_rule"] == "mold_ratio"
    assert mold_item["display_quantity"] == 177.78
    assert mold_item["source"]["source_type"] == "scenario_adjusted"
    assert mold_item["source"]["original_value"] == "100 g"
    mold_conversion = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "in", "diameter": 8}},
        headers=headers,
    )
    assert mold_conversion.status_code == 200, mold_conversion.text
    assert (
        mold_item["display_quantity"]
        == mold_conversion.json()["conversion"]["ingredients"][0]["display_quantity"]
    )

    standard_no_density = api.client.get(
        path,
        params={"mode": "standard", "target_servings": 4},
        headers=headers,
    )
    assert standard_no_density.status_code == 200, standard_no_density.text
    standard_source = standard_no_density.json()["display"]["ingredients"][0]["source"]
    assert standard_source["basis"]["reason_code"] == "serving_conversion"
    assert "原方" in standard_source["basis"]["text"]
    assert "缺少密度数据" in standard_source["basis"]["text"]

    empty_optional = api.client.get(
        path,
        params={"mode": "base", "measure_id": "", "target_mold": ""},
        headers=headers,
    )
    assert empty_optional.status_code == 200, empty_optional.text
