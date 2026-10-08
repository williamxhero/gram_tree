"""Time, difficulty and structural edits only through owned HTTP boundaries."""

import copy
import json
from pathlib import Path

import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import cli
from tests.test_cookware_modifications import recorded_proposal
from tests.test_recipe_modifications import choice
from tests.test_recipes import recipe_input

CORPUS = json.loads(
    Path(__file__)
    .with_name("fixtures")
    .joinpath("ai/method_modification_corpus.json")
    .read_text("utf-8")
)


@pytest.fixture
def method_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def method_api(method_recordings, api):
    return api, method_recordings


def setup(api, email):
    headers = bearer(api.login(email))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    return response.json(), headers


def method_operations(snapshot, case):
    operations = []
    for change in CORPUS[case]["changes"]:
        collection = "ingredients" if "ingredient" in change["type"] else "steps"
        node = next((n for n in snapshot[collection] if n["id"] == change["id"]), None)
        if change["type"].startswith("add_"):
            before = None
        elif change["type"].startswith("remove_"):
            before = node
        elif change["type"].startswith("reorder_"):
            before = [n["id"] for n in snapshot[collection]]
        elif change["type"] == "change_recipe_info":
            before = snapshot[change["field"]]
        else:
            assert node is not None, change
            before = node[change["field"]]
        operations.append(
            {
                "before": before,
                "scope": [collection],
                "intent": "缩短时间" if case == "time" else "降低难度并调整做法",
                "reason": CORPUS["reason"],
                "risk": CORPUS["risk"],
                "confidence": 0.8,
                **change,
            }
        )
    return operations


def propose_method(api, directory, headers, created, case="time", operations=None):
    return recorded_proposal(
        api,
        directory,
        headers,
        created,
        CORPUS[case]["text"],
        CORPUS[case]["intent"],
        {
            "operations": operations
            if operations is not None
            else method_operations(created["version"]["snapshot"], case)
        },
    )


def accept_all(proposal):
    return [
        {"operation_id": op["operation_id"], "decision": "accept"} for op in proposal["operations"]
    ]


def confirm(api, headers, preview):
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/confirm",
        headers=headers,
        json={"revision": preview["revision"]},
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_faster_steps_rederive_time_warn_and_save_only_author_selected_values(method_api):
    api, directory = method_api
    created, headers = setup(api, "faster-method@example.com")
    proposal = propose_method(api, directory, headers, created)
    assert proposal["error"] is None, proposal
    preview = choice(api, headers, proposal, accept_all(proposal))
    assert preview["snapshot"]["steps"][1]["duration_seconds"] == 30
    assert preview["safety"]["findings"]
    decisions = accept_all(proposal)
    decisions[0] = {
        "operation_id": "quick-instruction",
        "decision": "modify",
        "after": "加入适量调料，中火炒至鸡肉中心达到74°C",
    }
    decisions[1] = {"operation_id": "quick-duration", "decision": "modify", "after": 90}
    decisions[2]["decision"] = "reject"
    preview = choice(api, headers, proposal, decisions)
    assert (
        preview["snapshot"]["steps"][1]["doneness"]
        == created["version"]["snapshot"]["steps"][1]["doneness"]
    )
    assert preview["reproducibility"]["problems"]
    saved = confirm(api, headers, preview)["version"]
    assert saved["derived"]["total_time_seconds"] == 990
    assert saved["derived"]["active_time_seconds"] == 90
    assert saved["snapshot"]["steps"][0] == created["version"]["snapshot"]["steps"][0]
    assert {op["operation_id"] for op in saved["edit_operations"]} == {
        "quick-instruction",
        "quick-duration",
    }
    assert saved["snapshot"]["steps"][1]["duration_source"]["source"] == "author_filled"
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    ).json()
    assert old["version"] == created["version"]
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    event = next(
        e
        for e in cli("ai", "audit", "--user", user_id)["modification_events"]
        if e["content"]["stage"] == "saved"
    )
    assert event["content"]["intent"]["category"] == "time_difficulty"
    assert event["content"]["saved_version_id"] == saved["id"]


def test_simpler_method_add_remove_reorder_keep_reference_and_immutable_history(method_api):
    api, directory = method_api
    created, headers = setup(api, "simpler-method@example.com")
    proposal = propose_method(api, directory, headers, created, "difficulty")
    assert proposal["error"] is None, proposal
    # Dependency order, not model list order, governs structural application.
    preview = choice(api, headers, proposal, accept_all(proposal))
    assert [s["id"] for s in preview["snapshot"]["steps"]] == ["cook", "serve"]
    assert preview["snapshot"]["steps"][0]["depends_on"] == []
    assert preview["snapshot"]["steps"][1]["depends_on"] == ["cook"]
    assert preview["snapshot"]["difficulty"] == "简单"
    assert preview["snapshot"]["ingredients"] == created["version"]["snapshot"]["ingredients"]
    decisions = accept_all(proposal)
    decisions[0]["decision"] = "reject"
    rejected = choice(api, headers, proposal, decisions)
    assert rejected["snapshot"] == created["version"]["snapshot"]
    assert all(d["decision"] == "reject" for d in rejected["decisions"])
    preview = choice(api, headers, proposal, accept_all(proposal))
    saved = confirm(api, headers, preview)["version"]
    assert saved["derived"]["total_time_seconds"] == 150
    assert saved["derived"]["active_time_seconds"] == 150
    assert saved["snapshot"]["steps"] == preview["snapshot"]["steps"]
    assert {op["type"] for op in saved["edit_operations"]} == {
        "change_step_field",
        "change_step_dependencies",
        "remove_step",
        "add_step",
        "reorder_steps",
        "change_recipe_info",
    }
    current = api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()
    assert current["version"] == saved
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    ).json()
    assert old["version"] == created["version"]


def edit(snapshot, operation_id, kind, item_id, field, after, depends_on=None):
    collection = (
        "ingredients"
        if ("ingredient" in kind and "step" not in kind)
        or kind in ("change_preparation", "change_group_or_optional", "change_replacement")
        else "steps"
    )
    if kind.startswith("add_"):
        before = None
    elif kind.startswith("reorder_"):
        before = [item["id"] for item in snapshot[collection]]
    elif kind == "change_recipe_info":
        before = snapshot[field]
    else:
        item = next(item for item in snapshot[collection] if item["id"] == item_id)
        before = item if kind.startswith("remove_") else item[field]
    return {
        "operation_id": operation_id,
        "type": kind,
        "id": item_id,
        "field": field,
        "before": before,
        "after": after,
        "scope": [collection],
        "intent": "调整做法",
        "reason": CORPUS["reason"],
        "risk": CORPUS["risk"],
        "confidence": 0.8,
        "depends_on": depends_on or [],
    }


def test_ingredient_add_remove_refs_and_group_preparation_save_canonical_nodes(method_api):
    api, directory = method_api
    created, headers = setup(api, "method-ingredients@example.com")
    snapshot = created["version"]["snapshot"]
    ops = [
        edit(
            snapshot,
            "garlic",
            "add_ingredient",
            "garlic",
            "ingredients",
            {"id": "garlic", "display_name": "  蒜  ", "quantity": 10, "unit": "g"},
        ),
        edit(
            snapshot,
            "refs",
            "change_step_ingredients",
            "cook",
            "ingredient_ids",
            ["chicken", "garlic"],
            ["garlic"],
        ),
        edit(
            snapshot, "remove-pepper", "remove_ingredient", "pepper", "ingredients", None, ["refs"]
        ),
        edit(
            snapshot,
            "order-ingredients",
            "reorder_ingredients",
            None,
            "ingredients",
            ["garlic", "chicken"],
            ["garlic", "remove-pepper"],
        ),
        edit(snapshot, "preparation", "change_preparation", "chicken", "preparation", "切2厘米丁"),
        edit(snapshot, "group", "change_group_or_optional", "chicken", "group", "肉类"),
        edit(snapshot, "optional", "change_group_or_optional", "chicken", "optional", True),
    ]
    # A valid proposal must apply even if dependent operations appear first.
    proposal = propose_method(api, directory, headers, created, "difficulty", list(reversed(ops)))
    assert proposal["error"] is None, proposal
    preview = choice(api, headers, proposal, accept_all(proposal))
    garlic = preview["snapshot"]["ingredients"][0]
    assert garlic["display_name"] == "蒜"
    assert garlic["base_quantity"] == 10
    assert garlic["base_unit"] == "g"
    assert garlic["quantity_source"]["source"] == "ai_estimated"
    assert preview["snapshot"]["steps"][1]["ingredient_ids"] == ["chicken", "garlic"]
    saved = confirm(api, headers, preview)["version"]
    node_op = next(op for op in saved["edit_operations"] if op["operation_id"] == "garlic")
    assert node_op["after"] == saved["snapshot"]["ingredients"][0] == garlic
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    event = next(
        e
        for e in cli("ai", "audit", "--user", user_id)["modification_events"]
        if e["content"]["stage"] == "saved"
    )
    decision = next(d for d in event["content"]["decisions"] if d["operation_id"] == "garlic")
    assert decision["after"] == garlic


@pytest.mark.parametrize(
    "invalid",
    [
        "missing_cleanup_dependency",
        "duplicate_order",
        "dangling_order",
        "dangling_reference",
        "step_cycle",
        "operation_cycle",
        "id_change",
        "verified_source",
        "unknown_kind",
        "fabricated_total",
        "missing_time_dependency",
    ],
)
def test_invalid_method_operations_fail_repair_without_writing_base(method_api, invalid):
    api, directory = method_api
    created, headers = setup(api, f"method-invalid-{invalid}@example.com")
    snapshot = created["version"]["snapshot"]
    ops = copy.deepcopy(method_operations(snapshot, "difficulty"))
    if invalid == "missing_cleanup_dependency":
        ops[2]["depends_on"] = []
    elif invalid == "duplicate_order":
        ops[4]["after"] = ["cook", "cook", "serve"]
    elif invalid == "dangling_order":
        ops[4]["after"] = ["cook", "unknown"]
    elif invalid == "dangling_reference":
        ops[3]["after"]["ingredient_ids"] = ["unknown"]
    elif invalid == "step_cycle":
        ops[3]["after"]["depends_on"] = ["serve"]
    elif invalid == "operation_cycle":
        ops[0]["depends_on"] = ["remove-marinate"]
    elif invalid == "id_change":
        ops[3]["after"]["id"] = "different"
    elif invalid == "verified_source":
        ops[3]["after"]["instruction_source"] = {"source": "verified", "evidence_id": "invented"}
    elif invalid == "unknown_kind":
        ops[0]["type"] = "rewrite_recipe"
    elif invalid == "missing_time_dependency":
        ops = method_operations(snapshot, "time")
        ops[1]["depends_on"] = []
    else:
        ops.append(edit(snapshot, "total", "change_recipe_info", None, "total_time_seconds", 1))
    proposal = propose_method(
        api,
        directory,
        headers,
        created,
        "time" if invalid == "missing_time_dependency" else "difficulty",
        ops,
    )
    assert proposal["error"] == "invalid_output", proposal
    assert proposal["operations"] == []
    assert proposal["snapshot"] == snapshot
    assert (
        api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()["version"]
        == created["version"]
    )


def test_modified_structural_values_recheck_and_invalid_changes_keep_prior_preview(method_api):
    api, directory = method_api
    created, headers = setup(api, "method-user-structural@example.com")
    proposal = propose_method(api, directory, headers, created, "difficulty")
    assert proposal["error"] is None, proposal
    decisions = accept_all(proposal)
    preview = choice(api, headers, proposal, decisions)
    serve = next(op for op in proposal["operations"] if op["operation_id"] == "serve")
    bad_after = copy.deepcopy(serve["after"])
    bad_after["ingredient_ids"] = ["missing"]
    decisions[3] = {"operation_id": "serve", "decision": "modify", "after": bad_after}
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{proposal['id']}/decisions",
        headers=headers,
        json={"decisions": decisions},
    )
    assert response.status_code == 422
    retained = api.client.get(
        f"/v1/ai/recipes/modifications/{proposal['id']}", headers=headers
    ).json()
    assert retained["revision"] == preview["revision"]
    assert retained["snapshot"] == preview["snapshot"]
    good_after = copy.deepcopy(serve["after"])
    good_after["instruction"] = "加入适量调料后装盘"
    decisions[3]["after"] = good_after
    selected = choice(api, headers, proposal, decisions)
    assert any(p["position"]["item_id"] == "serve" for p in selected["reproducibility"]["problems"])
    saved = confirm(api, headers, selected)["version"]
    new_step = next(step for step in saved["snapshot"]["steps"] if step["id"] == "serve")
    assert new_step["instruction"] == "加入适量调料后装盘"
    assert new_step["instruction_source"]["source"] == "author_filled"
    op = next(op for op in saved["edit_operations"] if op["operation_id"] == "serve")
    assert op["after"] == new_step


@pytest.mark.parametrize("category", ["method", "time_difficulty"])
def test_unattainable_method_or_time_has_explicit_reason_and_no_write(method_api, category):
    api, directory = method_api
    created, headers = setup(api, f"method-noop-{category}@example.com")
    output = {"operations": [], "explanation": "缺少肉块厚度，不能安全承诺加快，请补充信息"}
    proposal = recorded_proposal(
        api,
        directory,
        headers,
        created,
        "能不能一分钟做好",
        {"category": category, "parameters": {"goal": "faster"}, "confidence": 0.9},
        output,
    )
    assert proposal["error"] == "cannot_modify"
    assert proposal["operations"] == []
    assert proposal["warnings"] == [output["explanation"]]
    assert proposal["snapshot"] == created["version"]["snapshot"]


def test_nested_replacement_is_canonical_json_through_preview_receipt_and_audit(method_api):
    api, directory = method_api
    created, headers = setup(api, "method-nested-replacement@example.com")
    snapshot = created["version"]["snapshot"]
    replacement = {"display_name": "火鸡肉", "ratio": 1, "note": "厚度一致并检查中心温度"}
    operation = edit(
        snapshot, "replacement", "change_replacement", "chicken", "replacement", replacement
    )
    proposal = propose_method(api, directory, headers, created, "difficulty", [operation])
    assert proposal["error"] is None, proposal
    preview = choice(api, headers, proposal, accept_all(proposal))
    canonical = {"ingredient_id": None, **replacement}
    assert preview["snapshot"]["ingredients"][0]["replacement"] == canonical
    assert preview["decisions"][0]["after"] == canonical
    saved = confirm(api, headers, preview)["version"]
    assert saved["edit_operations"][0]["after"] == canonical
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    event = next(
        e
        for e in cli("ai", "audit", "--user", user_id)["modification_events"]
        if e["content"]["stage"] == "saved"
    )
    assert event["content"]["decisions"][0]["after"] == canonical
