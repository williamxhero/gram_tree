"""Natural-language edits at the owned HTTP boundary, using recorded answers only."""


import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import recording
from tests.test_recipes import recipe_input
from tests.test_ai_recipes import cli, configure, CORPUS, TEXT as GENERATION_TEXT, generation_payload
import copy
import uuid

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
