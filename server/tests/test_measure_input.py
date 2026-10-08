"""Personal measure authoring through HTTP; versions retain confirmed conversion evidence."""

import json
import secrets
from copy import deepcopy
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from gramtree.main import create_app
from tests.accounts_support import Api, bearer
from tests.conftest import make_settings
from tests.test_conventions import assert_error_shape
from tests.test_recipes import recipe_input


def test_measure_input_preview_confirm_save_and_recalibration(api: Api) -> None:
    headers = bearer(api.login("measure-input@example.com"))
    measure_response = api.client.post(
        "/v1/me/measures",
        json={"name": "白瓷勺", "kind": "spoon", "capacity_ml": 12},
        headers=headers,
    )
    assert measure_response.status_code == 201, measure_response.text
    measure_id = measure_response.json()["id"]
    preview = api.client.post(
        "/v1/me/measures/input",
        json={"measure_id": measure_id, "quantity": 2, "base_unit": "ml"},
        headers=headers,
    )
    assert preview.status_code == 200, preview.text
    confirmed = preview.json()
    assert confirmed["base_quantity"] == 24
    assert confirmed["quantity_source"]["original"] == "2 白瓷勺"
    assert "12" in confirmed["quantity_source"]["basis"]
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []

    body = recipe_input("个人量具输入")
    body["snapshot"]["ingredients"] = [
        {
            "id": "water",
            "display_name": "水",
            "quantity": 24,
            "unit": "ml",
            "measure_input_token": confirmed["measure_input_token"],
        }
    ]
    body["snapshot"]["steps"] = []
    saved_response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()
    original_item = saved["version"]["snapshot"]["ingredients"][0]
    assert original_item["base_quantity"] == 24
    assert original_item["quantity_source"] == confirmed["quantity_source"]
    path = f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}"
    scaled = api.client.get(path + "/servings", params={"target_servings": 4}, headers=headers)
    assert scaled.status_code == 200, scaled.text
    assert scaled.json()["conversion"]["ingredients"][0]["display_quantity"] == 48

    assert (
        api.client.patch(
            f"/v1/me/measures/{measure_id}", json={"capacity_ml": 24}, headers=headers
        ).status_code
        == 200
    )
    display = api.client.get(
        path + "/display", params={"mode": "home", "measure_id": measure_id}, headers=headers
    )
    assert display.status_code == 200, display.text
    assert display.json()["display"]["ingredients"][0]["text"] == "约 1 白瓷勺（24 毫升）"
    assert api.client.delete(f"/v1/me/measures/{measure_id}", headers=headers).status_code == 204
    reopened = api.client.get(path, headers=headers)
    assert reopened.status_code == 200, reopened.text
    assert reopened.json()["version"]["snapshot"]["ingredients"][0] == original_item
    # An account-owned confirmed draft can still be saved after its tool is removed.
    next_version = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        json={"snapshot": saved["version"]["snapshot"], "change_note": "删除量具后继续编辑"},
        headers=headers,
    )
    assert next_version.status_code == 201, next_version.text
    assert next_version.json()["version"]["snapshot"]["ingredients"][0] == original_item


@pytest.mark.parametrize("quantity", [-1, "NaN", "Infinity", 10_000_001, 1_000_000])
def test_invalid_measure_input_cannot_change_recipe(api: Api, quantity: object) -> None:
    headers = bearer(api.login("measure-invalid@example.com"))
    measure = api.client.post(
        "/v1/me/measures", headers=headers, json={"name": "碗", "kind": "bowl", "capacity_ml": 300}
    ).json()
    result = api.client.post(
        "/v1/me/measures/input",
        headers=headers,
        json={"measure_id": measure["id"], "quantity": quantity, "base_unit": "ml"},
    )
    assert_error_shape(result, 422, "invalid_request")


def test_missing_density_zero_and_cross_account_boundaries(api: Api) -> None:
    owner = bearer(api.login("measure-boundary-owner@example.com"))
    other = bearer(api.login("measure-boundary-other@example.com"))
    measure = api.client.post(
        "/v1/me/measures", headers=owner, json={"name": "量杯", "kind": "cup", "capacity_ml": 200}
    ).json()
    request = {"measure_id": measure["id"], "quantity": 0, "base_unit": "g"}
    missing = api.client.post("/v1/me/measures/input", headers=owner, json=request)
    assert missing.status_code == 200, missing.text
    assert missing.json()["status"] == "no_density"
    assert missing.json()["measure_input_token"] is None
    assert "缺少密度" in missing.json()["basis"]
    assert_error_shape(
        api.client.post("/v1/me/measures/input", headers=other, json=request), 404, "not_found"
    )
    request["base_unit"] = "ml"
    zero = api.client.post("/v1/me/measures/input", headers=owner, json=request).json()
    assert zero["base_quantity"] == 0
    body = recipe_input("零用量")
    body["snapshot"]["ingredients"] = [
        {
            "id": "optional",
            "display_name": "水",
            "quantity": 0,
            "unit": "ml",
            "measure_input_token": zero["measure_input_token"],
        }
    ]
    body["snapshot"]["steps"] = []
    assert_error_shape(
        api.client.post("/v1/recipes", headers=other, json=body), 422, "invalid_measure_input"
    )
    saved = api.client.post("/v1/recipes", headers=owner, json=body)
    assert saved.status_code == 201, saved.text
    body["snapshot"]["ingredients"][0]["quantity"] = 1
    assert_error_shape(
        api.client.post("/v1/recipes", headers=owner, json=body), 422, "invalid_measure_input"
    )
    assert api.client.delete(f"/v1/me/measures/{measure['id']}", headers=owner).status_code == 204
    assert_error_shape(
        api.client.post("/v1/me/measures/input", headers=owner, json=request), 404, "not_found"
    )


DENSITY_ID = "00000000-0000-4000-8000-000000000099"


def _density_fixture(path: Path, density: float, status: str, version: str) -> None:
    (path / "manifest.json").write_text(
        json.dumps({"version": version, "changelog": "measure input"}), encoding="utf-8"
    )
    (path / "ingredients.json").write_text(
        json.dumps(
            [
                {
                    "id": DENSITY_ID,
                    "standard_name": "量具测试油",
                    "aliases": [],
                    "pinyin": "liangjuceshiyou",
                    "pinyin_initials": "ljcsy",
                    "category": "调料",
                    "attributes": {
                        "density": {"value": density, "source": "容量实测", "status": status},
                        "nutrition": {
                            "value": {
                                "energy_kcal": 100,
                                "protein_g": 20,
                                "fat_g": 4,
                                "carbohydrate_g": 10,
                                "sodium_mg": 50,
                            },
                            "source": "营养实测",
                            "status": "verified",
                        },
                    },
                }
            ]
        ),
        encoding="utf-8",
    )
    assert cli(["ingredients", "import", str(path)]) == 0


def test_density_estimate_confirmation_and_frozen_library_provenance(
    api: Api, tmp_path: Path
) -> None:
    _density_fixture(tmp_path, 0.9, "ai_draft", "1.0.0")
    headers = bearer(api.login("measure-density@example.com"))
    measure = api.client.post(
        "/v1/me/measures",
        headers=headers,
        json={"name": "油勺", "kind": "spoon", "capacity_ml": 10},
    ).json()
    request = {
        "measure_id": measure["id"],
        "ingredient_id": DENSITY_ID,
        "quantity": 2,
        "base_unit": "g",
    }
    response = api.client.post("/v1/me/measures/input", headers=headers, json=request)
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "estimate_confirmation_required"
    assert response.json()["base_quantity"] == 18
    assert response.json()["measure_input_token"] is None
    request["accept_estimate"] = True
    confirmed = api.client.post("/v1/me/measures/input", headers=headers, json=request).json()
    assert confirmed["quantity_source"]["source"] == "ai_estimated"
    assert "0.9" in confirmed["basis"] and "1.0.0" in confirmed["basis"]
    body = recipe_input("量具油")
    body["snapshot"]["base_mold"] = {"shape": "round", "unit": "in", "diameter": 6}
    body["snapshot"]["ingredients"] = [
        {
            "id": "oil",
            "ingredient_id": DENSITY_ID,
            "display_name": "油",
            "quantity": 18,
            "unit": "g",
            "measure_input_token": confirmed["measure_input_token"],
        }
    ]
    body["snapshot"]["steps"] = []
    saved_response = api.client.post("/v1/recipes", headers=headers, json=body)
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()
    _density_fixture(tmp_path, 1.2, "verified", "1.1.0")
    read = api.client.get(
        f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}", headers=headers
    ).json()
    assert read["version"]["snapshot"] == saved["version"]["snapshot"]
    request["accept_estimate"] = False
    fresh = api.client.post("/v1/me/measures/input", headers=headers, json=request).json()
    assert fresh["status"] == "ready" and fresh["base_quantity"] == 24
    # The same numeric base-unit recipe is indistinguishable to serving conversion.
    body["snapshot"]["ingredients"][0].pop("measure_input_token")
    base = api.client.post("/v1/recipes", headers=headers, json=body).json()
    outputs = []
    for recipe in [saved, base]:
        nutrition = recipe["version"]["derived"]["nutrition_per_serving"]
        assert nutrition["energy_kcal"] == 9
        assert nutrition["incomplete"] is False
        mold = api.client.post(
            f"/v1/recipes/{recipe['id']}/mold",
            headers=headers,
            json={"target_mold": {"shape": "round", "unit": "in", "diameter": 12}},
        )
        assert mold.status_code == 200, mold.text
        assert mold.json()["conversion"]["ingredients"][0]["display_quantity"] == 72
        scaled = api.client.get(
            f"/v1/recipes/{recipe['id']}/servings", params={"target_servings": 4}, headers=headers
        )
        assert scaled.status_code == 200, scaled.text
        outputs.append(scaled.json()["conversion"]["ingredients"][0]["display_quantity"])
    assert outputs == [36, 36]


def test_owned_editing_baseline_survives_key_rotation_without_trusting_swapped_input(
    api: Api,
) -> None:
    email = "measure-rotation@example.com"
    headers = bearer(api.login(email))
    other = bearer(api.login("measure-rotation-other@example.com"))
    tool = api.client.post(
        "/v1/me/measures",
        headers=headers,
        json={"name": "旧勺", "kind": "spoon", "capacity_ml": 12},
    ).json()
    preview = api.client.post(
        "/v1/me/measures/input",
        headers=headers,
        json={"measure_id": tool["id"], "quantity": 2, "base_unit": "ml"},
    ).json()
    body = recipe_input("轮换后继续编辑")
    body["snapshot"]["ingredients"] = [
        {
            "id": "water",
            "display_name": "水",
            "quantity": 24,
            "unit": "ml",
            "measure_input_token": preview["measure_input_token"],
        }
    ]
    body["snapshot"]["steps"] = []
    first_response = api.client.post("/v1/recipes", headers=headers, json=body)
    assert first_response.status_code == 201, first_response.text
    first = first_response.json()
    foreign_response = api.client.post("/v1/recipes", headers=other, json=recipe_input("其他作者"))
    assert foreign_response.status_code == 201, foreign_response.text
    foreign = foreign_response.json()
    # Another genuine old receipt must not be accepted merely because it existed
    # somewhere in the account's history: only the requested baseline is trusted.
    second_preview = api.client.post(
        "/v1/me/measures/input",
        headers=headers,
        json={"measure_id": tool["id"], "quantity": 4, "base_unit": "ml"},
    ).json()
    second_body = deepcopy(body)
    second_body["snapshot"]["ingredients"][0].update(
        quantity=48,
        measure_input_token=second_preview["measure_input_token"],
    )
    second_response = api.client.post(
        f"/v1/recipes/{first['id']}/versions",
        headers=headers,
        json=second_body,
    )
    assert second_response.status_code == 201, second_response.text
    second = second_response.json()
    assert api.client.delete(f"/v1/me/measures/{tool['id']}", headers=headers).status_code == 204

    # Rotate through the public application configuration, then log in normally
    # because authentication credentials also change with the configured secret.
    with TestClient(create_app(make_settings(auth_secret=secrets.token_urlsafe(48)))) as client:
        rotated = Api(client, api.clock, api.apple)
        client.app.state.clock = api.clock  # type: ignore[attr-defined]
        current_headers = bearer(rotated.login(email))
        draft = {
            "recipe_id": first["id"],
            "base_version_id": first["version"]["id"],
            "snapshot": first["version"]["snapshot"],
        }
        checked = client.post("/v1/recipes/safety/check", headers=current_headers, json=draft)
        assert checked.status_code == 200, checked.text
        for field, value in [
            ("quantity", 25),
            ("unit", "g"),
            ("base_quantity", 25),
            ("base_unit", "g"),
            ("id", "another-row"),
            ("quantity_source", {"source": "author_filled", "basis": "伪造依据"}),
            ("measure_input_token", second_preview["measure_input_token"]),
        ]:
            forged = deepcopy(draft)
            forged["snapshot"]["ingredients"][0][field] = value
            assert_error_shape(
                client.post("/v1/recipes/safety/check", headers=current_headers, json=forged),
                422,
                "invalid_measure_input",
            )
            forged.pop("recipe_id")
            assert_error_shape(
                client.post(
                    f"/v1/recipes/{first['id']}/versions", headers=current_headers, json=forged
                ),
                422,
                "invalid_measure_input",
            )
        swapped = deepcopy(draft)
        swapped["snapshot"] = second["version"]["snapshot"]
        assert_error_shape(
            client.post("/v1/recipes/safety/check", headers=current_headers, json=swapped),
            422,
            "invalid_measure_input",
        )
        for context in [
            {"recipe_id": foreign["id"], "base_version_id": foreign["version"]["id"]},
            {"recipe_id": first["id"], "base_version_id": foreign["version"]["id"]},
        ]:
            assert_error_shape(
                client.post(
                    "/v1/recipes/safety/check", headers=current_headers, json={**draft, **context}
                ),
                404,
                "not_found",
            )
        assert_error_shape(
            client.post(
                f"/v1/recipes/{first['id']}/versions",
                headers=current_headers,
                json={"snapshot": draft["snapshot"], "base_version_id": foreign["version"]["id"]},
            ),
            404,
            "not_found",
        )
        saved = client.post(
            f"/v1/recipes/{first['id']}/versions",
            headers=current_headers,
            json={
                "snapshot": draft["snapshot"],
                "base_version_id": first["version"]["id"],
                "change_note": "沿用已确认的旧依据",
            },
        )
        assert saved.status_code == 201, saved.text
        assert (
            saved.json()["version"]["snapshot"]["ingredients"] == draft["snapshot"]["ingredients"]
        )
