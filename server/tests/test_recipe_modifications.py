"""Natural-language edits at the owned HTTP boundary, using recorded answers only."""

import copy
import uuid
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import (
    CORPUS,
    begin,
    cli,
    configure,
    generate,
    generation_payload,
    recording,
)
from tests.test_ai_recipes import TEXT as GENERATION_TEXT
from tests.test_recipes import recipe_input

TEXT = "把第一步说明写清楚"
INTENT = {"category": "text", "parameters": {"target": "步骤说明"}, "confidence": 0.95}


@pytest.fixture
def modification_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def modification_api(modification_recordings, api):
    return api, modification_recordings


def operation(snapshot, **changes):
    return {
        "operation_id": "wording-1",
        "type": "change_step_field",
        "id": snapshot["steps"][0]["id"],
        "field": "instruction",
        "before": snapshot["steps"][0]["instruction"],
        "after": "将鸡肉切成 2 厘米块，放入碗中",
        "scope": ["steps"],
        "intent": "说明鸡肉处理方式",
        "reason": "把原有处理动作写清楚",
        "risk": "仍需按后续步骤充分加热",
        "confidence": 0.9,
        "depends_on": [],
        **changes,
    }


def propose(api, directory, headers, detail, *, operations=None, extra=None):
    snapshot = detail["version"]["snapshot"]
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    payload = {"text": TEXT, "snapshot": snapshot, "intent": INTENT}
    recording(
        directory,
        "modify",
        payload,
        {"operations": operations or [operation(snapshot)], **(extra or {})},
    )
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={"text": TEXT, "recipe_id": detail["id"], "base_version_id": detail["version"]["id"]},
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_text_preview_confirm_keeps_old_version_and_operation_intent(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("text-owner@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    preview = propose(api, directory, headers, created)
    assert preview["error"] is None, preview
    assert preview["decisions"][0]["decision"] == "pending"
    assert preview["snapshot"] == created["version"]["snapshot"]
    checked = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/decisions",
        headers=headers,
        json={"decisions": [{"operation_id": "wording-1", "decision": "accept"}]},
    )
    assert checked.status_code == 200, checked.text
    preview = checked.json()
    assert preview["snapshot"]["steps"][0]["instruction"] == "将鸡肉切成 2 厘米块，放入碗中"
    assert preview["safety"] and preview["reproducibility"]
    current = api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()
    assert current["version"]["id"] == created["version"]["id"]
    route = f"/v1/ai/recipes/modifications/{preview['id']}/confirm"
    response = api.client.post(route, headers=headers, json={"revision": preview["revision"]})
    assert response.status_code == 201, response.text
    saved = response.json()
    assert saved["version"]["ai_assisted"] is True
    assert saved["version"]["edit_operations"][0]["intent"] == "说明鸡肉处理方式"
    assert saved["version"]["edit_operations"][0]["type"] == "change_step_field"
    assert (
        saved["version"]["snapshot"]["steps"][0]["instruction_source"]["source"] == "ai_estimated"
    )
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    ).json()
    assert old["version"] == created["version"]
    assert (
        api.client.post(route, headers=headers, json={"revision": preview["revision"]}).json()[
            "version"
        ]["id"]
        == saved["version"]["id"]
    )


def choice(api, headers, preview, decisions):
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/decisions",
        headers=headers,
        json={"decisions": decisions},
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_pending_rejection_dependencies_and_modified_value_recheck(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("text-decisions@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    snapshot = created["version"]["snapshot"]
    first = operation(snapshot)
    dependent = operation(
        snapshot,
        operation_id="note",
        field="notes",
        before=snapshot["steps"][0]["notes"],
        after="按步骤说明处理",
        depends_on=["wording-1"],
        intent="跟随步骤说明补充提醒",
    )
    independent = operation(
        snapshot,
        operation_id="why",
        field="why",
        before=snapshot["steps"][0]["why"],
        after="让原有动作更容易理解",
        intent="说明处理原因",
    )
    preview = propose(api, directory, headers, created, operations=[first, dependent, independent])
    route = f"/v1/ai/recipes/modifications/{preview['id']}/confirm"
    pending = api.client.post(route, headers=headers, json={"revision": 0})
    assert (
        pending.status_code == 409
        and pending.json()["error"]["code"] == "modification_decisions_required"
    )
    # A dependent rejection does not require accepting its prerequisite.
    rejected = choice(api, headers, preview, [{"operation_id": "note", "decision": "reject"}])
    assert rejected["decisions"][1]["decision"] == "reject"
    assert rejected["snapshot"] == snapshot
    # A dependent accept cannot apply while its prerequisite is untouched.
    selected = choice(api, headers, preview, [{"operation_id": "note", "decision": "accept"}])
    assert selected["decisions"][1]["decision"] == "pending"
    assert selected["snapshot"] == snapshot
    selected = choice(
        api,
        headers,
        selected,
        [
            {"operation_id": "wording-1", "decision": "reject"},
            {"operation_id": "why", "decision": "modify", "after": "加入适量调料"},
        ],
    )
    assert selected["decisions"][1]["decision"] == "reject"
    assert selected["decisions"][1]["blocked_by"] == ["wording-1"]
    assert selected["snapshot"]["steps"][0]["instruction"] == snapshot["steps"][0]["instruction"]
    assert selected["snapshot"]["steps"][0]["notes"] == snapshot["steps"][0]["notes"]
    assert selected["snapshot"]["ingredients"] == snapshot["ingredients"]
    # Actual user-modified values determine checks, not the original AI candidate.
    selected = choice(
        api,
        headers,
        selected,
        [
            {"operation_id": "wording-1", "decision": "modify", "after": "加入适量调料"},
            {"operation_id": "note", "decision": "reject"},
            {"operation_id": "why", "decision": "reject"},
        ],
    )
    assert any(
        p["position"]["field"] == "instruction" for p in selected["reproducibility"]["problems"]
    )
    stale = api.client.post(route, headers=headers, json={"revision": selected["revision"] - 1})
    assert stale.status_code == 409
    saved = api.client.post(route, headers=headers, json={"revision": selected["revision"]})
    assert saved.status_code == 201, saved.text
    version = saved.json()["version"]
    assert version["snapshot"]["steps"][0]["instruction_source"]["source"] == "author_filled"
    assert version["reproducibility"]["state"] == "incomplete"
    assert len(version["edit_operations"]) == 1
    assert version["edit_operations"][0]["intent"] == first["intent"]
    assert version["edit_operations"][0]["after"] == "加入适量调料"
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    audit = cli("ai", "audit", "--user", user_id)
    saved_event = [e for e in audit["modification_events"] if e["content"]["stage"] == "saved"]
    assert len(saved_event) == 1
    receipt = saved_event[0]
    assert receipt["content"]["saved_version_id"] == version["id"]
    assert receipt["correlation"]["recipe_version_id"] == version["id"]
    assert {d["operation_id"]: d["decision"] for d in receipt["content"]["decisions"]} == {
        "wording-1": "modify",
        "note": "reject",
        "why": "reject",
    }
    assert receipt["content"]["decisions"][0]["after"] == "加入适量调料"
    correlated = [
        e for e in audit["version_events"] if e["content"]["recipe_version_id"] == version["id"]
    ]
    assert (
        len(correlated) == 1
        and correlated[0]["content"]["edit_operations"] == version["edit_operations"]
    )
    assert TEXT not in str(audit["modification_events"])
    retry = api.client.post(route, headers=headers, json={"revision": selected["revision"]})
    assert retry.status_code == 201
    assert len(cli("ai", "audit", "--user", user_id)["modification_events"]) == len(
        audit["modification_events"]
    )


@pytest.mark.parametrize("decision", ["accept", "modify"])
def test_canonical_selected_display_name_matches_version_and_event_audit(
    modification_api, decision
):
    api, directory = modification_api
    headers = bearer(api.login(f"text-canonical-{decision}@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    item = created["version"]["snapshot"]["ingredients"][0]
    op = operation(
        created["version"]["snapshot"],
        type="change_display_name",
        id=item["id"],
        field="display_name",
        before=item["display_name"],
        after="  Poultry  ",
        scope=["ingredients"],
        intent="把食材标签写清楚",
    )
    preview = propose(api, directory, headers, created, operations=[op])
    assert preview["operations"][0]["after"] == "Poultry"
    selected = choice(
        api,
        headers,
        preview,
        [
            {
                "operation_id": op["operation_id"],
                "decision": decision,
                **({"after": "  Poultry  "} if decision == "modify" else {}),
            }
        ],
    )
    assert selected["snapshot"]["ingredients"][0]["display_name"] == "Poultry"
    assert selected["decisions"][0]["after"] == "Poultry"
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert response.status_code == 201, response.text
    version = response.json()["version"]
    assert version["snapshot"]["ingredients"][0]["display_name"] == "Poultry"
    assert version["edit_operations"][0]["after"] == "Poultry"
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    audit = cli("ai", "audit", "--user", user_id)
    saved_event = [e for e in audit["modification_events"] if e["content"]["stage"] == "saved"]
    assert saved_event[0]["content"]["decisions"][0]["after"] == "Poultry"
    version_event = [
        e for e in audit["version_events"] if e["content"]["recipe_version_id"] == version["id"]
    ]
    assert version_event[0]["content"]["edit_operations"][0]["after"] == "Poultry"


def test_concurrent_proposal_retries_reserve_one_owned_receipt(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("text-concurrent@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    snapshot = created["version"]["snapshot"]
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    recording(
        directory,
        "modify",
        {"text": TEXT, "snapshot": snapshot, "intent": INTENT},
        {"operations": [operation(snapshot)]},
    )
    request_id = str(uuid.uuid4())
    body = {
        "request_id": request_id,
        "text": TEXT,
        "recipe_id": created["id"],
        "base_version_id": created["version"]["id"],
    }
    gate = Barrier(16)

    def retry():
        gate.wait(timeout=30)
        return api.client.post("/v1/ai/recipes/modifications", headers=headers, json=body)

    with ThreadPoolExecutor(max_workers=16) as pool:
        responses = list(pool.map(lambda _: retry(), range(16)))
    assert all(r.status_code == 200 for r in responses), [r.text for r in responses]
    assert {r.json()["id"] for r in responses} == {request_id}
    assert all(r.json()["error"] in (None, "pending") for r in responses)
    finished = api.client.get(f"/v1/ai/recipes/modifications/{request_id}", headers=headers).json()
    assert finished["error"] is None and len(finished["operations"]) == 1
    assert finished["status"]["remaining"] == 49
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    audit = cli("ai", "audit", "--user", user_id)
    assert [c["capability"] for c in audit["calls"]] == ["modify_intent", "modify"]
    assert len(audit["modification_events"]) == 1
    assert audit["modification_events"][0]["content"]["stage"] == "proposed"


def test_single_repair_and_unreferenced_fields_are_not_applied(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("text-repair@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    snapshot = created["version"]["snapshot"]
    good = operation(snapshot)
    bad = {"operations": [{**good, "type": "rewrite_recipe"}]}
    payload = {"text": TEXT, "snapshot": snapshot, "intent": INTENT}
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    recording(directory, "modify", payload, bad)
    rewritten = copy.deepcopy(snapshot)
    rewritten["servings"] = 100
    recording(
        directory,
        "modify",
        {**payload, "repair": {"errors": ["invalid_operations"], "previous": bad}},
        {"operations": [good], "snapshot": rewritten, "dish_name": "偷偷修改"},
    )
    request_id = str(uuid.uuid4())
    body = {
        "request_id": request_id,
        "text": TEXT,
        "recipe_id": created["id"],
        "base_version_id": created["version"]["id"],
    }
    response = api.client.post("/v1/ai/recipes/modifications", headers=headers, json=body)
    assert response.status_code == 200, response.text
    preview = response.json()
    assert preview["error"] is None and preview["warnings"] == ["unreferenced_fields_dropped"]
    selected = choice(
        api, headers, preview, [{"operation_id": good["operation_id"], "decision": "accept"}]
    )
    assert selected["snapshot"]["servings"] == snapshot["servings"]
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    calls = cli("ai", "audit", "--user", user_id)["calls"]
    assert [c["capability"] for c in calls] == ["modify_intent", "modify", "modify"]
    assert {c["request_id"] for c in calls} == {request_id}
    assert all(c["input_tokens"] == 120 and c["output_tokens"] == 240 for c in calls)
    assert selected["status"]["remaining"] == 49
    retry = api.client.post("/v1/ai/recipes/modifications", headers=headers, json=body)
    assert retry.status_code == 200 and retry.json()["id"] == request_id
    assert len(cli("ai", "audit", "--user", user_id)["calls"]) == 3
    assert (
        len(
            [
                e
                for e in cli("ai", "audit", "--user", user_id)["modification_events"]
                if e["content"]["stage"] == "proposed"
            ]
        )
        == 1
    )


@pytest.mark.parametrize(
    "invalid",
    [
        "type",
        "field",
        "before",
        "target",
        "missing_dependency",
        "cycle",
        "duplicate",
        "numeric",
        "rewrite",
        "blank",
    ],
)
def test_invalid_operations_repair_once_then_fail_without_snapshot_write(modification_api, invalid):
    api, directory = modification_api
    headers = bearer(api.login(f"text-invalid-{invalid}@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    snapshot = created["version"]["snapshot"]
    op = operation(snapshot)
    if invalid == "type":
        op["type"] = "change_quantity"
    elif invalid == "field":
        op["field"] = "duration_seconds"
    elif invalid == "before":
        op["before"] = "不是原来的文字"
    elif invalid == "target":
        op["id"] = "other-owned-step"
    elif invalid == "missing_dependency":
        op["depends_on"] = ["missing"]
    elif invalid == "cycle":
        op["depends_on"] = [op["operation_id"]]
    elif invalid == "numeric":
        op["after"] = 12
    elif invalid == "blank":
        op["after"] = "   "
    bad = (
        {"snapshot": snapshot}
        if invalid == "rewrite"
        else {"operations": [op, op] if invalid == "duplicate" else [op]}
    )
    payload = {"text": TEXT, "snapshot": snapshot, "intent": INTENT}
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    recording(directory, "modify", payload, bad)
    recording(
        directory,
        "modify",
        {**payload, "repair": {"errors": ["invalid_operations"], "previous": bad}},
        bad,
    )
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={
            "text": TEXT,
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
        },
    )
    assert response.status_code == 200, response.text
    preview = response.json()
    assert preview["error"] == "invalid_output"
    assert preview["operations"] == [] and preview["snapshot"] == snapshot
    assert (
        api.client.post(
            f"/v1/ai/recipes/modifications/{preview['id']}/confirm",
            headers=headers,
            json={"revision": 0},
        ).status_code
        == 409
    )
    assert (
        api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()["version"]
        == created["version"]
    )
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    calls = cli("ai", "audit", "--user", user_id)["calls"]
    assert [c["capability"] for c in calls] == ["modify_intent", "modify", "modify"]
    assert len({c["request_id"] for c in calls}) == 1


def unsaved_generation(api, directory, headers):
    recording(directory, "intent", {"text": GENERATION_TEXT}, CORPUS["intent"])
    recording(directory, "embedding", {"text": "宫保鸡丁"}, CORPUS["embedding"])
    recording(directory, "generate", generation_payload(), CORPUS["valid"])
    recording(
        directory,
        "normalize",
        {"names": ["鸡腿肉", "盐"], "candidates": []},
        CORPUS["normalization"],
    )
    found = begin(api, headers)
    result = generate(api, headers, found["request_id"])
    assert result["error"] is None, result
    return found["request_id"], result["draft"]["recipe"]


@pytest.mark.parametrize("decision", ["accept", "reject"])
def test_generated_modification_uses_first_save_and_preserves_text_sources(
    modification_api, decision
):
    api, directory = modification_api
    headers = bearer(api.login(f"text-generation-{decision}@example.com"))
    request_id, draft = unsaved_generation(api, directory, headers)
    snapshot = draft["snapshot"]
    op = operation(
        snapshot,
        type="change_recipe_info",
        id=None,
        field="description",
        before=snapshot["description"],
        after="把鸡肉炒熟后盛出",
        intent="把介绍写得更直白",
    )
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    recording(
        directory,
        "modify",
        {"text": TEXT, "snapshot": snapshot, "intent": INTENT},
        {"operations": [op]},
    )
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={"text": TEXT, "generation_request_id": request_id},
    )
    assert response.status_code == 200, response.text
    preview = response.json()
    assert preview["error"] is None, preview
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []
    selected = choice(
        api, headers, preview, [{"operation_id": op["operation_id"], "decision": decision}]
    )
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []
    saved = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert saved.status_code == 201, saved.text
    version = saved.json()["version"]
    assert version["version_number"] == 1 and version["ai_assisted"] is True
    assert version["snapshot"]["description"] == (
        op["after"] if decision == "accept" else op["before"]
    )
    if decision == "accept":
        assert version["snapshot"]["text_source"]["source"] == "ai_estimated"
        assert version["snapshot"]["text_source"]["basis"] == op["reason"]
        assert version["edit_operations"][0]["intent"] == op["intent"]
    else:
        assert version["edit_operations"] == []
    for saved_item, original_item in zip(
        version["snapshot"]["ingredients"], snapshot["ingredients"], strict=True
    ):
        # First-save fills absent field-source markers without editing ingredient data.
        assert {k: v for k, v in saved_item.items() if k != "preparation_source"} == {
            k: v for k, v in original_item.items() if k != "preparation_source"
        }
        assert saved_item["preparation_source"]["source"] == "author_filled"
    regular_retry = api.client.post(
        f"/v1/ai/recipes/requests/{request_id}/save", headers=headers, json=draft
    )
    assert regular_retry.status_code == 201 and regular_retry.json()["id"] == saved.json()["id"]


def test_generated_accepted_servings_preserves_ai_source_on_first_save(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("method-generation-servings@example.com"))
    request_id, draft = unsaved_generation(api, directory, headers)
    snapshot = draft["snapshot"]
    text = "调整做法为四人份"
    intent = {"category": "method", "parameters": {}, "confidence": 0.95}
    op = operation(
        snapshot,
        operation_id="servings",
        type="change_recipe_info",
        id=None,
        field="servings",
        before=snapshot["servings"],
        after=4,
        scope=["recipe"],
        intent="调整份数",
        reason="按本次选定的份数调整",
    )
    recording(directory, "modify_intent", {"text": text}, intent)
    recording(
        directory,
        "modify",
        {"text": text, "snapshot": snapshot, "intent": intent},
        {"operations": [op]},
    )
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={"text": text, "generation_request_id": request_id},
    )
    assert response.status_code == 200, response.text
    proposal = response.json()
    assert proposal["error"] is None, proposal
    selected = choice(api, headers, proposal, [{"operation_id": "servings", "decision": "accept"}])
    assert selected["snapshot"]["servings"] == 4
    selected_source = selected["snapshot"]["servings_source"]
    assert selected_source["source"] == "ai_estimated"
    assert selected_source["basis"] == op["reason"]
    saved = api.client.post(
        f"/v1/ai/recipes/modifications/{proposal['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert saved.status_code == 201, saved.text
    version = saved.json()["version"]
    assert version["version_number"] == 1
    assert version["ai_assisted"] is True
    assert version["snapshot"]["servings"] == 4
    assert version["snapshot"]["servings_source"] == selected_source
    assert [edit["operation_id"] for edit in version["edit_operations"]] == ["servings"]


@pytest.mark.parametrize("decision", ["reject", "modify"])
def test_no_actual_existing_edit_does_not_create_version(modification_api, decision):
    api, directory = modification_api
    headers = bearer(api.login(f"text-noop-{decision}@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    preview = propose(api, directory, headers, created)
    selected = choice(
        api,
        headers,
        preview,
        [
            {
                "operation_id": "wording-1",
                "decision": decision,
                **(
                    {"after": created["version"]["snapshot"]["steps"][0]["instruction"]}
                    if decision == "modify"
                    else {}
                ),
            }
        ],
    )
    assert selected["snapshot"] == created["version"]["snapshot"]
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert response.status_code == 409 and response.json()["error"]["code"] == "no_modifications"
    assert (
        api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()["version"]
        == created["version"]
    )


def test_ownership_stale_base_and_conflicting_receipt_are_guarded(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("text-private@example.com"))
    other = bearer(api.login("text-outsider@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    preview = propose(api, directory, headers, created)
    route = f"/v1/ai/recipes/modifications/{preview['id']}"
    body = {
        "request_id": preview["id"],
        "text": TEXT,
        "recipe_id": created["id"],
        "base_version_id": created["version"]["id"],
    }
    assert api.client.get(route, headers=other).status_code == 404
    assert (
        api.client.post(route + "/decisions", headers=other, json={"decisions": []}).status_code
        == 404
    )
    assert (
        api.client.post(route + "/confirm", headers=other, json={"revision": 0}).status_code == 404
    )
    assert (
        api.client.post("/v1/ai/recipes/modifications", headers=other, json=body).status_code == 404
    )
    assert (
        api.client.post(
            "/v1/ai/recipes/modifications", headers=headers, json={**body, "text": "另一项请求"}
        ).status_code
        == 409
    )
    changed = copy.deepcopy(created["version"]["snapshot"])
    changed["description"] = "手动更新基准"
    assert (
        api.client.post(
            f"/v1/recipes/{created['id']}/versions", headers=headers, json={"snapshot": changed}
        ).status_code
        == 201
    )
    for response in [
        api.client.get(route, headers=headers),
        api.client.post(route + "/decisions", headers=headers, json={"decisions": []}),
        api.client.post(route + "/confirm", headers=headers, json={"revision": 0}),
    ]:
        assert (
            response.status_code == 409 and response.json()["error"]["code"] == "stale_modification"
        )
    fresh_key = {**body, "request_id": str(uuid.uuid4())}
    assert (
        api.client.post("/v1/ai/recipes/modifications", headers=headers, json=fresh_key).status_code
        == 409
    )
    request_id, draft = unsaved_generation(api, directory, headers)
    assert (
        api.client.post(
            "/v1/ai/recipes/modifications",
            headers=other,
            json={"text": TEXT, "generation_request_id": request_id},
        ).status_code
        == 404
    )
    recording(
        directory,
        "modify",
        {"text": TEXT, "snapshot": draft["snapshot"], "intent": INTENT},
        {"operations": [operation(draft["snapshot"])]},
    )
    generated_preview = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={"text": TEXT, "generation_request_id": request_id},
    ).json()
    assert (
        api.client.post(
            f"/v1/ai/recipes/requests/{request_id}/save", headers=headers, json=draft
        ).status_code
        == 201
    )
    stale = api.client.post(
        f"/v1/ai/recipes/modifications/{generated_preview['id']}/confirm",
        headers=headers,
        json={"revision": 0},
    )
    assert stale.status_code == 409 and stale.json()["error"]["code"] == "generation_already_saved"


@pytest.mark.parametrize(
    "category,confidence,error",
    [
        (
            c,
            0.95,
            "model_unavailable"
            if c in ("cookware", "time_difficulty", "method")
            else "unsupported_intent",
        )
        for c in ["taste", "cookware", "substitution", "time_difficulty", "method"]
    ]
    + [("unknown", 0.95, "uncertain_intent"), ("text", 0.4, "uncertain_intent")],
)
def test_unsupported_or_uncertain_intent_is_explicit(modification_api, category, confidence, error):
    api, directory = modification_api
    headers = bearer(api.login(f"text-intent-{category}-{confidence}@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    recording(
        directory,
        "modify_intent",
        {"text": TEXT},
        {**INTENT, "category": category, "confidence": confidence},
    )
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={
            "text": TEXT,
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
        },
    )
    assert response.status_code == 200, response.text
    assert response.json()["error"] == error and response.json()["operations"] == []
    assert response.json()["snapshot"] == created["version"]["snapshot"]
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    assert [c["capability"] for c in cli("ai", "audit", "--user", user_id)["calls"]] == (
        ["modify_intent", "modify"]
        if category in ("cookware", "time_difficulty", "method")
        else ["modify_intent"]
    )


def test_selected_health_claim_blocks_confirm_and_modified_text_rechecks(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("text-safety@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    preview = propose(
        api,
        directory,
        headers,
        created,
        operations=[operation(created["version"]["snapshot"], after="食用这道菜可以降血糖")],
    )
    selected = choice(api, headers, preview, [{"operation_id": "wording-1", "decision": "accept"}])
    assert selected["safety"]["can_save"] is False
    route = f"/v1/ai/recipes/modifications/{preview['id']}/confirm"
    rejected = api.client.post(route, headers=headers, json={"revision": selected["revision"]})
    assert (
        rejected.status_code == 422
        and rejected.json()["error"]["code"] == "prohibited_health_claim"
    )
    assert (
        api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()["version"]["id"]
        == created["version"]["id"]
    )
    selected = choice(
        api,
        headers,
        preview,
        [{"operation_id": "wording-1", "decision": "modify", "after": "将鸡肉切块"}],
    )
    assert selected["safety"]["can_save"] is True
    note = api.client.post(
        route, headers=headers, json={"revision": selected["revision"], "change_note": "降血糖"}
    )
    assert note.status_code == 422
    assert (
        api.client.post(route, headers=headers, json={"revision": selected["revision"]}).status_code
        == 201
    )


@pytest.mark.parametrize("failure", ["missing_replay", "daily_quota", "monthly_budget"])
def test_unavailable_modification_preserves_manual_save(modification_api, failure):
    api, _directory = modification_api
    headers = bearer(api.login(f"text-unavailable-{failure}@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    if failure == "daily_quota":
        configure(
            "ai.policies",
            {
                "modify": {"timeout": 60, "retries": 0, "daily_limit": 0},
                "modify_intent": {"timeout": 15, "retries": 0, "daily_limit": 0},
            },
        )
    elif failure == "monthly_budget":
        configure("ai.monthly_budget", 0)
    response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={
            "text": TEXT,
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
        },
    )
    assert response.status_code == 200, response.text
    preview = response.json()
    expected = "model_unavailable" if failure == "missing_replay" else failure
    assert preview["error"] == expected
    assert preview["status"]["available"] is False and preview["status"]["reason"] == expected
    assert preview["snapshot"] == created["version"]["snapshot"]
    changed = copy.deepcopy(created["version"]["snapshot"])
    changed["description"] = "不用 AI 也能继续手动编辑"
    assert (
        api.client.post(
            f"/v1/recipes/{created['id']}/versions", headers=headers, json={"snapshot": changed}
        ).status_code
        == 201
    )
    assert cli("ai", "purge-logs")["modifications"] == 0
    assert (
        api.client.get(f"/v1/ai/recipes/modifications/{preview['id']}", headers=headers).status_code
        == 409
    )
