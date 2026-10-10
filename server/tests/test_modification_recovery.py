"""Modification recovery and quota degradation through owned public interfaces."""

import uuid

import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import cli, configure, recording
from tests.test_recipe_modifications import (
    INTENT,
    TEXT,
    choice,
    operation,
    propose,
)
from tests.test_recipes import recipe_input


@pytest.fixture
def recovery_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def modification_api(recovery_recordings, api):
    return api, recovery_recordings


def test_failed_product_request_retries_without_double_quota_and_records_cost(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("modification-recovery@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    body = {
        "request_id": str(uuid.uuid4()),
        "text": TEXT,
        "recipe_id": created["id"],
        "base_version_id": created["version"]["id"],
    }
    configure("ai.policies", {"modify": {"daily_limit": 1}, "modify_intent": {"daily_limit": 1}})
    failed = api.client.post("/v1/ai/recipes/modifications", headers=headers, json=body)
    assert failed.status_code == 200, failed.text
    assert failed.json()["error"] == "model_unavailable"
    assert failed.json()["status"]["remaining"] == 0
    snapshot = created["version"]["snapshot"]
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    recording(
        directory,
        "modify",
        {"text": TEXT, "snapshot": snapshot, "intent": INTENT},
        {"operations": [operation(snapshot)]},
    )
    recovered = api.client.post(
        "/v1/ai/recipes/modifications", headers=headers, json={**body, "retry_failed": True}
    )
    assert recovered.status_code == 200, recovered.text
    assert recovered.json()["id"] == body["request_id"]
    assert recovered.json()["error"] is None
    assert recovered.json()["status"]["remaining"] == 0
    selected = choice(
        api,
        headers,
        recovered.json(),
        [{"operation_id": "wording-1", "decision": "modify", "after": "切成 3 厘米块"}],
    )
    reopened = api.client.get(f"/v1/ai/recipes/modifications/{body['request_id']}", headers=headers)
    assert reopened.status_code == 200, reopened.text
    assert reopened.json()["decisions"] == selected["decisions"]
    assert reopened.json()["snapshot"] == selected["snapshot"]
    saved = api.client.post(
        f"/v1/ai/recipes/modifications/{body['request_id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["snapshot"]["steps"][0]["instruction"] == "切成 3 厘米块"
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    calls = cli("ai", "audit", "--user", user_id)["calls"]
    assert [call["status"] for call in calls] == ["failed", "succeeded", "succeeded"]
    assert {call["request_id"] for call in calls} == {body["request_id"]}
    assert calls[0]["reserved_cost"] > 0
    assert all(call["input_tokens"] == 120 and call["output_tokens"] == 240 for call in calls[1:])


def test_checked_selection_survives_later_failure_and_quota_degradation(modification_api):
    api, directory = modification_api
    headers = bearer(api.login("modification-preserve@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    initial = propose(api, directory, headers, created)
    selected = choice(api, headers, initial, [{"operation_id": "wording-1", "decision": "accept"}])
    failure = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={
            "text": "一个没有回放的后续请求",
            "recipe_id": created["id"],
            "base_version_id": created["version"]["id"],
        },
    )
    assert failure.status_code == 200, failure.text
    assert failure.json()["error"] == "model_unavailable"
    configure("ai.monthly_budget", 0)
    reopened = api.client.get(f"/v1/ai/recipes/modifications/{selected['id']}", headers=headers)
    assert reopened.status_code == 200, reopened.text
    assert reopened.json()["status"]["reason"] == "monthly_budget"
    assert reopened.json()["decisions"] == selected["decisions"]
    assert reopened.json()["snapshot"] == selected["snapshot"]
    saved = api.client.post(
        f"/v1/ai/recipes/modifications/{selected['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert saved.status_code == 201, saved.text
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    )
    assert old.json()["version"]["snapshot"] == created["version"]["snapshot"]
