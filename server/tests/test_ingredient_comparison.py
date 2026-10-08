"""Ingredient-only version comparison through HTTP with real PostgreSQL."""

import json
from copy import deepcopy
from pathlib import Path
from uuid import uuid4

import pytest

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer


def ingredient(id: str = "salt", name: str = "盐", quantity: float = 3, **fields) -> dict:
    return {
        "id": id,
        "display_name": name,
        "quantity": quantity,
        "unit": "g",
        "group": "调味",
        **fields,
    }


def create(
    api: Api, headers: dict, items: list[dict], servings: int = 2, name: str = "比较菜"
) -> dict:
    response = api.client.post(
        "/v1/recipes",
        headers=headers,
        json={
            "dish_name": name,
            "snapshot": {"servings": servings, "ingredients": items, "steps": []},
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def save(api: Api, headers: dict, first: dict, items: list[dict], servings: int = 2) -> dict:
    snapshot = deepcopy(first["version"]["snapshot"])
    snapshot.update(ingredients=items, servings=servings)
    response = api.client.post(
        f"/v1/recipes/{first['id']}/versions", headers=headers, json={"snapshot": snapshot}
    )
    assert response.status_code == 201, response.text
    return response.json()


def compare(api: Api, headers: dict, first: dict, second: dict):
    return api.client.get(
        f"/v1/recipes/{first['id']}/compare",
        headers=headers,
        params={
            "from_version_id": first["version"]["id"],
            "to_version_id": second["version"]["id"],
        },
    )


def test_same_dish_candidates_include_owned_roots_and_paginate_without_private_leaks(
    api: Api,
) -> None:
    headers = bearer(api.login("candidates@example.com"))
    first = create(api, headers, [ingredient()], name="候选菜")
    second = create(api, headers, [ingredient(quantity=2)], name="候选菜")
    unrelated = create(api, headers, [ingredient()], name="另一道菜")
    other = bearer(api.login("private-candidate@example.com"))
    foreign = create(api, other, [ingredient()], name="候选菜")
    assert first["dish"]["id"] == second["dish"]["id"] == foreign["dish"]["id"]
    path = f"/v1/recipes/{first['id']}/comparison-candidates"
    page = api.client.get(path, params={"limit": 1}, headers=headers)
    assert page.status_code == 200, page.text
    data = page.json()
    assert len(data["items"]) == 1
    assert data["next_cursor"] is not None
    next_page = api.client.get(
        path, params={"limit": 1, "cursor": data["next_cursor"]}, headers=headers
    )
    assert next_page.status_code == 200, next_page.text
    items = data["items"] + next_page.json()["items"]
    assert {item["id"] for item in items} == {first["version"]["id"], second["version"]["id"]}
    assert {item["recipe_id"] for item in items} == {first["id"], second["id"]}
    assert next_page.json()["next_cursor"] is None
    assert all(
        item["id"] not in {foreign["version"]["id"], unrelated["version"]["id"]} for item in items
    )
    assert compare(api, headers, first, second).status_code == 200
    missing = api.client.get(f"/v1/recipes/{uuid4()}/comparison-candidates", headers=headers)
    denied = api.client.get(f"/v1/recipes/{foreign['id']}/comparison-candidates", headers=headers)
    assert missing.status_code == denied.status_code == 404
    assert missing.json()["error"]["code"] == denied.json()["error"]["code"]
    assert missing.json()["error"]["message"] == denied.json()["error"]["message"]
    assert api.client.get(path, params={"cursor": "invalid"}, headers=headers).status_code == 422
    assert api.client.get(path, params={"limit": 100000}, headers=headers).status_code == 422


def test_preparation_evidence_alone_is_not_an_execution_change(api: Api) -> None:
    headers = bearer(api.login("preparation-evidence-compare@example.com"))
    first = create(
        api,
        headers,
        [ingredient(preparation="切块", preparation_source={"source": "author_filled"})],
    )
    second = create(
        api,
        headers,
        [
            ingredient(
                preparation="切块",
                preparation_source={"source": "ai_estimated", "basis": "原有切法的估算依据"},
            )
        ],
    )
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    row = response.json()["ingredients"][0]
    assert row["before"]["preparation_source"]["source"] == "author_filled"
    assert row["after"]["preparation_source"]["source"] == "ai_estimated"
    assert row["changes"] == []
    assert response.json()["snapshot_fields"] == []


@pytest.mark.parametrize(
    "unit_a,qty_a,unit_b,qty_b,attrs,expected",
    [
        ("g", 3, "kg", 0.003, {}, []),
        ("g", 100, "ml", 50, {"density": 2.0}, []),
        ("g", 100, "个", 2, {"count_units": [{"unit": "个", "grams": 50.0}]}, []),
        ("ml", 50, "个", 2, {"density": 2.0, "count_units": [{"unit": "个", "grams": 50.0}]}, []),
        ("g", 100, "个", 3, {"count_units": [{"unit": "个", "grams": 50.0}]}, ["quantity"]),
        ("g", 100, "ml", 100, {}, ["unit"]),
        (
            "个",
            2,
            "片",
            2,
            {"count_units": [{"unit": "个", "grams": 50.0}, {"unit": "片", "grams": 10.0}]},
            ["quantity"],
        ),
        ("个", 2, "片", 2, {}, ["unit"]),
    ],
)
def test_units_use_ingredient_specific_conversion(
    api: Api, tmp_path: Path, unit_a, qty_a, unit_b, qty_b, attrs, expected
) -> None:
    standard_id = str(uuid4())
    record = {
        "id": standard_id,
        "standard_name": "比较食材",
        "aliases": ["比较别名"],
        "pinyin": "bijiaoshicai",
        "pinyin_initials": "bjsc",
        "category": "调料",
        "attributes": {
            k: {"value": v, "source": "fixture", "status": "verified"} for k, v in attrs.items()
        },
    }
    (tmp_path / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "comparison"}), encoding="utf-8"
    )
    (tmp_path / "ingredients.json").write_text(json.dumps([record]), encoding="utf-8")
    assert cli(["ingredients", "import", str(tmp_path)]) == 0
    headers = bearer(api.login("unit-compare@example.com"))
    first = create(
        api,
        headers,
        [ingredient(name="比较食材", quantity=qty_a, unit=unit_a, ingredient_id=standard_id)],
    )
    second = save(
        api,
        headers,
        first,
        [ingredient(name="比较食材", quantity=qty_b, unit=unit_b, ingredient_id=standard_id)],
    )
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    changes = response.json()["ingredients"][0]["changes"]
    assert [c["kind"] for c in changes] == expected
    if expected == ["quantity"] and unit_a == "g":
        assert changes[0]["before"] == 100
        assert changes[0]["after"] == 150
        assert changes[0]["relative_change"] == 0.5
    if expected == ["unit"]:
        assert changes[0]["relative_change"] is None
    # Same library identity with an alias and independent row ID is text only.
    alias = create(
        api,
        headers,
        [
            ingredient(
                id="alias", name="比较别名", quantity=qty_a, unit=unit_a, ingredient_id=standard_id
            )
        ],
    )
    assert [
        c["kind"]
        for r in compare(api, headers, first, alias).json()["ingredients"]
        for c in r["changes"]
    ] == ["text"]


def test_standard_replacement_and_unrecorded_alias_pairing(api: Api, tmp_path: Path) -> None:
    ids = [str(uuid4()), str(uuid4())]
    records = [
        {
            "id": ids[0],
            "standard_name": "生抽",
            "aliases": ["酱油"],
            "pinyin": "shengchou",
            "pinyin_initials": "sc",
            "category": "调料",
        },
        {
            "id": ids[1],
            "standard_name": "糖",
            "aliases": [],
            "pinyin": "tang",
            "pinyin_initials": "t",
            "category": "调料",
        },
    ]
    (tmp_path / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "comparison"}), encoding="utf-8"
    )
    (tmp_path / "ingredients.json").write_text(json.dumps(records), encoding="utf-8")
    assert cli(["ingredients", "import", str(tmp_path)]) == 0
    headers = bearer(api.login("standard-compare@example.com"))
    first = create(api, headers, [ingredient(name="生抽", ingredient_id=ids[0])])
    replaced = save(api, headers, first, [ingredient(name="糖", ingredient_id=ids[1])])
    changes = compare(api, headers, first, replaced).json()["ingredients"][0]["changes"]
    assert [c["kind"] for c in changes] == ["replacement", "text"]
    alias = create(api, headers, [ingredient(id="unrecorded", name="酱油")])
    row = compare(api, headers, first, alias).json()["ingredients"][0]
    assert row["pairing"] == "identity_group"
    assert [c["kind"] for c in row["changes"]] == ["text"]
    # Identical local IDs in independent recipes must NOT override identity + group.
    independent = create(api, headers, [ingredient(name="糖", group="主料", ingredient_id=ids[1])])
    assert [
        c["kind"]
        for r in compare(api, headers, first, independent).json()["ingredients"]
        for c in r["changes"]
    ] == ["removed", "added"]


def test_snapshot_fields_and_permissions(api: Api) -> None:
    headers = bearer(api.login("scope-compare@example.com"))
    first = create(api, headers, [ingredient()])
    snapshot = deepcopy(first["version"]["snapshot"])
    snapshot.update(description="文字", difficulty="hard")
    second_response = api.client.post(
        f"/v1/recipes/{first['id']}/versions", headers=headers, json={"snapshot": snapshot}
    )
    assert second_response.status_code == 201
    second = second_response.json()
    result = compare(api, headers, first, second).json()
    assert [(c["field"], c["kind"]) for c in result["snapshot_fields"]] == [
        ("description", "text"),
        ("difficulty", "field"),
    ]
    other_headers = bearer(api.login("other-compare@example.com"))
    foreign = create(api, other_headers, [ingredient()])
    hidden = compare(api, headers, first, foreign)
    missing = deepcopy(foreign)
    missing["version"]["id"] = str(uuid4())
    nonexistent = compare(api, headers, first, missing)
    assert hidden.status_code == nonexistent.status_code == 404
    assert {k: v for k, v in hidden.json()["error"].items() if k != "request_id"} == {
        k: v for k, v in nonexistent.json()["error"].items() if k != "request_id"
    }
    assert compare(api, other_headers, first, second).status_code == 404
    assert (
        api.client.get(f"/v1/recipes/{first['id']}/versions", headers=other_headers).status_code
        == 404
    )
    other_dish = create(api, headers, [ingredient()], name="另一道菜")
    assert compare(api, headers, first, other_dish).status_code == 422


def test_quantity_comparison_is_directional_and_ingredient_only(api: Api) -> None:
    headers = bearer(api.login("compare@example.com"))
    first = create(api, headers, [ingredient()])
    second = save(api, headers, first, [ingredient(quantity=2)])
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["scope"] == "ingredients"
    assert result["normalized_servings"] == 2
    change = result["ingredients"][0]["changes"][0]
    assert change["kind"] == "quantity"
    assert change["before"] == 3
    assert change["after"] == 2
    assert abs(change["relative_change"] + 1 / 3) < 1e-10
    assert change["unit"] == "g"
    assert (
        api.client.get(
            f"/v1/recipes/{first['id']}/versions/{first['version']['id']}", headers=headers
        ).json()["version"]
        == first["version"]
    )
    reverse = compare(api, headers, second, first).json()["ingredients"][0]["changes"][0]
    assert reverse["relative_change"] == 0.5


@pytest.mark.parametrize(
    "before,after,independent,expected",
    [
        ([ingredient()], [ingredient(name="糖")], False, ["text"]),
        ([ingredient()], [ingredient(id="different")], True, []),
        ([ingredient(name="私房 盐")], [ingredient(id="different", name="私房盐")], True, ["text"]),
        ([ingredient()], [ingredient(id="sugar", name="糖")], True, ["replacement", "text"]),
        (
            [ingredient(), ingredient("pepper", "胡椒")],
            [ingredient("sugar", "糖"), ingredient("oil", "油")],
            True,
            ["removed", "removed", "added", "added"],
        ),
        (
            [ingredient("a"), ingredient("b", quantity=2)],
            [ingredient("c"), ingredient("d", quantity=2), ingredient("e")],
            True,
            ["added"],
        ),
        (
            [ingredient("a", group="主料"), ingredient("b", group="调味")],
            [ingredient("c", group="调味"), ingredient("d", group="主料")],
            True,
            [],
        ),
        ([ingredient()], [], False, ["removed"]),
        ([], [ingredient()], False, ["added"]),
        ([ingredient(quantity=0)], [ingredient(quantity=2)], False, ["quantity"]),
    ],
)
def test_pairing_is_stable_and_lossless(api: Api, before, after, independent, expected) -> None:
    headers = bearer(api.login("pair-compare@example.com"))
    first = create(api, headers, before)
    second = create(api, headers, after) if independent else save(api, headers, first, after)
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    result = response.json()
    assert [c["kind"] for r in result["ingredients"] for c in r["changes"]] == expected
    assert sum(r["before"] is not None for r in result["ingredients"]) == len(before)
    assert sum(r["after"] is not None for r in result["ingredients"]) == len(after)
    assert compare(api, headers, first, second).json() == result
    if before and before[0]["quantity"] == 0:
        assert result["ingredients"][0]["changes"][0]["relative_change"] is None


@pytest.mark.parametrize(
    "field,value",
    [
        ("preparation", "切丁"),
        ("group", "主料"),
        ("optional", True),
        ("functional", True),
        ("scaling_mode", "unchanged"),
        ("replacement", "糖"),
    ],
)
def test_execution_fields_are_compared(api: Api, field, value) -> None:
    headers = bearer(api.login("fields-compare@example.com"))
    first = create(api, headers, [ingredient()])
    second = save(api, headers, first, [ingredient(**{field: value})])
    result = compare(api, headers, first, second).json()
    changes = result["ingredients"][0]["changes"]
    assert len(changes) == 1
    assert changes[0]["kind"] == "field"
    assert changes[0]["field"] == field
    assert changes[0]["after"] == value


@pytest.mark.parametrize(
    "target,mode,before,after",
    [
        (1, "proportional", 3, 1.5),
        (2, "proportional", 3, 3),
        (4, "proportional", 3, 6),
        (4, "unchanged", 3, 3),
        (4, "round", 2, 4),
        (1, "round", 2, 1),
        (4, "round", 0, 0),
    ],
)
def test_serving_normalization_has_no_false_quantity_change(
    api: Api, target, mode, before, after
) -> None:
    headers = bearer(api.login("normalize-compare@example.com"))
    first = create(api, headers, [ingredient(quantity=before, scaling_mode=mode)])
    second = save(
        api, headers, first, [ingredient(quantity=after, scaling_mode=mode)], servings=target
    )
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["normalized_servings"] == 2
    assert result["ingredients"][0]["changes"] == []
    assert result["ingredients"][0]["after"]["base_quantity"] == before
    assert (
        api.client.get(f"/v1/recipes/{second['id']}", headers=headers).json()["version"][
            "snapshot"
        ]["ingredients"][0]["base_quantity"]
        == after
    )
