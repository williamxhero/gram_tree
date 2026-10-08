"""Recipe-level flavor and functional choices through public HTTP/CLI seams."""

from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ingredients_attributes import _import, _record, _write
from tests.test_recipes import recipe_input

STANDARD_ID = "00000000-0000-4000-8000-000000000137"


@pytest.mark.parametrize("cleared_profile", [None, {}, {"salty": None, "umami": None}])
def test_library_flavor_is_adopted_and_saved_as_recipe_data(
    api: Api, tmp_path: Path, cleared_profile: dict | None
) -> None:
    _write(
        tmp_path,
        "137.1.0",
        [
            _record(
                STANDARD_ID,
                "测试生抽",
                "ceshishengchou",
                {
                    "flavor": {
                        "value": {"salty": 3, "umami": 2},
                        "source": "AI 起草、待核对",
                        "status": "ai_draft",
                    },
                    "functional": {"value": True, "source": "人工整理", "status": "verified"},
                },
            )
        ],
    )
    assert _import(tmp_path) == 0
    body = recipe_input("味型贡献")
    item = body["snapshot"]["ingredients"][0]
    item.update(ingredient_id=STANDARD_ID, display_name="我的生抽", quantity=15, unit="ml")
    item.pop("functional")
    headers = bearer(api.login("flavor@example.com"))
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    saved = response.json()
    ingredient = saved["version"]["snapshot"]["ingredients"][0]
    assert ingredient["flavor_contribution"] == {
        "salty": 3,
        "sweet": 0,
        "sour": 0,
        "spicy": 0,
        "umami": 2,
        "numbing": 0,
        "oily": 0,
    }
    assert ingredient["flavor_source"]["source"] == "ai_estimated"
    assert "137.1.0" in ingredient["flavor_source"]["basis"]
    assert ingredient["functional"] is True
    assert ingredient["functional_source"]["source"] == "author_filled"
    assert "不是做菜验证" in ingredient["functional_source"]["basis"]
    assert ingredient["display_name"] == "我的生抽"
    assert ingredient["base_quantity"] == 15
    assert ingredient["base_unit"] == "ml"
    assert ingredient["group"] == "主料"
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved

    # Library corrections cannot alter history or an old client's baseline save.
    _write(
        tmp_path,
        "137.2.0",
        [
            _record(
                STANDARD_ID,
                "测试生抽",
                "ceshishengchou",
                {
                    "flavor": {"value": {"salty": 1}, "source": "人工整理", "status": "verified"},
                    "functional": {"value": False, "source": "人工整理", "status": "verified"},
                },
            )
        ],
    )
    assert _import(tmp_path) == 0
    old_client = recipe_input("味型贡献")
    old_client["snapshot"]["ingredients"][0].update(
        ingredient_id=STANDARD_ID,
        display_name="我的生抽",
        quantity=15,
        unit="ml",
        functional=True,
    )
    edited = api.client.post(
        f"/v1/recipes/{saved['id']}/versions", json=old_client, headers=headers
    )
    assert edited.status_code == 201, edited.text
    assert edited.json()["version"]["snapshot"]["ingredients"][0] == ingredient
    historical = api.client.get(
        f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}",
        headers=headers,
    )
    assert historical.json()["version"] == saved["version"]
    override = recipe_input("味型贡献")
    override["snapshot"]["ingredients"][0].update(
        ingredient_id=STANDARD_ID,
        flavor_contribution={"salty": 0, "umami": 3},
        functional=False,
    )
    overridden = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        json=override,
        headers=headers,
    )
    assert overridden.status_code == 201, overridden.text
    chosen = overridden.json()["version"]["snapshot"]["ingredients"][0]
    assert chosen["flavor_contribution"]["salty"] == 0
    assert chosen["flavor_contribution"]["umami"] == 3
    assert chosen["flavor_source"]["source"] == "author_filled"
    assert chosen["functional"] is False
    override["snapshot"]["ingredients"][0]["flavor_contribution"] = cleared_profile
    cleared = api.client.post(f"/v1/recipes/{saved['id']}/versions", json=override, headers=headers)
    assert cleared.status_code == 201, cleared.text
    cleared_item = cleared.json()["version"]["snapshot"]["ingredients"][0]
    assert cleared_item["flavor_contribution"] is None
    assert cleared_item["flavor_source"] is None
    comparison = api.client.get(
        f"/v1/recipes/{saved['id']}/compare",
        params={
            "from_version_id": overridden.json()["version"]["id"],
            "to_version_id": cleared.json()["version"]["id"],
        },
        headers=headers,
    )
    assert comparison.status_code == 200, comparison.text
    flavor_changes = [
        change
        for change in comparison.json()["ingredients"][0]["changes"]
        if change["field"] == "flavor_contribution"
    ]
    assert len(flavor_changes) == 1
    assert flavor_changes[0]["before"]["salty"] == 0
    assert flavor_changes[0]["after"] is None
    # Editing an older version uses that baseline, not the current version.
    old_client["base_version_id"] = saved["version"]["id"]
    from_old = api.client.post(
        f"/v1/recipes/{saved['id']}/versions", json=old_client, headers=headers
    )
    assert from_old.status_code == 201, from_old.text
    assert from_old.json()["version"]["snapshot"]["ingredients"][0] == ingredient


@pytest.mark.parametrize(
    "contribution",
    [
        None,
        {},
        {"salty": 0},
        {"salty": 3, "umami": 2},
        {
            "salty": 1,
            "sweet": 2,
            "sour": 3,
            "spicy": 0,
            "umami": 1,
            "numbing": 2,
            "oily": 3,
        },
    ],
)
def test_author_contribution_unknown_zero_and_false_survive_versions(
    api: Api,
    contribution: dict | None,
) -> None:
    headers = bearer(api.login("author-contribution@example.com"))
    body = recipe_input("作者味型")
    body["snapshot"]["ingredients"][0].update(
        flavor_contribution=contribution,
        functional=False,
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    item = saved["version"]["snapshot"]["ingredients"][0]
    if contribution is None or not contribution:
        assert item["flavor_contribution"] is None
        assert item["flavor_source"] is None
    else:
        for axis in ("salty", "sweet", "sour", "spicy", "umami", "numbing", "oily"):
            assert item["flavor_contribution"][axis] == contribution.get(axis)
        assert item["flavor_source"]["source"] == "author_filled"
    assert item["functional"] is False
    changed = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        json={
            "base_version_id": saved["version"]["id"],
            "snapshot": saved["version"]["snapshot"],
        },
        headers=headers,
    )
    assert changed.status_code == 201, changed.text
    assert changed.json()["version"]["snapshot"]["ingredients"][0] == item
    other = bearer(api.login("flavor-other@example.com"))
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=other).status_code == 404
    assert (
        api.client.post(f"/v1/recipes/{saved['id']}/versions", json=body, headers=other).status_code
        == 404
    )


@pytest.mark.parametrize("unknown", [{}, {"salty": None, "umami": None}])
def test_unchanged_unknown_profile_has_no_author_source_or_comparison_change(
    api: Api, unknown: dict
) -> None:
    headers = bearer(api.login("unknown-profile@example.com"))
    body = recipe_input("未知贡献")
    body["snapshot"]["ingredients"][0]["flavor_contribution"] = None
    created = api.client.post("/v1/recipes", json=body, headers=headers).json()
    snapshot = created["version"]["snapshot"]
    item = snapshot["ingredients"][0]
    item["flavor_contribution"] = unknown
    item.pop("flavor_source")  # Generated clients omit null properties.
    saved_response = api.client.post(
        f"/v1/recipes/{created['id']}/versions",
        json={"base_version_id": created["version"]["id"], "snapshot": snapshot},
        headers=headers,
    )
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()
    assert saved["version"]["snapshot"]["ingredients"][0]["flavor_contribution"] is None
    assert saved["version"]["snapshot"]["ingredients"][0]["flavor_source"] is None
    comparison = api.client.get(
        f"/v1/recipes/{created['id']}/compare",
        params={
            "from_version_id": created["version"]["id"],
            "to_version_id": saved["version"]["id"],
        },
        headers=headers,
    )
    assert comparison.status_code == 200, comparison.text
    assert comparison.json()["ingredients"][0]["changes"] == []


@pytest.mark.parametrize("axis", ["salty", "sweet", "sour", "spicy", "umami", "numbing", "oily"])
@pytest.mark.parametrize("invalid", [-1, 4, 1.5, True, "2"])
def test_recipe_flavor_rejects_illegal_strength(api: Api, axis: str, invalid: object) -> None:
    headers = bearer(api.login("invalid-flavor@example.com"))
    body = recipe_input()
    body["snapshot"]["ingredients"][0]["flavor_contribution"] = {axis: invalid}
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 422, response.text


@pytest.mark.parametrize("field", ["flavor_source", "functional_source"])
def test_author_cannot_claim_recipe_contribution_has_been_verified(api: Api, field: str) -> None:
    headers = bearer(api.login("unverified-flavor@example.com"))
    body = recipe_input()
    body["snapshot"]["ingredients"][0].update(
        flavor_contribution={"salty": 3},
        **{field: {"source": "verified"}},
    )
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 422, response.text
