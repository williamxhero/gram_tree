"""Shared golden rules and cache inputs exercised through the HTTP contract."""

import json
from pathlib import Path
from typing import Any

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import configure
from tests.test_allergies import consent
from tests.test_family_members import family_api, member_body  # noqa: F401
from tests.test_recipes import recipe_input

_CASES = Path(__file__).parents[2] / "app" / "assets" / "personalization_cases.json"
_RULE_CASES = json.loads(_CASES.read_text(encoding="utf-8"))["cases"]


@pytest.mark.parametrize("case", _RULE_CASES, ids=lambda case: case["name"])
def test_shared_personalization_cases(api: Api, case: dict[str, Any]) -> None:
    headers = bearer(api.login("shared-personalization@example.com"))
    configure("recipe.personalization_adjustment_limit", case.get("adjustment_limit", 0.3))
    body = recipe_input("共享规则验收")
    body["snapshot"].update(
        servings=case["original_servings"],
        ingredients=[_ingredient(item) for item in case["ingredients"]],
        steps=[{"id": "prepare", "instruction": "按原版步骤制作"}],
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    recipe_id = saved["id"]
    profile = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": case["flavors"]}
    )
    assert profile.status_code == 200, profile.text
    original_before = api.client.post(
        f"/v1/recipes/{recipe_id}/personalized",
        params={"view": "original"},
        headers=headers,
        json={},
    )
    assert original_before.status_code == 200, original_before.text
    assert original_before.json()["snapshot"] == saved["version"]["snapshot"]
    response = api.client.post(
        f"/v1/recipes/{recipe_id}/personalized",
        headers=headers,
        json={"target_servings": case["target_servings"]},
    )
    assert response.status_code == 200, response.text
    result = response.json()
    rows = {item["id"]: item for item in result["ingredients"]}
    quantities = {item["id"]: item["quantity"] for item in result["snapshot"]["ingredients"]}
    for item in case["ingredients"]:
        row = rows[item["id"]]
        assert row["display_quantity"] == item["expected"]
        assert quantities[item["id"]] == item["expected"]
        assert row["original_quantity"] == item["quantity"]
        assert row["original_name"] == item["display_name"]
        assert row["original_unit"] == row["display_unit"] == item["unit"]
        if "expected_rule" in item:
            assert row["rule"] == item["expected_rule"]
        if item["functional"]:
            assert "功能性用料保护" in row["reason"]
    assert result["snapshot"]["servings"] == case["target_servings"]
    assert result["snapshot_unchanged"] is True
    after = api.client.get(f"/v1/recipes/{recipe_id}", headers=headers)
    assert after.status_code == 200, after.text
    assert after.json()["version"] == saved["version"]
    assert after.json()["author"] == saved["author"]
    original_after = api.client.post(
        f"/v1/recipes/{recipe_id}/personalized",
        params={"view": "original"},
        headers=headers,
        json={},
    )
    assert original_after.status_code == 200, original_after.text
    assert original_after.json()["snapshot"] == original_before.json()["snapshot"]
    assert all(not item["changed"] for item in original_after.json()["ingredients"])


def _ingredient(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": item["id"],
        "display_name": item["display_name"],
        "quantity": item["quantity"],
        "unit": item["unit"],
        "group": item.get("group"),
        "scaling_mode": item["scaling_mode"],
        "functional": item["functional"],
        "flavor_contribution": item["contribution"],
    }


@pytest.mark.usefixtures("family_api")
def test_cache_key_tracks_all_personalization_inputs(api: Api) -> None:
    headers = bearer(api.login("personalization-input-keys@example.com"))
    consent(api, headers)
    members = []
    family_path = "/v1/me/taste-profile/family-members"
    for name in ("甲", "乙"):
        state = api.client.get(family_path, headers=headers).json()
        response = api.client.post(
            family_path,
            headers=headers,
            json=member_body(
                state,
                nickname=name,
                age_band="adult",
                flavors={},
                allergies={"categories": [], "ingredient_ids": []},
            ),
        )
        assert response.status_code == 201, response.text
        members.append(response.json()["id"])
    body = recipe_input("缓存输入验收")
    body["snapshot"]["base_mold"] = {"shape": "round", "diameter": 10, "unit": "cm"}
    # Equipment differences affect the key even when no step requires adaptation.
    for step in body["snapshot"]["steps"]:
        step["cookware"] = None
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    saved = response.json()
    version_id = saved["version"]["id"]
    path = f"/v1/recipes/{saved['id']}/personalized"

    def project(inputs: dict[str, Any], *, view: str = "personalized") -> dict[str, Any]:
        response = api.client.post(path, params={"view": view}, headers=headers, json=inputs)
        assert response.status_code == 200, response.text
        return response.json()

    base_inputs = {"version_id": version_id, "equipment": [], "diner_member_ids": []}
    base = project(base_inputs)
    assert project(base_inputs)["cache_key"] == base["cache_key"]
    variants = [
        {"target_servings": 3},
        {"target_mold": {"shape": "round", "diameter": 12, "unit": "cm"}},
        {"equipment": ["蒸锅"]},
        {"equipment": ["蒸锅", "烤箱"]},
        {"diner_member_ids": [members[0]]},
        {"diner_member_ids": members},
        {"diner_member_ids": members, "primary_diner_id": members[0]},
        {"diner_member_ids": members, "primary_diner_id": members[1]},
    ]
    keys = [base["cache_key"]]
    for variant in variants:
        keys.append(project({**base_inputs, **variant})["cache_key"])
    assert len(set(keys)) == len(keys)
    assert project(base_inputs, view="original")["cache_key"] not in keys
    ordered = project({**base_inputs, "equipment": ["蒸锅", "烤箱"], "diner_member_ids": members})
    reordered = project(
        {**base_inputs, "equipment": ["烤箱", "蒸锅"], "diner_member_ids": list(reversed(members))}
    )
    assert ordered["cache_key"] == reordered["cache_key"]

    edited = {"snapshot": saved["version"]["snapshot"], "change_note": "新的不可变版本"}
    response = api.client.post(f"/v1/recipes/{saved['id']}/versions", headers=headers, json=edited)
    assert response.status_code == 201, response.text
    next_version = response.json()["version"]["id"]
    assert next_version != version_id
    assert project({**base_inputs, "version_id": next_version})["cache_key"] != base["cache_key"]
    assert project(base_inputs)["cache_key"] == base["cache_key"]

    response = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 0.8}}
    )
    assert response.status_code == 200, response.text
    changed = project(base_inputs)
    assert changed["profile_version"] != base["profile_version"]
    assert changed["cache_key"] != base["cache_key"]
