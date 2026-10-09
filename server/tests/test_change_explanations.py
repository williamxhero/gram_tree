"""Change explanations through owned HTTP APIs and synthetic gateway recordings."""

import copy
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from gramtree.main import create_app
from tests.accounts_support import bearer
from tests.conftest import make_settings
from tests.test_ai_recipes import cli, configure, recording
from tests.test_recipe_modifications import choice, operation, propose, unsaved_generation
from tests.test_recipes import recipe_input

EXPLANATIONS = json.loads(
    Path(__file__)
    .with_name("fixtures")
    .joinpath("ai/change_explanation_corpus.json")
    .read_text(encoding="utf-8")
)


@pytest.fixture
def explanation_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def replay_explanation_api(explanation_recordings, api):
    return api, explanation_recordings


@pytest.mark.parametrize("entry_point", ["manual", "generation"])
def test_explanation_and_save_preserve_owned_measure_input(replay_explanation_api, entry_point):
    api, directory = replay_explanation_api
    headers = bearer(api.login(f"explanation-measure-{entry_point}@example.com"))
    measure_response = api.client.post(
        "/v1/me/measures",
        headers=headers,
        json={"name": "白瓷勺", "kind": "spoon", "capacity_ml": 12},
    )
    assert measure_response.status_code == 201, measure_response.text
    confirmed_response = api.client.post(
        "/v1/me/measures/input",
        headers=headers,
        json={"measure_id": measure_response.json()["id"], "quantity": 2, "base_unit": "ml"},
    )
    assert confirmed_response.status_code == 200, confirmed_response.text
    confirmed = confirmed_response.json()
    if entry_point == "generation":
        request_id, recipe = unsaved_generation(api, directory, headers)
        target = {"generation_request_id": request_id}
        save_route = f"/v1/ai/recipes/requests/{request_id}/save"
    else:
        created_response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
        assert created_response.status_code == 201, created_response.text
        created = created_response.json()
        recipe = {"snapshot": created["version"]["snapshot"]}
        target = {"recipe_id": created["id"], "base_version_id": created["version"]["id"]}
        save_route = f"/v1/recipes/{created['id']}/versions"
    changed = copy.deepcopy(recipe)
    before = recipe["snapshot"]["ingredients"][0]
    after = changed["snapshot"]["ingredients"][0]
    after.update(
        quantity=confirmed["base_quantity"],
        unit="ml",
        measure_input_token=confirmed["measure_input_token"],
    )
    operations = [
        {
            "type": "change_quantity",
            "id": before["id"],
            "field": field,
            "before": before[field],
            "after": after[field],
            "intent": "作者手动修改",
        }
        for field in ("quantity", "unit")
    ]
    operations.sort(key=lambda value: json.dumps(value, ensure_ascii=False, sort_keys=True))
    recording(
        directory,
        "change_explanation",
        {"operations": operations},
        {"change_note": "按个人量具确认用量", "tags": ["用量调整"]},
    )
    response = api.client.post(
        "/v1/ai/recipes/change-explanation",
        headers=headers,
        json={**target, "snapshot": changed["snapshot"]},
    )
    assert response.status_code == 200, response.text
    explanation = response.json()
    assert explanation["error"] is None, explanation
    changed["explanation_fingerprint"] = explanation["changes_fingerprint"]
    changed["change_note"] = explanation["change_note"]
    if entry_point == "manual":
        changed["base_version_id"] = target["base_version_id"]
    saved_response = api.client.post(save_route, headers=headers, json=changed)
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()["version"]["snapshot"]["ingredients"][0]
    assert saved["quantity_source"] == confirmed["quantity_source"]
    assert saved["measure_input_token"] == confirmed["measure_input_token"]
    assert saved["base_quantity"] == 24 and saved["base_unit"] == "ml"


def test_manual_explanation_inherits_omitted_functional_fields_like_final_save(
    replay_explanation_api,
):
    api, directory = replay_explanation_api
    headers = bearer(api.login("explanation-legacy-functional@example.com"))
    recipe = recipe_input()
    recipe["snapshot"]["ingredients"][0]["functional"] = True
    created_response = api.client.post("/v1/recipes", headers=headers, json=recipe)
    assert created_response.status_code == 201, created_response.text
    created = created_response.json()
    baseline = created["version"]["snapshot"]
    changed = copy.deepcopy(baseline)
    changed["steps"][0]["instruction"] = "鸡腿肉切成 2 厘米块后加盐腌制"
    for ingredient in changed["ingredients"]:
        ingredient.pop("functional")
        ingredient.pop("functional_source")
    recording(
        directory,
        "change_explanation",
        {
            "operations": [
                {
                    "type": "change_step_field",
                    "id": "marinate",
                    "field": "instruction",
                    "before": "鸡腿肉加盐腌制",
                    "after": changed["steps"][0]["instruction"],
                    "intent": "作者手动修改",
                }
            ]
        },
        EXPLANATIONS["manual"],
    )
    response = api.client.post(
        "/v1/ai/recipes/change-explanation",
        headers=headers,
        json={
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
            "snapshot": changed,
        },
    )
    assert response.status_code == 200, response.text
    explanation = response.json()
    assert explanation["error"] is None, explanation
    saved_response = api.client.post(
        f"/v1/recipes/{created['id']}/versions",
        headers=headers,
        json={
            "snapshot": changed,
            "base_version_id": created["version"]["id"],
            "change_note": explanation["change_note"],
            "explanation_fingerprint": explanation["changes_fingerprint"],
        },
    )
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()["version"]
    assert saved["snapshot"]["ingredients"] == baseline["ingredients"]
    assert [operation["field"] for operation in saved["edit_operations"]] == ["instruction"]


def test_manual_explanation_can_be_edited_saved_and_read_without_ai_recipe_provenance(
    replay_explanation_api,
):
    api, directory = replay_explanation_api
    headers = bearer(api.login("explanation-manual@example.com"))
    created_response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert created_response.status_code == 201, created_response.text
    created = created_response.json()
    changed = copy.deepcopy(created["version"]["snapshot"])
    changed["steps"][0]["instruction"] = "鸡腿肉切成 2 厘米块后加盐腌制"
    operations = [
        {
            "type": "change_step_field",
            "id": "marinate",
            "field": "instruction",
            "before": "鸡腿肉加盐腌制",
            "after": "鸡腿肉切成 2 厘米块后加盐腌制",
            "intent": "作者手动修改",
        }
    ]
    recording(
        directory,
        "change_explanation",
        {"operations": operations},
        EXPLANATIONS["manual"],
    )
    response = api.client.post(
        "/v1/ai/recipes/change-explanation",
        headers=headers,
        json={
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
            "snapshot": changed,
        },
    )
    assert response.status_code == 200, response.text
    explanation = response.json()
    assert explanation["error"] is None, explanation
    assert explanation["change_note"] == "把鸡肉切块大小写清楚"
    assert explanation["tags"] == ["步骤更清楚"]
    assert explanation["source"] == "ai_estimated"
    changed["tags"] = ["作者标签"]
    saved_response = api.client.post(
        f"/v1/recipes/{created['id']}/versions",
        headers=headers,
        json={
            "snapshot": changed,
            "base_version_id": created["version"]["id"],
            "change_note": "作者确认：切 2 厘米块",
            "explanation_fingerprint": explanation["changes_fingerprint"],
        },
    )
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()["version"]
    assert saved["ai_assisted"] is False
    assert saved["change_note"] == "作者确认：切 2 厘米块"
    assert saved["snapshot"]["tags"] == ["作者标签"]
    assert all(op["intent"] == "作者手动修改" for op in saved["edit_operations"])
    assert saved["snapshot"]["steps"][0]["instruction_source"]["source"] == "author_filled"
    reread = api.client.get(f"/v1/recipes/{created['id']}/versions/{saved['id']}", headers=headers)
    assert reread.status_code == 200, reread.text
    assert reread.json()["version"] == saved
    history = api.client.get(f"/v1/recipes/{created['id']}/versions", headers=headers).json()
    assert history["items"][0]["change_note"] == "作者确认：切 2 厘米块"
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    ).json()
    assert old["version"] == created["version"]


def test_explanation_uses_only_final_accepted_canonical_values_and_author_can_edit_labels(
    replay_explanation_api,
):
    api, directory = replay_explanation_api
    headers = bearer(api.login("explanation-confirmed@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    snapshot = created["version"]["snapshot"]
    item = snapshot["ingredients"][0]
    accepted = operation(
        snapshot,
        type="change_display_name",
        id=item["id"],
        field="display_name",
        before=item["display_name"],
        after="Chicken",
        scope=["ingredients"],
        intent="把食材标签写清楚",
    )
    rejected = operation(
        snapshot,
        operation_id="rejected",
        field="notes",
        before="提前准备",
        after="去掉盐",
    )
    unchanged = operation(
        snapshot,
        operation_id="unchanged",
        field="why",
        before="让肉更入味",
        after="让文字更清楚",
    )
    preview = propose(api, directory, headers, created, operations=[accepted, rejected, unchanged])
    selected = choice(
        api,
        headers,
        preview,
        [
            {
                "operation_id": accepted["operation_id"],
                "decision": "modify",
                "after": "  Poultry  ",
            },
            {"operation_id": "rejected", "decision": "reject"},
            {"operation_id": "unchanged", "decision": "modify", "after": "让肉更入味"},
        ],
    )
    operations = [
        {
            "type": "change_display_name",
            "id": "chicken",
            "field": "display_name",
            "before": "鸡腿肉",
            "after": "Poultry",
            "intent": "把食材标签写清楚",
        }
    ]
    recording(
        directory,
        "change_explanation",
        {"operations": operations},
        EXPLANATIONS["confirmed"],
    )
    explained = api.client.post(
        "/v1/ai/recipes/change-explanation",
        headers=headers,
        json={"modification_id": selected["id"], "revision": selected["revision"]},
    )
    assert explained.status_code == 200, explained.text
    explanation = explained.json()
    assert explanation["error"] is None, explanation
    assert explanation["change_note"] == "将鸡肉标签改为 Poultry"
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{selected['id']}/confirm",
        headers=headers,
        json={
            "revision": selected["revision"],
            "change_note": "作者采用 Poultry 标签",
            "tags": ["作者改标签"],
            "explanation_fingerprint": explanation["changes_fingerprint"],
        },
    )
    assert response.status_code == 201, response.text
    version = response.json()["version"]
    assert version["change_note"] == "作者采用 Poultry 标签"
    assert version["snapshot"]["tags"] == ["作者改标签"]
    assert version["ai_assisted"] is True
    assert len(version["edit_operations"]) == 1
    assert version["edit_operations"][0]["after"] == "Poultry"
    assert version["edit_operations"][0]["intent"] == "把食材标签写清楚"
    assert version["snapshot"]["steps"] == snapshot["steps"]
    assert version["snapshot"]["ingredients"][0]["quantity_source"]["source"] == "author_filled"
    reread = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{version['id']}", headers=headers
    ).json()
    assert reread["version"] == version


def manual_change(api, headers):
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    changed = copy.deepcopy(created["version"]["snapshot"])
    changed["ingredients"][0]["quantity"] = 250
    body = {
        "recipe_id": created["id"],
        "base_version_id": created["version"]["id"],
        "snapshot": changed,
    }
    facts = [
        {
            "type": "change_quantity",
            "id": "chicken",
            "field": "quantity",
            "before": 300.0,
            "after": 250.0,
            "intent": "作者手动修改",
        }
    ]
    return created, changed, body, {"operations": facts}


def test_stale_manual_explanation_is_not_adopted_but_handwriting_can_still_save(
    replay_explanation_api,
):
    api, directory = replay_explanation_api
    headers = bearer(api.login("explanation-stale-manual@example.com"))
    created, changed, body, payload = manual_change(api, headers)
    recording(
        directory,
        "change_explanation",
        payload,
        {"change_note": "鸡肉减为 250 克", "tags": ["用量调整"]},
    )
    explained = api.client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
    assert explained.status_code == 200 and explained.json()["error"] is None, explained.text
    changed["ingredients"][0]["quantity"] = 200
    save = {
        "snapshot": changed,
        "base_version_id": created["version"]["id"],
        "change_note": explained.json()["change_note"],
        "explanation_fingerprint": explained.json()["changes_fingerprint"],
    }
    response = api.client.post(f"/v1/recipes/{created['id']}/versions", headers=headers, json=save)
    assert (
        response.status_code == 409
        and response.json()["error"]["code"] == "stale_change_explanation"
    )
    assert (
        api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()["version"]["id"]
        == created["version"]["id"]
    )
    save.pop("explanation_fingerprint")
    save["change_note"] = "作者手写：改为 200 克"
    saved = api.client.post(f"/v1/recipes/{created['id']}/versions", headers=headers, json=save)
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["snapshot"]["ingredients"][0]["quantity"] == 200
    assert saved.json()["version"]["ai_assisted"] is False


@pytest.mark.parametrize("failure", ["missing_replay", "daily_quota", "monthly_budget", "disabled"])
def test_failed_explanation_preserves_manual_changes_and_handwritten_save(
    replay_explanation_api, failure
):
    api, _directory = replay_explanation_api
    headers = bearer(api.login(f"explanation-failure-{failure}@example.com"))
    created, changed, body, _payload = manual_change(api, headers)
    if failure == "daily_quota":
        configure(
            "ai.policies", {"change_explanation": {"timeout": 15, "retries": 0, "daily_limit": 0}}
        )
    elif failure == "monthly_budget":
        configure("ai.monthly_budget", 0)
    if failure == "disabled":
        # Process settings come from the existing app, so use a fresh app against
        # the same public resources rather than patching a gateway collaborator.
        with TestClient(
            create_app(make_settings(ai_mode="disabled")), raise_server_exceptions=False
        ) as client:
            explained = client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
    else:
        explained = api.client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
    assert explained.status_code == 200, explained.text
    result = explained.json()
    expected = "model_unavailable" if failure in ("missing_replay", "disabled") else failure
    assert result["error"] == expected
    assert result["status"]["available"] is False and result["status"]["reason"] == expected
    assert result["change_note"] is None and result["tags"] == [] and result["source"] is None
    changed["tags"] = ["作者手写标签"]
    saved = api.client.post(
        f"/v1/recipes/{created['id']}/versions",
        headers=headers,
        json={"snapshot": changed, "change_note": "作者手写：鸡肉改为 250 克"},
    )
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["snapshot"]["ingredients"][0]["quantity"] == 250
    assert saved.json()["version"]["snapshot"]["tags"] == ["作者手写标签"]
    assert saved.json()["version"]["change_note"] == "作者手写：鸡肉改为 250 克"


@pytest.mark.parametrize(
    "invalid",
    [
        "medical_note",
        "medical_tag",
        "verified_note",
        "verified_tag",
        "invalid_structure",
        "whole_recipe",
    ],
)
def test_explanation_rejects_unsafe_unverified_or_unstructured_output_once_then_falls_back(
    replay_explanation_api, invalid
):
    api, directory = replay_explanation_api
    headers = bearer(api.login(f"explanation-invalid-{invalid}@example.com"))
    created, changed, body, payload = manual_change(api, headers)
    bad = EXPLANATIONS[invalid]
    recording(directory, "change_explanation", payload, bad)
    recording(
        directory,
        "change_explanation",
        {**payload, "repair": {"errors": ["invalid_explanation"], "previous": bad}},
        bad,
    )
    explained = api.client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
    assert explained.status_code == 200, explained.text
    result = explained.json()
    assert result["error"] == "invalid_output"
    assert result["change_note"] is None and result["tags"] == [] and result["source"] is None
    assert result["status"]["remaining"] == 49
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    calls = cli("ai", "audit", "--user", user_id)["calls"]
    assert [call["capability"] for call in calls] == ["change_explanation", "change_explanation"]
    assert len({call["request_id"] for call in calls}) == 1
    assert all(call["content_id"] == created["version"]["id"] for call in calls)
    saved = api.client.post(
        f"/v1/recipes/{created['id']}/versions",
        headers=headers,
        json={"snapshot": changed, "change_note": "作者手写：调整鸡肉用量"},
    )
    assert saved.status_code == 201, saved.text


def test_generated_form_changes_can_be_explained_and_stale_binding_cannot_be_saved(
    replay_explanation_api,
):
    api, directory = replay_explanation_api
    headers = bearer(api.login("explanation-generation@example.com"))
    request_id, draft = unsaved_generation(api, directory, headers)
    changed = copy.deepcopy(draft)
    changed["snapshot"]["description"] = "手动补充制作说明"
    operations = [
        {
            "type": "change_recipe_info",
            "field": "description",
            "before": draft["snapshot"]["description"],
            "after": "手动补充制作说明",
            "intent": "作者手动修改",
        }
    ]
    recording(
        directory,
        "change_explanation",
        {"operations": operations},
        {"change_note": "补充制作说明", "tags": ["介绍调整"]},
    )
    body = {"generation_request_id": request_id, "snapshot": changed["snapshot"]}
    explained = api.client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
    assert explained.status_code == 200 and explained.json()["error"] is None, explained.text
    changed["explanation_fingerprint"] = explained.json()["changes_fingerprint"]
    changed["snapshot"]["description"] = "另一次手动修改"
    route = f"/v1/ai/recipes/requests/{request_id}/save"
    stale = api.client.post(route, headers=headers, json=changed)
    assert stale.status_code == 409 and stale.json()["error"]["code"] == "stale_change_explanation"
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []
    changed["snapshot"]["description"] = "手动补充制作说明"
    changed["change_note"] = "作者采用：补充说明"
    changed["snapshot"]["tags"] = ["作者标签"]
    saved = api.client.post(route, headers=headers, json=changed)
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["change_note"] == "作者采用：补充说明"
    assert saved.json()["version"]["snapshot"]["tags"] == ["作者标签"]
    assert saved.json()["version"]["ai_assisted"] is True  # Original recipe was generated.
    assert saved.json()["version"]["snapshot"]["text_source"]["source"] == "author_filled"


def test_pending_and_stale_decisions_cannot_generate_or_adopt_explanation(replay_explanation_api):
    api, directory = replay_explanation_api
    headers = bearer(api.login("explanation-stale-selected@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    preview = propose(api, directory, headers, created)
    endpoint = "/v1/ai/recipes/change-explanation"
    pending = api.client.post(
        endpoint, headers=headers, json={"modification_id": preview["id"], "revision": 0}
    )
    assert (
        pending.status_code == 409
        and pending.json()["error"]["code"] == "modification_decisions_required"
    )
    selected = choice(api, headers, preview, [{"operation_id": "wording-1", "decision": "accept"}])
    operations = [
        {
            "type": "change_step_field",
            "id": "marinate",
            "field": "instruction",
            "before": "鸡腿肉加盐腌制",
            "after": "将鸡肉切成 2 厘米块，放入碗中",
            "intent": "说明鸡肉处理方式",
        }
    ]
    recording(directory, "change_explanation", {"operations": operations}, EXPLANATIONS["manual"])
    explained = api.client.post(
        endpoint,
        headers=headers,
        json={"modification_id": selected["id"], "revision": selected["revision"]},
    )
    assert explained.status_code == 200 and explained.json()["error"] is None, explained.text
    updated = choice(
        api,
        headers,
        selected,
        [{"operation_id": "wording-1", "decision": "modify", "after": "鸡肉切成 3 厘米块"}],
    )
    stale = api.client.post(
        endpoint,
        headers=headers,
        json={"modification_id": updated["id"], "revision": selected["revision"]},
    )
    assert (
        stale.status_code == 409 and stale.json()["error"]["code"] == "stale_modification_decisions"
    )
    route = f"/v1/ai/recipes/modifications/{updated['id']}/confirm"
    stale = api.client.post(
        route,
        headers=headers,
        json={
            "revision": updated["revision"],
            "change_note": explained.json()["change_note"],
            "explanation_fingerprint": explained.json()["changes_fingerprint"],
        },
    )
    assert stale.status_code == 409 and stale.json()["error"]["code"] == "stale_change_explanation"
    saved = api.client.post(
        route,
        headers=headers,
        json={"revision": updated["revision"], "change_note": "作者手写：改为 3 厘米块"},
    )
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["snapshot"]["steps"][0]["instruction"] == "鸡肉切成 3 厘米块"


def test_explanation_targets_are_private_and_client_operations_are_not_trusted(
    replay_explanation_api,
):
    api, _directory = replay_explanation_api
    headers = bearer(api.login("explanation-owner@example.com"))
    other = bearer(api.login("explanation-other@example.com"))
    created, _changed, body, _payload = manual_change(api, headers)
    endpoint = "/v1/ai/recipes/change-explanation"
    hidden = api.client.post(endpoint, headers=other, json=body)
    assert hidden.status_code == 404
    fabricated = api.client.post(
        endpoint, headers=headers, json={**body, "operations": [{"after": "invented"}]}
    )
    assert fabricated.status_code == 422
    false_verified = copy.deepcopy(body)
    false_verified["snapshot"]["text_source"] = {"source": "verified"}
    assert api.client.post(endpoint, headers=headers, json=false_verified).status_code == 422
    invalid_target = api.client.post(
        endpoint, headers=headers, json={"recipe_id": created["id"], "snapshot": body["snapshot"]}
    )
    assert invalid_target.status_code == 422


def test_no_actual_changes_produce_no_summary_or_billable_attempt(replay_explanation_api):
    api, _directory = replay_explanation_api
    headers = bearer(api.login("explanation-noop@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    body = {
        "recipe_id": created["id"],
        "base_version_id": created["version"]["id"],
        "snapshot": created["version"]["snapshot"],
    }
    explained = api.client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
    assert explained.status_code == 200, explained.text
    assert explained.json()["error"] == "no_changes"
    assert explained.json()["change_note"] is None and explained.json()["tags"] == []
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    assert cli("ai", "audit", "--user", user_id)["calls"] == []


@pytest.mark.parametrize("field", ["change_note", "tags"])
def test_authored_summary_and_labels_still_obey_save_safety(replay_explanation_api, field):
    api, _directory = replay_explanation_api
    headers = bearer(api.login(f"explanation-author-safety-{field}@example.com"))
    created, changed, _body, _payload = manual_change(api, headers)
    save = {"snapshot": changed, "change_note": "作者改用量"}
    if field == "change_note":
        save["change_note"] = "吃这道菜可以降血糖"
    else:
        changed["tags"] = ["降血糖"]
    blocked = api.client.post(f"/v1/recipes/{created['id']}/versions", headers=headers, json=save)
    assert (
        blocked.status_code == 422 and blocked.json()["error"]["code"] == "prohibited_health_claim"
    )
