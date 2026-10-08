"""Household cooking constraints through authenticated HTTP and real PostgreSQL."""

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input

PATH = "/v1/me/taste-profile/cooking-constraints"
PROFILE = "/v1/me/taste-profile"


def test_constraints_persist_clear_and_share_profile_history(api: Api) -> None:
    owner = bearer(api.login("constraints-owner@example.com"))
    initial = api.client.get(PATH, headers=owner)
    assert initial.status_code == 200, initial.text
    before = initial.json()
    assert before["constraints"] == {
        "household_servings": None, "equipment": [], "meal_times": [], "meal_templates": []
    }
    assert {item["id"] for item in before["equipment_vocabulary"]} >= {"wok", "oven", "air_fryer", "rice_cooker"}
    values = {
        "household_servings": 4,
        "equipment": ["wok", "rice_cooker"],
        "meal_times": [{"day_type": "weekday", "meal": "dinner", "minutes": 30}],
        "meal_templates": [{"day_type": "weekday", "meal": "dinner", "dish_count": 3,
                            "composition": ["meat", "vegetable", "soup"]}],
    }
    saved = api.client.put(PATH, headers=owner, json=values)
    assert saved.status_code == 200, saved.text
    current = saved.json()
    assert current["constraints"] == values
    assert current["profile_version"] == before["profile_version"] + 1
    assert api.client.get(PATH, headers=owner).json() == current
    assert api.client.get(PROFILE, headers=owner).json()["version"] == current["profile_version"]
    changes = api.client.get(PROFILE + "/changes", headers=owner).json()["items"]
    assert len(changes) == 1
    assert changes[0]["field"] == "cooking_constraints"
    assert changes[0]["old_value"] == before["constraints"]
    assert changes[0]["new_value"] == values
    assert changes[0]["reason"] == "你手动修改"
    assert changes[0]["source"] == "manual"
    assert api.client.put(PATH, headers=owner, json=values).json()["profile_version"] == current["profile_version"]
    cleared = api.client.put(PATH, headers=owner, json={})
    assert cleared.status_code == 200, cleared.text
    assert cleared.json()["constraints"] == before["constraints"]
    assert cleared.json()["profile_version"] == current["profile_version"] + 1
    assert api.client.get(PATH, headers=owner).json() == cleared.json()
    other = bearer(api.login("constraints-other@example.com", device="other"))
    assert api.client.get(PATH, headers=other).json()["constraints"] == before["constraints"]
    assert api.client.get(PATH).status_code == 401
    assert api.client.put(PATH, json=values).status_code == 401


def test_invalid_constraints_never_partially_update(api: Api) -> None:
    owner = bearer(api.login("constraints-validation@example.com"))
    before = api.client.get(PATH, headers=owner).json()
    for invalid in (
        {"household_servings": 0}, {"household_servings": 21},
        {"household_servings": True}, {"household_servings": "4"},
        {"household_servings": 4, "equipment": ["unregistered"]},
        {"equipment": ["wok", "wok"]},
        {"meal_times": [{"day_type": "weekday", "meal": "dinner", "minutes": 0}]},
        {"meal_times": [{"day_type": "weekday", "meal": "dinner", "minutes": 1441}]},
        {"meal_times": [{"day_type": "weekday", "meal": "dinner", "minutes": 20}] * 2},
        {"meal_templates": [{"day_type": "weekend", "meal": "lunch", "dish_count": 2, "composition": ["soup"]}]},
        {"meal_templates": [{"day_type": "weekday", "meal": "dinner", "dish_count": 1, "composition": ["bad"]}]},
        {"equipment": None}, {"owner_id": before["profile_version"]},
    ):
        response = api.client.put(PATH, headers=owner, json=invalid)
        assert response.status_code == 422, response.text
        assert api.client.get(PATH, headers=owner).json() == before
        assert api.client.get(PROFILE + "/changes", headers=owner).json()["items"] == []


def test_household_default_is_metadata_not_a_recipe_snapshot_change(api: Api) -> None:
    owner = bearer(api.login("household-recipe@example.com"))
    body = recipe_input("家庭默认份数")
    body["snapshot"]["steps"][0]["cookware"] = "祖传小炒锅（自由文本）"
    created = api.client.post("/v1/recipes", json=body, headers=owner)
    assert created.status_code == 201, created.text
    original = created.json()
    path = f"/v1/recipes/{original['id']}"
    assert original["default_servings"] is None
    assert api.client.put(PATH, headers=owner, json={"household_servings": 4}).status_code == 200
    changed = api.client.get(path, headers=owner).json()
    assert changed["default_servings"] == 4
    assert changed["taste_profile_version"] == api.client.get(PATH, headers=owner).json()["profile_version"]
    assert changed["version"] == original["version"]
    version_path = path + "/versions/" + original["version"]["id"]
    assert api.client.get(version_path, headers=owner).json()["version"] == original["version"]
    conversion = api.client.get(version_path + "/servings", params={"target_servings": 4}, headers=owner)
    assert conversion.status_code == 200, conversion.text
    assert conversion.json()["conversion"]["target_servings"] == 4
    measure = api.client.post("/v1/me/measures", headers=owner,
                             json={"name": "家用勺", "kind": "spoon", "capacity_ml": 10}).json()
    api.client.patch("/v1/me/measures/" + measure["id"], headers=owner, json={"capacity_ml": 15})
    assert api.client.get(path, headers=owner).json()["version"] == original["version"]
    assert api.client.put(PATH, headers=owner, json={}).status_code == 200
    assert api.client.get(path, headers=owner).json()["default_servings"] is None
    stranger = bearer(api.login("household-stranger@example.com", device="stranger"))
    assert api.client.get(path, headers=stranger).status_code == 404
