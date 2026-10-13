"""SPEC-003.2 taste/substitution behavior through HTTP and recorded provider replies."""

import copy
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import cli, configure, recording
from tests.test_ingredients_attributes import CHECKED, _import, _record, _write
from tests.test_recipe_modifications import choice
from tests.test_recipes import recipe_input

CORPUS = json.loads(
    Path(__file__)
    .with_name("fixtures")
    .joinpath("ai/taste_substitution_modification_corpus.json")
    .read_text("utf-8")
)
TASTE = CORPUS["taste"]
SUB = CORPUS["substitution"]
AXES = ("salty", "sweet", "sour", "spicy", "umami", "numbing", "oily")
ZERO = dict.fromkeys(AXES, 0)


@pytest.fixture
def modification_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def modification_api(modification_recordings, api):
    return api, modification_recordings


def create(api, body, email="consequential@example.com"):
    headers = bearer(api.login(email))
    response = api.client.post("/v1/recipes", headers=headers, json=body)
    assert response.status_code == 201, response.text
    return response.json(), headers


def taste_recipe():
    body = recipe_input()
    snapshot = body["snapshot"]
    snapshot["ingredients"] = [snapshot["ingredients"][0]]
    snapshot["ingredients"][0]["flavor_contribution"] = ZERO.copy()
    snapshot["ingredients"].extend(
        {
            **copy.deepcopy(item),
            "flavor_contribution": {**ZERO, **item["flavor_contribution"]},
            "functional": False,
            "group": "调味",
            "scaling_mode": "proportional",
        }
        for item in TASTE["ingredients"]
    )
    snapshot["steps"][1]["ingredient_ids"] = ["chicken", "salt", "soy", "oyster", "bean"]
    snapshot["steps"][1]["instruction"] = "中火炒鸡肉至中心温度达到74°C，加入调料收汁"
    return body


def edit(snapshot, change, *, intent, reason, risk):
    collection = "steps" if change["type"].startswith("change_step") else "ingredients"
    node = next(item for item in snapshot[collection] if item["id"] == change["id"])
    before = node if change["type"] == "remove_ingredient" else node[change["field"]]
    return {
        "before": before,
        "scope": [collection],
        "intent": intent,
        "reason": reason,
        "risk": risk,
        "confidence": 0.85,
        "depends_on": [],
        **change,
    }


def taste_operations(snapshot, amounts, *, sides=True):
    changes = [
        {
            "operation_id": f"reduce-{item_id}",
            "type": "change_quantity",
            "id": item_id,
            "field": "quantity",
            "after": amount,
        }
        for item_id, amount in amounts.items()
    ]
    if sides:
        changes.extend(copy.deepcopy(TASTE["side_effects"]))
    return [
        edit(snapshot, change, intent="降低咸度", reason=TASTE["reason"], risk=TASTE["risk"])
        for change in changes
    ]


def proposal(
    api,
    directory,
    headers,
    created,
    text,
    intent,
    operations,
    *,
    amounts=None,
    percent=None,
    configured_percent=25,
    explanation=None,
):
    recording(directory, "modify_intent", {"text": text}, intent)
    effective_intent = copy.deepcopy(intent)
    if intent["category"] == "taste":
        effective_intent["parameters"]["adjustment_percent"] = (
            percent if percent is not None else configured_percent
        )
    snapshot = created["version"]["snapshot"]
    if intent["category"] == "substitution":
        parameters = effective_intent["parameters"]
        if "ingredient_id" not in parameters:
            target_name = parameters.get("missing_ingredient") or parameters.get("ingredient_name")
            matches = [
                item for item in snapshot["ingredients"] if item["display_name"] == target_name
            ]
            assert len(matches) == 1
            parameters["ingredient_id"] = matches[0]["id"]
    payload = {"text": text, "snapshot": snapshot, "intent": effective_intent}
    if intent["category"] == "substitution":
        target = next(
            item
            for item in snapshot["ingredients"]
            if item["id"] == effective_intent["parameters"]["ingredient_id"]
        )
        relation = target["replacement"]
        payload["substitution_facts"] = None
        if relation is not None:
            response = api.client.get(f"/v1/ingredients/{relation['ingredient_id']}")
            assert response.status_code == 200, response.text
            ingredient = response.json()
            payload["substitution_facts"] = {
                "ingredient_id": ingredient["id"],
                "display_name": ingredient["standard_name"],
                "ratio": float(relation["ratio"]),
                "attributes": ingredient["attributes"],
            }
    if amounts is not None:
        # Provider replay keys distinguish JSON 12 from 12.0; quantities are floats.
        payload["taste_quantities"] = {
            item_id: float(amount) for item_id, amount in amounts.items()
        }
    output = {"operations": operations}
    if explanation is not None:
        output["explanation"] = explanation
    recording(directory, "modify", payload, output)
    recording(
        directory,
        "modify",
        {**payload, "repair": {"errors": ["invalid_operations"], "previous": output}},
        output,
    )
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={
            "text": text,
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
            **({"adjustment_percent": percent} if percent is not None else {}),
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


def accept_all(preview):
    return [
        {"operation_id": op["operation_id"], "decision": "accept"} for op in preview["operations"]
    ]


def confirm(api, headers, selected):
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{selected['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert response.status_code == 201, response.text
    return response.json()["version"]


def unchanged_old(api, headers, created):
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    )
    assert old.status_code == 200, old.text
    assert old.json()["version"] == created["version"]


@pytest.mark.parametrize(
    "percent,expected,total",
    [
        (20, {"salt": 2.4, "soy": 12, "oyster": 8, "bean": 12}, 83.2),
        (None, {"salt": 2.25, "soy": 11.25, "oyster": 7.5, "bean": 11.25}, 78),
        (30, {"salt": 2.1, "soy": 10.5, "oyster": 7, "bean": 10.5}, 72.8),
    ],
)
def test_four_sources_use_known_contributions_and_requested_percent(
    modification_api, percent, expected, total
):
    api, directory = modification_api
    created, headers = create(api, taste_recipe())
    baseline = created["version"]["snapshot"]
    preview = proposal(
        api,
        directory,
        headers,
        created,
        TASTE["text"],
        TASTE["intent"],
        taste_operations(baseline, expected),
        amounts=expected,
        percent=percent,
    )
    assert preview["error"] is None, preview
    assert preview["snapshot"] == baseline
    quantities = {
        op["id"]: op["after"] for op in preview["operations"] if op["type"] == "change_quantity"
    }
    assert quantities == expected
    assert any("颜色" in warning for warning in preview["warnings"])
    assert any("鲜味" in warning for warning in preview["warnings"])
    assert any("收汁" in warning for warning in preview["warnings"])
    selected = choice(api, headers, preview, accept_all(preview))
    items = {item["id"]: item for item in selected["snapshot"]["ingredients"]}
    assert sum(
        items[key]["base_quantity"] * strength
        for key, strength in (("salt", 3), ("soy", 2), ("oyster", 2), ("bean", 3))
    ) == pytest.approx(total)
    assert items["chicken"] == baseline["ingredients"][0]
    saved = confirm(api, headers, selected)
    assert saved["snapshot"] == selected["snapshot"]
    assert all(op["intent"] == "降低咸度" for op in saved["edit_operations"])
    unchanged_old(api, headers, created)


@pytest.mark.parametrize("invalid_value", [0.24, 20, 0.35])
def test_cli_rejects_invalid_taste_config(modification_api, invalid_value):
    _api, _directory = modification_api
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "gramtree.cli",
            "config",
            "set",
            "taste.adjustment_percent",
            json.dumps(invalid_value),
            "--by",
            "acceptance-test",
            "--reason",
            "SPEC-003.2 invalid taste percentage",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"},
    )
    assert result.returncode != 0
    assert "taste.adjustment_percent" in result.stdout + result.stderr
    current = subprocess.run(
        [sys.executable, "-m", "gramtree.cli", "config", "get", "taste.adjustment_percent"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"},
    )
    assert current.returncode == 0 and current.stdout.strip() == "0.25"


def test_default_percent_comes_from_registered_configuration(modification_api):
    api, directory = modification_api
    configure("taste.adjustment_percent", 0.2)
    created, headers = create(api, taste_recipe())
    expected = {"salt": 2.4, "soy": 12, "oyster": 8, "bean": 12}
    preview = proposal(
        api,
        directory,
        headers,
        created,
        TASTE["text"],
        TASTE["intent"],
        taste_operations(created["version"]["snapshot"], expected),
        amounts=expected,
        configured_percent=20,
    )
    assert preview["error"] is None, preview
    assert {
        op["id"]: op["after"] for op in preview["operations"] if op["type"] == "change_quantity"
    } == expected


@pytest.mark.parametrize(
    "role,name,axis", [("腌肉", "盐", "salty"), ("发酵", "糖", "sweet"), ("面团", "盐", "salty")]
)
def test_functional_same_name_source_is_preserved_while_other_source_adjusts(
    modification_api, role, name, axis
):
    api, directory = modification_api
    body = recipe_input()
    body["snapshot"]["ingredients"] = [
        {
            "id": "protected",
            "display_name": name,
            "quantity": 2,
            "unit": "g",
            "functional": True,
            "preparation": role,
            "flavor_contribution": {**ZERO, axis: 3},
        },
        {
            "id": "seasoning",
            "display_name": name,
            "quantity": 6,
            "unit": "g",
            "functional": False,
            "flavor_contribution": {**ZERO, axis: 3},
        },
    ]
    for step in body["snapshot"]["steps"]:
        step["ingredient_ids"] = ["protected", "seasoning"]
    created, headers = create(api, body)
    baseline = created["version"]["snapshot"]
    intent = {
        "category": "taste",
        "parameters": {"axis": axis, "direction": "reduce"},
        "confidence": 0.95,
    }
    # Known contribution 24 -> 18; functional 2g stays, seasoning 6g -> 4g.
    expected = {"seasoning": 4}
    preview = proposal(
        api,
        directory,
        headers,
        created,
        f"{role}这道菜少一点{name}",
        intent,
        taste_operations(baseline, expected, sides=False),
        amounts=expected,
    )
    assert preview["error"] is None, preview
    assert [op["id"] for op in preview["operations"]] == ["seasoning"]
    selected = choice(api, headers, preview, accept_all(preview))
    assert selected["snapshot"]["ingredients"][0] == baseline["ingredients"][0]
    assert selected["snapshot"]["ingredients"][1]["quantity"] == 4


@pytest.mark.parametrize(
    "axis,text,direction,expected",
    [
        ("sweet", "少甜一点", "reduce", 7.5),
        ("sour", "少酸一点", "reduce", 7.5),
        ("spicy", "加点辣", "increase", 12.5),
        ("oily", "少油一点", "reduce", 7.5),
    ],
)
def test_other_taste_axes_use_known_recipe_contribution(
    modification_api, axis, text, direction, expected
):
    api, directory = modification_api
    body = recipe_input()
    for item in body["snapshot"]["ingredients"]:
        item["flavor_contribution"] = ZERO.copy()
    body["snapshot"]["ingredients"][1].update(
        quantity=10, unit="g", flavor_contribution={**ZERO, axis: 2}
    )
    created, headers = create(api, body)
    intent = {
        "category": "taste",
        "parameters": {"axis": axis, "direction": direction},
        "confidence": 0.95,
    }
    preview = proposal(
        api,
        directory,
        headers,
        created,
        text,
        intent,
        taste_operations(created["version"]["snapshot"], {"pepper": expected}, sides=False),
        amounts={"pepper": expected},
    )
    assert preview["error"] is None, preview
    selected = choice(api, headers, preview, accept_all(preview))
    assert (
        selected["snapshot"]["ingredients"][0] == created["version"]["snapshot"]["ingredients"][0]
    )
    assert selected["snapshot"]["ingredients"][1]["quantity"] == expected


@pytest.mark.parametrize("missing", ["contribution", "axis", "conversion", "functional_capacity"])
def test_insufficient_taste_data_has_honest_noop_without_guessing(modification_api, missing):
    api, directory = modification_api
    body = taste_recipe()
    target = body["snapshot"]["ingredients"][1]
    if missing == "contribution":
        target["flavor_contribution"] = None
    elif missing == "axis":
        target["flavor_contribution"]["salty"] = None
    elif missing == "conversion":
        target["unit"] = "撮"
    else:
        for item in body["snapshot"]["ingredients"][2:]:
            item["functional"] = True
    created, headers = create(api, body)
    preview = proposal(
        api,
        directory,
        headers,
        created,
        TASTE["text"],
        TASTE["intent"],
        [],
        explanation="缺少实际贡献或可调整的量，无法可靠分摊；功能性用料不能突破保护",
    )
    assert preview["error"] == "cannot_modify", preview
    assert preview["operations"] == []
    assert preview["warnings"]
    assert preview["snapshot"] == created["version"]["snapshot"]
    current = api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()
    assert current["version"] == created["version"]


def test_reject_modify_and_side_effect_decisions_save_exact_values_and_events(modification_api):
    api, directory = modification_api
    created, headers = create(api, taste_recipe())
    expected = {"salt": 2.25, "soy": 11.25, "oyster": 7.5, "bean": 11.25}
    preview = proposal(
        api,
        directory,
        headers,
        created,
        TASTE["text"],
        TASTE["intent"],
        taste_operations(created["version"]["snapshot"], expected),
        amounts=expected,
    )
    assert preview["error"] is None, preview
    decisions = accept_all(preview)
    for decision in decisions:
        if decision["operation_id"] in ("reduce-soy", "umami-why"):
            decision["decision"] = "reject"
        if decision["operation_id"] == "reduce-salt":
            decision.update(decision="modify", after=2.6)
    selected = choice(api, headers, preview, decisions)
    selected_decisions = {item["operation_id"]: item for item in selected["decisions"]}
    assert selected_decisions["color-notes"]["decision"] == "reject"
    assert selected_decisions["color-notes"]["blocked_by"] == ["reduce-soy"]
    assert selected_decisions["reduction-instruction"]["decision"] == "reject"
    assert "减少咸味来源可能使颜色变浅，请单独观察上色" in selected["warnings"]
    assert any("收汁" in warning for warning in selected["warnings"])
    items = {item["id"]: item for item in selected["snapshot"]["ingredients"]}
    assert {key: items[key]["quantity"] for key in expected} == {
        "salt": 2.6,
        "soy": 15,
        "oyster": 7.5,
        "bean": 11.25,
    }
    assert items["salt"]["quantity_source"]["source"] == "author_filled"
    assert selected["snapshot"]["steps"] == created["version"]["snapshot"]["steps"]
    checked = api.client.post(
        "/v1/recipes/safety/check",
        headers=headers,
        json={"dish_name": created["dish"]["name"], "snapshot": selected["snapshot"]},
    )
    assert checked.status_code == 200, checked.text
    for key in ("findings", "allergens", "allergens_incomplete", "can_save"):
        assert selected["safety"][key] == checked.json()["result"][key]
    saved = confirm(api, headers, selected)
    assert saved["snapshot"] == selected["snapshot"]
    assert {op["operation_id"]: op["after"] for op in saved["edit_operations"]} == {
        "reduce-salt": 2.6,
        "reduce-oyster": 7.5,
        "reduce-bean": 11.25,
    }
    owner = api.client.get("/v1/me", headers=headers).json()["id"]
    audit = cli("ai", "audit", "--user", owner)
    receipt = next(
        event for event in audit["modification_events"] if event["content"]["stage"] == "saved"
    )
    assert receipt["content"]["saved_version_id"] == saved["id"]
    assert receipt["content"]["intent"] == preview["intent"]
    assert {item["operation_id"]: item["decision"] for item in receipt["content"]["decisions"]} == {
        "reduce-salt": "modify",
        "reduce-soy": "reject",
        "reduce-oyster": "accept",
        "reduce-bean": "accept",
        "color-notes": "reject",
        "umami-why": "reject",
        "reduction-instruction": "reject",
    }
    assert receipt["content"]["decisions"][0]["after"] == 2.6
    version_event = next(
        event
        for event in audit["version_events"]
        if event["content"]["recipe_version_id"] == saved["id"]
    )
    assert version_event["content"]["edit_operations"] == saved["edit_operations"]
    unchanged_old(api, headers, created)


def import_substitution_library(directory):
    records = []
    for key, name, flavor, allergens in [
        ("wine_id", "料酒", {**ZERO, "umami": 1}, []),
        ("white_wine_id", SUB["white_wine_name"], {**ZERO, "sour": 1}, []),
        ("peanut_id", SUB["peanut_name"], {**ZERO, "salty": 1, "oily": 2}, ["花生"]),
    ]:
        records.append(
            _record(
                SUB[key],
                name,
                "ceshi",
                {
                    "base_unit": {"value": "毫升", **CHECKED},
                    "flavor": {"value": flavor, **CHECKED},
                    "allergens": {"value": allergens, **CHECKED},
                    "functional": {"value": False, **CHECKED},
                },
            )
        )
    records.append(_record(SUB["unknown_id"], "未完善资料调味汁", "weizhiao"))
    _write(directory / "library", "172.1.0", records)
    assert _import(directory / "library") == 0


def wine_recipe(*, functional=False, replacement="white_wine_id", same_name=False):
    body = recipe_input()
    wine = {
        "id": "wine",
        "ingredient_id": SUB["wine_id"],
        "display_name": "料酒",
        "quantity": 10,
        "unit": "ml",
        "functional": functional,
        "flavor_contribution": {**ZERO, "umami": 2},
        "preparation": "出锅前加入",
        "replacement": {
            "ingredient_id": SUB[replacement],
            "display_name": SUB["peanut_name"]
            if replacement == "peanut_id"
            else SUB["white_wine_name"],
            "ratio": 2,
            "note": "本菜谱作者登记1:2换算，适用于出锅前去腥",
        },
    }
    body["snapshot"]["ingredients"] = [wine]
    if same_name:
        body["snapshot"]["ingredients"].append(
            {
                **copy.deepcopy(wine),
                "id": "wine-marinate",
                "functional": True,
                "preparation": "腌制时使用",
            }
        )
    body["snapshot"]["steps"][0].update(
        ingredient_ids=["wine-marinate"] if same_name else [], instruction="准备碗和调料"
    )
    body["snapshot"]["steps"][1].update(ingredient_ids=["wine"], instruction="加入料酒，翻炒收汁")
    return body


def substitution_operations(snapshot, *, target="white_wine_id", amount=20):
    name = {
        "white_wine_id": SUB["white_wine_name"],
        "peanut_id": SUB["peanut_name"],
        "unknown_id": "未完善资料调味汁",
    }[target]
    flavor = {
        "white_wine_id": {**ZERO, "sour": 1},
        "peanut_id": {**ZERO, "salty": 1, "oily": 2},
        "unknown_id": None,
    }[target]
    changes = [
        {
            "operation_id": "replace-wine",
            "type": "replace_ingredient",
            "id": "wine",
            "field": "ingredient_id",
            "after": SUB[target],
        },
        {
            "operation_id": "name-wine",
            "type": "change_display_name",
            "id": "wine",
            "field": "display_name",
            "after": name,
            "depends_on": ["replace-wine"],
        },
        {
            "operation_id": "flavor-wine",
            "type": "change_flavor_contribution",
            "id": "wine",
            "field": "flavor_contribution",
            "after": flavor,
            "depends_on": ["replace-wine"],
        },
        {
            "operation_id": "relation-wine",
            "type": "change_replacement",
            "id": "wine",
            "field": "replacement",
            "after": {
                "ingredient_id": SUB[target],
                "display_name": name,
                "ratio": 2,
                "note": "由料酒10ml换算而来；本次替代比1:2，去腥和风味不等效",
            },
            "depends_on": ["replace-wine"],
        },
        {
            "operation_id": "quantity-wine",
            "type": "change_quantity",
            "id": "wine",
            "field": "quantity",
            "after": amount,
            "depends_on": ["replace-wine"],
        },
        {
            "operation_id": "replace-wine-instruction",
            "type": "change_step_field",
            "id": "cook",
            "field": "instruction",
            "after": f"加入{name}，翻炒收汁",
            "depends_on": ["replace-wine"],
        },
    ]
    return [
        edit(snapshot, change, intent="缺料替代", reason=SUB["reason"], risk=SUB["risk"])
        for change in changes
    ]


def test_replacement_requires_explicit_instruction_update(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe())
    baseline = created["version"]["snapshot"]
    operations = [
        op
        for op in substitution_operations(baseline)
        if op["operation_id"] != "replace-wine-instruction"
    ]
    preview = proposal(api, directory, headers, created, SUB["text"], SUB["intent"], operations)
    assert preview["error"] == "invalid_output", preview
    assert preview["operations"] == []
    assert preview["snapshot"] == baseline
    unchanged_old(api, headers, created)


@pytest.mark.parametrize(
    "same_name,intent",
    [
        (False, SUB["intent"]),
        (True, SUB["intent"]),
        (
            False,
            {
                "category": "substitution",
                "parameters": {"missing_ingredient": "料酒"},
                "confidence": 0.95,
            },
        ),
    ],
)
def test_registered_substitution_converts_only_requested_ingredient_and_saves_relation(
    modification_api, same_name, intent
):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe(same_name=same_name))
    baseline = created["version"]["snapshot"]
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["text"],
        intent,
        substitution_operations(baseline),
    )
    assert preview["error"] is None, preview
    assert preview["snapshot"] == baseline
    assert {op["id"] for op in preview["operations"]} == {"wine", "cook"}
    assert all(op["reason"] and op["risk"] for op in preview["operations"])
    selected = choice(api, headers, preview, accept_all(preview))
    target = selected["snapshot"]["ingredients"][0]
    assert target["ingredient_id"] == SUB["white_wine_id"]
    assert target["display_name"] == "白葡萄酒"
    assert target["quantity"] == 20 and target["unit"] == "ml" and target["base_quantity"] == 20
    assert target["flavor_contribution"] == {**ZERO, "sour": 1}
    assert target["replacement"]["ingredient_id"] == SUB["white_wine_id"]
    assert target["replacement"]["display_name"] == "白葡萄酒"
    assert target["replacement"]["ratio"] == 2
    assert target["functional"] == baseline["ingredients"][0]["functional"]
    assert target["functional_source"] == baseline["ingredients"][0]["functional_source"]
    assert selected["snapshot"]["steps"][0] == baseline["steps"][0]
    assert selected["snapshot"]["steps"][1]["instruction"] == "加入白葡萄酒，翻炒收汁"
    for field in ("ingredient_ids", "notes", "why", "duration_seconds"):
        assert selected["snapshot"]["steps"][1][field] == baseline["steps"][1][field]
    if same_name:
        assert selected["snapshot"]["ingredients"][1] == baseline["ingredients"][1]
    saved = confirm(api, headers, selected)
    assert saved["snapshot"] == selected["snapshot"]
    assert all(op["intent"] == "缺料替代" for op in saved["edit_operations"])
    owner = api.client.get("/v1/me", headers=headers).json()["id"]
    receipt = next(
        event
        for event in cli("ai", "audit", "--user", owner)["modification_events"]
        if event["content"]["stage"] == "saved"
    )
    assert receipt["content"]["saved_version_id"] == saved["id"]
    assert preview["intent"]["parameters"]["ingredient_id"] == "wine"
    assert receipt["content"]["intent"] == preview["intent"]
    assert all(item["decision"] == "accept" for item in receipt["content"]["decisions"])
    unchanged_old(api, headers, created)


def test_peanut_and_unknown_library_data_are_visible_in_actual_selected_safety(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe(replacement="peanut_id"))
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["peanut_text"],
        SUB["intent"],
        substitution_operations(created["version"]["snapshot"], target="peanut_id"),
    )
    assert preview["error"] is None, preview
    selected = choice(api, headers, preview, accept_all(preview))
    assert "花生" in selected["safety"]["allergens"]
    assert selected["safety"]["allergens_incomplete"] is False
    saved = confirm(api, headers, selected)
    assert "花生" in saved["safety"]["allergens"]
    unknown_body = wine_recipe()
    unknown_body["snapshot"]["ingredients"][0]["replacement"] = None
    other, _ = create(api, unknown_body, email="unknown-substitution@example.com")
    unknown_headers = bearer(api.login("unknown-substitution@example.com"))
    unknown = proposal(
        api,
        directory,
        unknown_headers,
        other,
        "没有料酒，换成未完善资料调味汁",
        SUB["intent"],
        substitution_operations(other["version"]["snapshot"], target="unknown_id"),
    )
    assert unknown["error"] is None, unknown
    unknown_selected = choice(api, unknown_headers, unknown, accept_all(unknown))
    assert unknown_selected["safety"]["allergens_incomplete"] is True
    assert unknown_selected["snapshot"]["ingredients"][0]["flavor_contribution"] is None
    assert unknown_selected["warnings"] or any(op["risk"] for op in unknown_selected["operations"])


def test_substitution_does_not_override_author_functional_mark_from_library(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe(functional=True))
    baseline = created["version"]["snapshot"]
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["text"],
        SUB["intent"],
        substitution_operations(baseline),
    )
    assert preview["error"] is None, preview
    assert any("功能" in op["risk"] for op in preview["operations"])
    selected = choice(api, headers, preview, accept_all(preview))
    item = selected["snapshot"]["ingredients"][0]
    assert item["functional"] is True
    assert item["functional_source"] == baseline["ingredients"][0]["functional_source"]
    saved = confirm(api, headers, selected)
    assert saved["snapshot"]["ingredients"][0]["functional"] is True
    assert saved["snapshot"]["ingredients"][0]["functional_source"] == item["functional_source"]


@pytest.mark.parametrize(
    "rejected", ["name-wine", "flavor-wine", "relation-wine", "replace-wine-instruction"]
)
def test_replacement_cannot_save_stale_rejected_companion_facts(modification_api, rejected):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe())
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["text"],
        SUB["intent"],
        substitution_operations(created["version"]["snapshot"]),
    )
    assert preview["error"] is None, preview
    decisions = accept_all(preview)
    next(item for item in decisions if item["operation_id"] == rejected)["decision"] = "reject"
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/decisions",
        headers=headers,
        json={"decisions": decisions},
    )
    assert response.status_code == 422, response.text
    retained = api.client.get(
        f"/v1/ai/recipes/modifications/{preview['id']}", headers=headers
    ).json()
    assert retained["snapshot"] == created["version"]["snapshot"]
    assert retained["revision"] == preview["revision"]
    rejected_all = choice(
        api,
        headers,
        preview,
        [
            {
                "operation_id": op["operation_id"],
                "decision": "reject" if op["operation_id"] == "replace-wine" else "accept",
            }
            for op in preview["operations"]
        ],
    )
    assert rejected_all["snapshot"] == created["version"]["snapshot"]
    assert all(item["decision"] == "reject" for item in rejected_all["decisions"])


@pytest.mark.parametrize("author_edit", [False, True])
def test_replacement_instruction_can_explain_original_ingredient(modification_api, author_edit):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe())
    baseline = created["version"]["snapshot"]
    instruction = "加入20ml白葡萄酒（替代原来的10ml料酒），翻炒收汁。"
    operations = substitution_operations(baseline)
    if not author_edit:
        next(op for op in operations if op["field"] == "instruction")["after"] = instruction
    preview = proposal(api, directory, headers, created, SUB["text"], SUB["intent"], operations)
    assert preview["error"] is None, preview
    decisions = accept_all(preview)
    if author_edit:
        next(
            item for item in decisions if item["operation_id"] == "replace-wine-instruction"
        ).update(decision="modify", after=instruction)
    selected = choice(api, headers, preview, decisions)
    assert selected["snapshot"]["steps"][1]["instruction"] == instruction
    saved = confirm(api, headers, selected)
    assert saved["snapshot"] == selected["snapshot"]
    assert saved["snapshot"]["ingredients"][0]["display_name"] == SUB["white_wine_name"]
    unchanged_old(api, headers, created)


def test_replacement_instruction_cannot_be_modified_back_to_baseline(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe())
    baseline = created["version"]["snapshot"]
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["text"],
        SUB["intent"],
        substitution_operations(baseline),
    )
    assert preview["error"] is None, preview
    decisions = accept_all(preview)
    next(item for item in decisions if item["operation_id"] == "replace-wine-instruction").update(
        decision="modify", after=baseline["steps"][1]["instruction"]
    )
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/decisions",
        headers=headers,
        json={"decisions": decisions},
    )
    assert response.status_code == 422, response.text
    retained = api.client.get(
        f"/v1/ai/recipes/modifications/{preview['id']}", headers=headers
    ).json()
    assert retained["snapshot"] == baseline
    assert retained["revision"] == preview["revision"]
    unchanged_old(api, headers, created)


@pytest.mark.parametrize("selection", ["accept", "reject_cleanup", "reject_deletion"])
def test_no_substitute_requires_explicit_deletion_and_reference_cleanup(
    modification_api, selection
):
    api, directory = modification_api
    import_substitution_library(directory)
    body = wine_recipe()
    body["snapshot"]["ingredients"][0]["replacement"] = None
    created, headers = create(api, body)
    baseline = created["version"]["snapshot"]
    operations = [
        edit(baseline, change, intent="缺料省略", reason=SUB["omit_reason"], risk=SUB["omit_risk"])
        for change in [
            {
                "operation_id": "clean-wine-reference",
                "type": "change_step_ingredients",
                "id": "cook",
                "field": "ingredient_ids",
                "after": [],
            },
            {
                "operation_id": "omit-wine-instruction",
                "type": "change_step_field",
                "id": "cook",
                "field": "instruction",
                "after": "保持原火候翻炒收汁；省略料酒会减弱去腥和香气",
            },
            {
                "operation_id": "remove-wine",
                "type": "remove_ingredient",
                "id": "wine",
                "field": "ingredients",
                "after": None,
                "depends_on": ["clean-wine-reference", "omit-wine-instruction"],
            },
        ]
    ]
    preview = proposal(
        api, directory, headers, created, SUB["omit_text"], SUB["intent"], operations
    )
    assert preview["error"] is None, preview
    assert preview["snapshot"] == baseline
    assert "省略" in preview["operations"][1]["reason"]
    selected = choice(
        api,
        headers,
        preview,
        [
            {
                "operation_id": "clean-wine-reference",
                "decision": "reject" if selection == "reject_cleanup" else "accept",
            },
            {"operation_id": "omit-wine-instruction", "decision": "accept"},
            {
                "operation_id": "remove-wine",
                "decision": "reject" if selection == "reject_deletion" else "accept",
            },
        ],
    )
    if selection == "accept":
        assert selected["snapshot"]["ingredients"] == []
        assert selected["snapshot"]["steps"][1]["ingredient_ids"] == []
        assert selected["snapshot"]["steps"][0] == baseline["steps"][0]
        assert (
            selected["snapshot"]["steps"][1]["instruction"]
            == "保持原火候翻炒收汁；省略料酒会减弱去腥和香气"
        )
        for field in ("notes", "why", "duration_seconds"):
            assert selected["snapshot"]["steps"][1][field] == baseline["steps"][1][field]
        saved = confirm(api, headers, selected)
        assert saved["snapshot"] == selected["snapshot"]
        assert {op["operation_id"] for op in saved["edit_operations"]} == {
            "clean-wine-reference",
            "omit-wine-instruction",
            "remove-wine",
        }
        assert all(op["intent"] == "缺料省略" for op in saved["edit_operations"])
    else:
        deletion = next(
            item for item in selected["decisions"] if item["operation_id"] == "remove-wine"
        )
        assert deletion["decision"] == "reject"
        if selection == "reject_cleanup":
            assert deletion["blocked_by"] == ["clean-wine-reference"]
        assert selected["snapshot"] == baseline
        assert all(item["decision"] == "reject" for item in selected["decisions"])
        response = api.client.post(
            f"/v1/ai/recipes/modifications/{preview['id']}/confirm",
            headers=headers,
            json={"revision": selected["revision"]},
        )
        assert (
            response.status_code == 409 and response.json()["error"]["code"] == "no_modifications"
        )
    unchanged_old(api, headers, created)


def test_taste_base_units_preserve_author_display_units(modification_api):
    api, directory = modification_api
    body = taste_recipe()
    body["snapshot"]["ingredients"][1].update(quantity=0.003, unit="kg")
    body["snapshot"]["ingredients"][2].update(quantity=0.015, unit="l")
    created, headers = create(api, body)
    expected = {"salt": 0.00225, "soy": 0.01125, "oyster": 7.5, "bean": 11.25}
    preview = proposal(
        api,
        directory,
        headers,
        created,
        TASTE["text"],
        TASTE["intent"],
        taste_operations(created["version"]["snapshot"], expected),
        amounts=expected,
    )
    assert preview["error"] is None, preview
    selected = choice(api, headers, preview, accept_all(preview))
    items = {item["id"]: item for item in selected["snapshot"]["ingredients"]}
    assert items["salt"]["quantity"] == 0.00225 and items["salt"]["unit"] == "kg"
    assert items["salt"]["base_quantity"] == 2.25
    assert items["soy"]["quantity"] == 0.01125 and items["soy"]["unit"] == "l"
    assert items["soy"]["base_quantity"] == 11.25


def test_model_only_reducing_salt_is_rejected_without_partial_recipe_write(modification_api):
    api, directory = modification_api
    created, headers = create(api, taste_recipe())
    expected = {"salt": 2.25, "soy": 11.25, "oyster": 7.5, "bean": 11.25}
    preview = proposal(
        api,
        directory,
        headers,
        created,
        TASTE["text"],
        TASTE["intent"],
        taste_operations(created["version"]["snapshot"], {"salt": 2.25}, sides=False),
        amounts=expected,
    )
    assert preview["error"] == "invalid_output", preview
    assert preview["operations"] == []
    assert preview["snapshot"] == created["version"]["snapshot"]
    unchanged_old(api, headers, created)


def test_modified_replacement_identity_requires_new_corresponding_facts(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe())
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["text"],
        SUB["intent"],
        substitution_operations(created["version"]["snapshot"]),
    )
    assert preview["error"] is None, preview
    decisions = accept_all(preview)
    decisions[0].update(decision="modify", after=SUB["peanut_id"])
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/decisions",
        headers=headers,
        json={"decisions": decisions},
    )
    assert response.status_code == 422, response.text
    retained = api.client.get(
        f"/v1/ai/recipes/modifications/{preview['id']}", headers=headers
    ).json()
    assert retained["revision"] == preview["revision"]
    assert retained["snapshot"] == created["version"]["snapshot"]


def test_author_modified_substitution_amount_is_preserved_in_version_and_event(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    created, headers = create(api, wine_recipe())
    preview = proposal(
        api,
        directory,
        headers,
        created,
        SUB["text"],
        SUB["intent"],
        substitution_operations(created["version"]["snapshot"]),
    )
    assert preview["error"] is None, preview
    decisions = accept_all(preview)
    next(item for item in decisions if item["operation_id"] == "quantity-wine").update(
        decision="modify", after=18
    )
    selected = choice(api, headers, preview, decisions)
    target = selected["snapshot"]["ingredients"][0]
    assert target["quantity"] == 18 and target["quantity_source"]["source"] == "author_filled"
    assert target["replacement"]["ratio"] == 2
    assert any("登记" in warning and "作者" in warning for warning in selected["warnings"])
    saved = confirm(api, headers, selected)
    assert saved["snapshot"] == selected["snapshot"]
    quantity = next(op for op in saved["edit_operations"] if op["operation_id"] == "quantity-wine")
    assert quantity["before"] == 10 and quantity["after"] == 18 and quantity["decision"] == "modify"
    identity = next(op for op in saved["edit_operations"] if op["operation_id"] == "replace-wine")
    assert identity["before"] == SUB["wine_id"] and identity["after"] == SUB["white_wine_id"]
    owner = api.client.get("/v1/me", headers=headers).json()["id"]
    receipt = next(
        event
        for event in cli("ai", "audit", "--user", owner)["modification_events"]
        if event["content"]["stage"] == "saved"
    )
    recorded_quantity = next(
        item for item in receipt["content"]["decisions"] if item["operation_id"] == "quantity-wine"
    )
    assert recorded_quantity["decision"] == "modify" and recorded_quantity["after"] == 18
    unchanged_old(api, headers, created)


def test_replacement_with_same_registered_flavor_needs_no_noop_operation(modification_api):
    api, directory = modification_api
    import_substitution_library(directory)
    body = wine_recipe()
    body["snapshot"]["ingredients"][0]["flavor_contribution"] = {**ZERO, "sour": 1}
    created, headers = create(api, body)
    baseline = created["version"]["snapshot"]
    operations = [
        op for op in substitution_operations(baseline) if op["operation_id"] != "flavor-wine"
    ]
    preview = proposal(api, directory, headers, created, SUB["text"], SUB["intent"], operations)
    assert preview["error"] is None, preview
    assert {op["operation_id"] for op in preview["operations"]} == {
        "replace-wine",
        "name-wine",
        "relation-wine",
        "quantity-wine",
        "replace-wine-instruction",
    }
    selected = choice(api, headers, preview, accept_all(preview))
    target = selected["snapshot"]["ingredients"][0]
    assert target["ingredient_id"] == SUB["white_wine_id"] and target["quantity"] == 20
    assert target["flavor_contribution"] == baseline["ingredients"][0]["flavor_contribution"]
    saved = confirm(api, headers, selected)
    assert saved["snapshot"] == selected["snapshot"]
    assert len(saved["edit_operations"]) == 5
    unchanged_old(api, headers, created)
