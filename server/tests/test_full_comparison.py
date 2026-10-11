"""Full deterministic version comparison through HTTP and audited CLI, on PostgreSQL."""

import json
from copy import deepcopy
from pathlib import Path
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from gramtree.main import create_app
from tests.accounts_support import Api, bearer
from tests.conftest import make_settings


def ingredient(quantity: float = 15, **fields) -> dict:
    return {
        "id": "sauce",
        "display_name": "生抽",
        "quantity": quantity,
        "unit": "ml",
        "group": "调味",
        **fields,
    }


def step(id: str = "cook", **fields) -> dict:
    return {
        "id": id,
        "action": "炒",
        "instruction": "炒熟",
        "ingredient_ids": ["sauce"],
        "duration_seconds": 100,
        "cookware": "炒锅",
        **fields,
    }


def create(api: Api, headers: dict, **snapshot) -> dict:
    response = api.client.post(
        "/v1/recipes",
        headers=headers,
        json={
            "dish_name": "完整比较菜",
            "snapshot": {
                "servings": 2,
                "ingredients": [ingredient()],
                "steps": [step()],
                **snapshot,
            },
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def save(api: Api, headers: dict, first: dict, *, base_version_id=None, **changes) -> dict:
    snapshot = deepcopy(first["version"]["snapshot"])
    snapshot.update(changes)
    response = api.client.post(
        f"/v1/recipes/{first['id']}/versions",
        headers=headers,
        json={"snapshot": snapshot, "base_version_id": base_version_id},
    )
    assert response.status_code == 201, response.text
    return response.json()


def compare(api: Api, headers: dict, first: dict, second: dict):
    return api.client.get(
        f"/v1/recipes/{first['id']}/full-comparison",
        headers=headers,
        params={
            "from_version_id": first["version"]["id"],
            "to_version_id": second["version"]["id"],
        },
    )


@pytest.mark.parametrize(
    "before,after,unit,grade,conclusion",
    [
        (15, 13, "ml", "minor", "minor_only"),
        (3, 2, "g", "general", "general"),
        (10, 8, "g", "general", "general"),
        (0, 1, "g", "general", "general"),
        (10.5, 8.4, "g", "general", "general"),
        (0.1, 0.12, "g", "general", "general"),
        (0.102, 0.0816, "kg", "general", "general"),
        (10, 8.001, "g", "minor", "minor_only"),
    ],
)
def test_quantity_rules_and_save_history_are_explainable(
    api: Api, before, after, unit, grade, conclusion
) -> None:
    headers = bearer(api.login("full-quantity@example.com"))
    first = create(api, headers, ingredients=[ingredient(before, unit=unit)])
    second = save(api, headers, first, ingredients=[ingredient(after, unit=unit)])
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["scope"] == "full"
    assert data["conclusion"] == conclusion
    change = next(c for c in data["ingredients"][0]["changes"] if c["kind"] == "quantity")
    assert change["grade"] == grade
    assert change["basis"] and change["rule_id"]
    assert change["rules_version"] == data["rules_version"]
    assert second["version"]["conclusion"] == conclusion
    assert second["version"]["rules_version"] == data["rules_version"]
    assert second["version"]["base_version_id"] == first["version"]["id"]
    history = api.client.get(f"/v1/recipes/{first['id']}/versions", headers=headers).json()["items"]
    assert history[0]["conclusion"] == conclusion
    assert history[0]["rules_version"] == data["rules_version"]
    assert history[1]["conclusion"] is None
    assert history[1]["rules_version"] is None


@pytest.mark.parametrize(
    "field,value,grade,conclusion",
    [
        ("duration_seconds", 85, "minor", "minor_only"),
        ("duration_seconds", 80, "general", "general"),
        ("unattended", True, "general", "general"),
        ("heat", "小火", "general", "general"),
        ("temperature_celsius", 150, "general", "general"),
        ("cookware", "空气炸锅", "significant", "significant"),
        ("doneness", "中心熟透", "general", "general"),
        ("instruction", "翻炒至熟", "excluded", "minor_only"),
        ("notes", "及时翻动", "excluded", "minor_only"),
        ("why", "更好吃", "excluded", "minor_only"),
    ],
)
def test_aligned_steps_preserve_fields_and_grade_execution_not_wording(
    api: Api, field, value, grade, conclusion
) -> None:
    headers = bearer(api.login("full-step@example.com"))
    first = create(api, headers)
    second = save(api, headers, first, steps=[step("renumbered", **{field: value})])
    response = compare(api, headers, first, second)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["conclusion"] == conclusion
    assert len(data["steps"]) == 1
    row = data["steps"][0]
    assert row["alignment"] == "deterministic"
    assert row["before"]["id"] == "cook" and row["after"]["id"] == "renumbered"
    assert len(row["changes"]) == 1
    change = row["changes"][0]
    assert change["field"] == field and change["after"] == value
    assert change["grade"] == grade
    assert (
        change["basis"] and change["rule_id"] and change["rules_version"] == data["rules_version"]
    )


@pytest.mark.parametrize(
    "before,after,kind",
    [
        ([], [ingredient(group="主料")], "added"),
        ([ingredient(group="主料")], [], "removed"),
        ([ingredient(group="主料")], [ingredient(group="调味")], "field"),
    ],
)
def test_main_ingredient_membership_changes_are_significant(api: Api, before, after, kind) -> None:
    headers = bearer(api.login("main-membership@example.com"))
    first = create(api, headers, ingredients=before, steps=[])
    second = save(api, headers, first, ingredients=after)
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "significant"
    assert any(
        c["kind"] == kind and c["grade"] == "significant"
        for row in data["ingredients"]
        for c in row["changes"]
    )


@pytest.mark.parametrize("action", ["炸", "切"])
def test_main_heating_action_set_changes_even_for_unaligned_steps(api: Api, action) -> None:
    headers = bearer(api.login("main-heating@example.com"))
    first = create(api, headers, ingredients=[ingredient(group="主料")])
    second = save(api, headers, first, steps=[step(action=action)])
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "significant"
    method = next(c for c in data["method_changes"] if c["field"] == "main_heating_actions")
    assert method["before"] == ["炒"]
    assert method["after"] == (["炸"] if action == "炸" else [])
    assert method["grade"] == "significant" and method["basis"]


def test_reused_raw_dependency_ids_do_not_hide_semantically_changed_targets(api: Api) -> None:
    headers = bearer(api.login("reused-dependency@example.com"))
    first = create(
        api,
        headers,
        steps=[step("x", action="切"), step("y", action="洗"), step("z", depends_on=["x"])],
    )
    second = save(
        api,
        headers,
        first,
        steps=[step("y", action="切"), step("x", action="洗"), step("z", depends_on=["x"])],
    )
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "general"
    row = next(r for r in data["steps"] if r["before"]["id"] == "z")
    assert any(c["field"] == "depends_on" and c["grade"] == "general" for c in row["changes"])


def test_independent_recipes_reusing_ids_compare_paired_ingredient_targets(api: Api) -> None:
    headers = bearer(api.login("reused-ingredient-ref@example.com"))
    first = create(
        api,
        headers,
        ingredients=[
            ingredient(id="x", display_name="甲食材"),
            ingredient(id="y", display_name="乙食材"),
        ],
        steps=[step(ingredient_ids=["x"])],
    )
    second = create(
        api,
        headers,
        ingredients=[
            ingredient(id="y", display_name="甲食材"),
            ingredient(id="x", display_name="乙食材"),
        ],
        steps=[step(ingredient_ids=["x"])],
    )
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "general"
    assert all(not row["changes"] for row in data["ingredients"])
    assert any(c["field"] == "ingredient_ids" for c in data["steps"][0]["changes"])


def test_reorder_dependencies_and_renumbered_references(api: Api) -> None:
    headers = bearer(api.login("order-dependencies@example.com"))
    first = create(
        api, headers, steps=[step("prep", action="切"), step("cook", depends_on=["prep"])]
    )
    # Semantic references do not change when step IDs are renumbered.
    renamed = save(
        api, headers, first, steps=[step("p2", action="切"), step("c2", depends_on=["p2"])]
    )
    equivalent = compare(api, headers, first, renamed).json()
    assert equivalent["conclusion"] == "no_change"
    assert all(not row["changes"] for row in equivalent["steps"])
    second = save(
        api, headers, renamed, steps=[step("c3"), step("p3", action="切", depends_on=["c3"])]
    )
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "general"
    changes = [c for row in data["steps"] for c in row["changes"]]
    assert len([c for c in changes if c["kind"] == "order"]) == 2
    assert len([c for c in changes if c["field"] == "depends_on"]) == 2
    assert {row["before"]["id"]: row["after"]["id"] for row in data["steps"]} == {
        "prep": "p3",
        "cook": "c3",
    }


@pytest.mark.parametrize("mode", ["ambiguous", "low", "added", "removed"])
def test_uncertain_or_unpaired_steps_remain_lossless_and_conservative(api: Api, mode) -> None:
    headers = bearer(api.login("uncertain@example.com"))
    before = [step("a", action="切", cookware=None, notes="原始要点")]
    if mode == "ambiguous":
        after = [
            step("a", action="切", cookware=None, notes="另一要点"),
            step("b", action="切", cookware=None),
        ]
    elif mode == "low":
        after = [
            step(
                "a",
                action="摆盘",
                ingredient_ids=[],
                cookware=None,
                instruction="同样编号不是同样方法",
            )
        ]
    elif mode == "added":
        before, after = [], before
    else:
        after = []
    first = create(api, headers, steps=before)
    second = save(api, headers, first, steps=after)
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "general"
    rows = data["steps"]
    assert all(
        row["alignment"] == ("uncertain" if mode in {"ambiguous", "low"} else "unpaired")
        for row in rows
    )
    assert [row["before"] for row in rows if row["before"]] == first["version"]["snapshot"]["steps"]
    assert [row["after"] for row in rows if row["after"]] == second["version"]["snapshot"]["steps"]
    assert len(rows) == len(before) + len(after)
    assert all(c["grade"] == "general" for row in rows for c in row["changes"])


@pytest.mark.parametrize(
    "unit_before,qty_before,unit_after,qty_after",
    [("一撮", 1, "一撮", 2), ("一撮", 1, "一把", 1), ("g", 1, "ml", 1)],
)
def test_unconvertible_quantities_are_not_hidden_as_zero(
    api: Api, unit_before, qty_before, unit_after, qty_after
) -> None:
    headers = bearer(api.login("unknown-unit@example.com"))
    first = create(api, headers, ingredients=[ingredient(qty_before, unit=unit_before)])
    second = save(api, headers, first, ingredients=[ingredient(qty_after, unit=unit_after)])
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "general"
    changes = data["ingredients"][0]["changes"]
    assert any(
        c["kind"] == "unit" and c["grade"] == "general" and c["relative_change"] is None
        for c in changes
    )


def test_directional_cache_rules_and_permissions_are_checked_on_every_read(api: Api) -> None:
    headers = bearer(api.login("cache-owner@example.com"))
    first = create(api, headers, ingredients=[ingredient(10)])
    second = save(api, headers, first, ingredients=[ingredient(8)])
    original = compare(api, headers, first, second).json()
    assert compare(api, headers, first, second).json() == original
    reverse = compare(api, headers, second, first).json()
    assert reverse["ingredients"][0]["changes"][0]["relative_change"] == 0.25
    assert original["ingredients"][0]["changes"][0]["relative_change"] == -0.2
    assert reverse["from_version"]["version_id"] == second["version"]["id"]
    assert (
        cli(
            [
                "config",
                "set",
                "recipe.comparison_minor_threshold",
                "0.3",
                "--by",
                "test",
                "--reason",
                "change rules",
            ]
        )
        == 0
    )
    updated = compare(api, headers, first, second).json()
    assert updated["conclusion"] == "minor_only"
    assert updated["rules_version"] != original["rules_version"]
    assert updated["ingredients"][0]["changes"][0]["grade"] == "minor"
    # Historical save evidence never silently adopts a new runtime policy.
    history = api.client.get(f"/v1/recipes/{first['id']}/versions", headers=headers).json()["items"]
    assert history[0]["conclusion"] == "general"
    assert history[0]["rules_version"] == original["rules_version"]
    other = bearer(api.login("cache-other@example.com"))
    anchor = create(api, other)
    denied = api.client.get(
        f"/v1/recipes/{anchor['id']}/full-comparison",
        headers=other,
        params={
            "from_version_id": first["version"]["id"],
            "to_version_id": second["version"]["id"],
        },
    )
    missing = api.client.get(
        f"/v1/recipes/{anchor['id']}/full-comparison",
        headers=other,
        params={"from_version_id": str(uuid4()), "to_version_id": str(uuid4())},
    )
    assert denied.status_code == missing.status_code == 404
    assert denied.json()["error"]["message"] == missing.json()["error"]["message"]
    assert compare(api, other, first, second).status_code == 404
    for a, b in [(first, anchor), (anchor, first)]:
        assert compare(api, headers, a, b).status_code == 404


@pytest.mark.parametrize("wording,count", [(False, 1), (True, 1), (False, 2), (True, 2)])
def test_instruction_only_steps_noop_or_wording_never_invent_method_changes(
    api: Api, wording, count
) -> None:
    headers = bearer(api.login("instruction-only@example.com"))
    raw = [
        step(str(i), action=None, ingredient_ids=[], instruction="原始说明") for i in range(count)
    ]
    first = create(api, headers, steps=raw)
    after = [
        {**s, "id": f"new-{s['id']}", "instruction": "润色说明" if wording else s["instruction"]}
        for s in raw
    ]
    second = save(api, headers, first, steps=after)
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == ("minor_only" if wording else "no_change")
    assert len(data["steps"]) == count
    assert all(
        c["kind"] == "text" and c["grade"] == "excluded"
        for row in data["steps"]
        for c in row["changes"]
    )


def test_standard_main_replacement_uses_legacy_pairing_and_is_significant(
    api: Api, tmp_path: Path
) -> None:
    ids = [str(uuid4()), str(uuid4())]
    records = [
        {
            "id": id,
            "standard_name": name,
            "aliases": [],
            "pinyin": "jirou",
            "pinyin_initials": "jr",
            "category": "肉禽",
            "attributes": {},
        }
        for id, name in zip(ids, ["鸡腿肉", "鸡胸肉"], strict=True)
    ]
    (tmp_path / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "full comparison"}), encoding="utf-8"
    )
    (tmp_path / "ingredients.json").write_text(json.dumps(records), encoding="utf-8")
    assert cli(["ingredients", "import", str(tmp_path)]) == 0
    headers = bearer(api.login("main-replacement@example.com"))
    first = create(
        api,
        headers,
        ingredients=[
            ingredient(100, unit="g", display_name="鸡腿肉", ingredient_id=ids[0], group="主料")
        ],
    )
    second = save(
        api,
        headers,
        first,
        ingredients=[
            ingredient(100, unit="g", display_name="鸡胸肉", ingredient_id=ids[1], group="主料")
        ],
    )
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "significant"
    row = data["ingredients"][0]
    assert row["pairing"] == "stable_id"
    assert next(c for c in row["changes"] if c["kind"] == "replacement")["grade"] == "significant"
    legacy = api.client.get(
        f"/v1/recipes/{first['id']}/compare",
        headers=headers,
        params={
            "from_version_id": first["version"]["id"],
            "to_version_id": second["version"]["id"],
        },
    ).json()
    assert legacy["scope"] == "ingredients"
    assert "conclusion" not in legacy and "steps" not in legacy
    assert (
        row["before"] == legacy["ingredients"][0]["before"]
        and row["after"] == legacy["ingredients"][0]["after"]
    )
    assert [c["kind"] for c in row["changes"]] == [
        c["kind"] for c in legacy["ingredients"][0]["changes"]
    ]


@pytest.mark.parametrize("scaled", [False, True])
def test_normalization_and_many_minor_changes_never_accumulate(api: Api, scaled) -> None:
    headers = bearer(api.login("normalization-minors@example.com"))
    before = [ingredient(100, id=f"i-{i}", display_name=f"食材{i}", unit="g") for i in range(5)]
    steps = [step(ingredient_ids=["i-0"])]
    first = create(api, headers, ingredients=before, steps=steps)
    after = [{**i, "quantity": 200 if scaled else 90} for i in before]
    second = save(
        api,
        headers,
        first,
        servings=4 if scaled else 2,
        ingredients=after,
        steps=[{**steps[0], "duration_seconds": 100 if scaled else 90}],
    )
    data = compare(api, headers, first, second).json()
    assert data["normalized_servings"] == 2
    assert data["conclusion"] == ("no_change" if scaled else "minor_only")
    assert all(c["grade"] == "minor" for row in data["ingredients"] for c in row["changes"])


@pytest.mark.parametrize(
    "key,value,expected",
    [
        ("recipe.comparison_main_groups", '{"values":["调味"]}', "significant"),
        ("recipe.comparison_heating_actions", '{"values":[]}', "general"),
        ("recipe.comparison_alignment_threshold", "0.9", "significant"),
    ],
)
def test_all_rule_config_content_invalidates_directional_results(
    api: Api, key, value, expected
) -> None:
    headers = bearer(api.login("config-fingerprint@example.com"))
    if key.endswith("main_groups"):
        first = create(api, headers, ingredients=[], steps=[])
        second = save(api, headers, first, ingredients=[ingredient()])
    else:
        first = create(api, headers, ingredients=[ingredient(group="主料")])
        second = save(api, headers, first, steps=[step(action="炸")])
    original = compare(api, headers, first, second).json()
    assert (
        cli(["config", "set", key, value, "--by", "test", "--reason", "rule content update"]) == 0
    )
    updated = compare(api, headers, first, second).json()
    assert updated["rules_version"] != original["rules_version"]
    assert updated["conclusion"] == expected
    if key.endswith("alignment_threshold"):
        assert all(row["alignment"] == "uncertain" for row in updated["steps"])
        assert len(updated["steps"]) == 2


def test_inserted_step_does_not_invent_reordering(api: Api) -> None:
    headers = bearer(api.login("insert-step@example.com"))
    first = create(api, headers, steps=[step("cut", action="切"), step("cook")])
    second = save(
        api,
        headers,
        first,
        steps=[
            step("wash", action="洗", ingredient_ids=[], cookware=None),
            step("cut", action="切"),
            step("cook"),
        ],
    )
    data = compare(api, headers, first, second).json()
    assert data["conclusion"] == "general"
    changes = [c for row in data["steps"] for c in row["changes"]]
    assert [c["kind"] for c in changes] == ["added"]


def test_other_dish_cannot_use_even_owned_versions(api: Api) -> None:
    headers = bearer(api.login("different-dish-full@example.com"))
    first = create(api, headers)
    other = api.client.post(
        "/v1/recipes",
        headers=headers,
        json={
            "dish_name": "不一样的菜",
            "snapshot": {"servings": 2, "steps": [], "ingredients": []},
        },
    ).json()
    assert compare(api, headers, first, other).status_code == 422
    assert compare(api, headers, other, first).status_code == 422


def test_durable_outbox_retains_conclusion_after_delete_and_retry(api: Api, capsys) -> None:
    headers = bearer(api.login("full-durable-event@example.com"))
    first = create(api, headers)
    # Redis is an external boundary; use an unavailable endpoint, not mocks of
    # the application's outbox/event collaborators.
    with TestClient(
        create_app(make_settings(redis_url="redis://127.0.0.1:63999/6")),
        raise_server_exceptions=False,
    ) as broken:
        snapshot = deepcopy(first["version"]["snapshot"])
        snapshot["ingredients"][0]["quantity"] = 13
        response = broken.post(
            f"/v1/recipes/{first['id']}/versions", headers=headers, json={"snapshot": snapshot}
        )
        assert response.status_code == 201, response.text
        second = response.json()
        assert second["version"]["conclusion"] == "minor_only"
        assert broken.delete(f"/v1/recipes/{first['id']}", headers=headers).status_code == 204
    capsys.readouterr()
    assert cli(["recipes", "drain-save-events"]) == 0
    assert "已投递 1 条" in capsys.readouterr().out
    assert cli(["recipes", "save-event-receipt", second["version"]["id"]]) == 0
    event = json.loads(capsys.readouterr().out)
    assert (
        event["conclusion"] == "minor_only"
        and event["rules_version"] == second["version"]["rules_version"]
    )
    assert event["previous_version_id"] == first["version"]["id"]
    assert event["base_version_id"] == first["version"]["id"]
    assert cli(["recipes", "drain-save-events"]) == 0
    assert "已投递 0 条" in capsys.readouterr().out


@pytest.mark.parametrize(
    "key,value",
    [
        ("recipe.comparison_main_groups", "{}"),
        ("recipe.comparison_heating_actions", '{"values":false}'),
        ("recipe.comparison_main_groups", '{"values":[1]}'),
        ("recipe.comparison_minor_threshold", "nan"),
    ],
)
def test_invalid_comparison_config_cannot_break_existing_saves(api: Api, key, value) -> None:
    headers = bearer(api.login("invalid-rule-config@example.com"))
    first = create(api, headers)
    assert (
        cli(["config", "set", key, value, "--by", "test", "--reason", "invalid config rejected"])
        != 0
    )
    second = save(api, headers, first, ingredients=[ingredient(13)])
    assert second["version"]["conclusion"] == "minor_only"


def test_old_editing_baseline_save_event_uses_actual_predecessor(api: Api, capsys) -> None:
    headers = bearer(api.login("baseline-event@example.com"))
    first = create(api, headers, ingredients=[ingredient(10)])
    second = save(api, headers, first, ingredients=[ingredient(5)])
    third = save(
        api, headers, first, base_version_id=first["version"]["id"], ingredients=[ingredient(9)]
    )
    assert third["version"]["previous_version_id"] == second["version"]["id"]
    assert third["version"]["base_version_id"] == first["version"]["id"]
    assert third["version"]["conclusion"] == "general"
    assert compare(api, headers, first, third).json()["conclusion"] == "minor_only"
    assert compare(api, headers, second, third).json()["conclusion"] == "general"
    operation = next(o for o in third["version"]["edit_operations"] if o.get("field") == "quantity")
    assert operation["before"] == 10 and operation["after"] == 9
    capsys.readouterr()
    assert cli(["recipes", "save-event-receipt", third["version"]["id"]]) == 0
    event = json.loads(capsys.readouterr().out)
    assert event["conclusion"] == "general"
    assert event["rules_version"] == third["version"]["rules_version"]
    assert event["previous_version_id"] == second["version"]["id"]
    assert event["base_version_id"] == first["version"]["id"]
    assert cli(["recipes", "save-event-receipt", first["version"]["id"]]) == 0
    initial_event = json.loads(capsys.readouterr().out)
    assert initial_event["conclusion"] is None and initial_event["rules_version"] is None
