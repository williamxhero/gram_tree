"""SPEC-005.2 temporary personalization projection through HTTP."""

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input


def test_personalized_projection_scales_flavor_inputs_without_saving_version(api: Api) -> None:
    headers = bearer(api.login("personalization-rules@example.com"))
    body = recipe_input("口味换算")
    body["snapshot"]["ingredients"][0]["group"] = "主料"
    body["snapshot"]["ingredients"][1]["flavor_contribution"] = {"salty": 3}
    body["snapshot"]["ingredients"].append(
        {
            "id": "dough-sugar",
            "display_name": "发面糖",
            "quantity": 10,
            "unit": "g",
            "functional": True,
            "flavor_contribution": {"sweet": 3},
            "scaling_mode": "proportional",
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    recipe_id = saved["id"]
    version_id = saved["version"]["id"]

    changed_profile = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 0.5}}
    )
    assert changed_profile.status_code == 200, changed_profile.text
    before = api.client.get(f"/v1/recipes/{recipe_id}", headers=headers).json()

    response = api.client.post(
        f"/v1/recipes/{recipe_id}/personalized",
        headers=headers,
        json={"target_servings": 4},
    )
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["view"] == "personalized"
    assert result["version_id"] == version_id
    assert result["profile_version"] == changed_profile.json()["version"]
    assert result["snapshot_unchanged"] is True
    ingredients = {item["id"]: item for item in result["ingredients"]}
    assert ingredients["chicken"]["display_quantity"] == 600
    assert ingredients["chicken"]["rule"] == "servings"
    assert "份数换算" in ingredients["chicken"]["reason"]
    assert ingredients["pepper"]["display_quantity"] < 6
    assert ingredients["dough-sugar"]["display_quantity"] == 20
    assert "功能性用料保护" in next(
        item["reason"] for item in result["ingredients"] if item["id"] == "dough-sugar"
    )

    original = api.client.post(
        f"/v1/recipes/{recipe_id}/personalized?view=original",
        headers=headers,
        json={"target_servings": 4},
    )
    assert original.status_code == 200, original.text
    assert original.json()["view"] == "original"
    original_ingredients = {item["id"]: item for item in original.json()["ingredients"]}
    assert original_ingredients["chicken"]["display_quantity"] == 600
    author_ingredients = {item["id"]: item for item in before["version"]["snapshot"]["ingredients"]}
    assert (
        original_ingredients["chicken"]["original_name"]
        == author_ingredients["chicken"]["display_name"]
    )
    assert original.json()["snapshot_unchanged"] is True
    after = api.client.get(f"/v1/recipes/{recipe_id}", headers=headers).json()
    assert after["version"]["id"] == before["version"]["id"]
    assert after["version"]["snapshot"] == before["version"]["snapshot"]
    assert after["version"]["id"] == version_id


def test_personalization_cache_key_changes_with_profile_version(api: Api) -> None:
    headers = bearer(api.login("personalization-cache@example.com"))
    body = recipe_input("缓存键")
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    recipe_id = created.json()["id"]
    first = api.client.post(f"/v1/recipes/{recipe_id}/personalized", headers=headers, json={})
    assert first.status_code == 200, first.text
    profile = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 0.75}}
    )
    assert profile.status_code == 200, profile.text
    second = api.client.post(f"/v1/recipes/{recipe_id}/personalized", headers=headers, json={})
    assert second.status_code == 200, second.text
    assert second.json()["cache_key"] != first.json()["cache_key"]
    assert second.json()["profile_version"] != first.json()["profile_version"]
