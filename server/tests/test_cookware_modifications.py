"""Cookware conversion through owned HTTP edits and synthetic gateway replay."""

import copy
import json
import subprocess
import sys
from pathlib import Path

import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import begin, cli, generate, recording
from tests.test_recipe_modifications import choice
from tests.test_recipes import recipe_input


@pytest.fixture
def cookware_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def modification_api(cookware_recordings, api):
    return api, cookware_recordings


CORPUS = json.loads(
    Path(__file__)
    .with_name("fixtures")
    .joinpath("ai/cookware_modification_corpus.json")
    .read_text("utf-8")
)


def cookware_operations(snapshot):
    step = snapshot["steps"][1]
    return [
        {
            "id": step["id"],
            "before": step[change["field"]],
            "scope": [f"steps:{step['id']}:{change['field']}"],
            "intent": "换空气炸锅",
            "reason": CORPUS["reason"],
            "risk": CORPUS["risk"],
            "confidence": 0.8,
            **change,
        }
        for change in CORPUS["changes"]
    ]


def recorded_proposal(api, directory, headers, detail, text, intent, output):
    snapshot = detail["version"]["snapshot"]
    payload = {"text": text, "snapshot": snapshot, "intent": intent}
    recording(directory, "modify_intent", {"text": text}, intent)
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
        json={"text": text, "recipe_id": detail["id"], "base_version_id": detail["version"]["id"]},
    )
    assert response.status_code == 200, response.text
    return response.json()


def propose_cookware(api, directory, headers, created, operations=None):
    return recorded_proposal(
        api,
        directory,
        headers,
        created,
        CORPUS["text"],
        CORPUS["intent"],
        {
            "operations": operations
            if operations is not None
            else cookware_operations(created["version"]["snapshot"])
        },
    )


def create_recipe(api, email):
    headers = bearer(api.login(email))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    return response.json(), headers


def test_materialized_cookware_corpus_explains_canonical_selected_values(modification_api):
    api, directory = modification_api
    root = Path(__file__).resolve().parents[2]
    subprocess.run(
        [sys.executable, str(root / "tool/ai_replay_corpus.py"), "--out", str(directory)],
        check=True,
    )
    headers = bearer(api.login("cookware-materialized-corpus@example.com"))
    found = begin(api, headers)
    generated = generate(api, headers, found["request_id"])
    assert generated["error"] is None, generated
    saved_response = api.client.post(
        f"/v1/ai/recipes/requests/{found['request_id']}/save",
        headers=headers,
        json=generated["draft"]["recipe"],
    )
    assert saved_response.status_code == 201, saved_response.text
    saved = saved_response.json()
    proposal_response = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=headers,
        json={
            "text": CORPUS["text"],
            "recipe_id": saved["id"],
            "base_version_id": saved["version"]["id"],
        },
    )
    assert proposal_response.status_code == 200, proposal_response.text
    proposal = proposal_response.json()
    assert proposal["error"] is None, proposal
    values = {
        "instruction": "空气炸锅180°C加热鸡肉10分钟，用食品温度计确认鸡肉中心温度达到74°C后盛出",
        "duration_seconds": 600,
        "doneness": "用食品温度计确认鸡肉中心温度达到74°C",
    }
    selected = choice(
        api,
        headers,
        proposal,
        [
            {
                "operation_id": operation["operation_id"],
                "decision": "modify" if operation["field"] in values else "accept",
                **({"after": values[operation["field"]]} if operation["field"] in values else {}),
            }
            for operation in proposal["operations"]
        ],
    )
    explained = api.client.post(
        "/v1/ai/recipes/change-explanation",
        headers=headers,
        json={"modification_id": selected["id"], "revision": selected["revision"]},
    )
    assert explained.status_code == 200, explained.text
    explanation = explained.json()
    assert explanation["error"] is None, explanation
    assert explanation["change_note"] == "改用空气炸锅，调整温度、时长、容器和中心温度判断。"
    assert explanation["tags"] == ["换厨具"]
    assert explanation["source"] == "ai_estimated"
    assert explanation["changes_fingerprint"]


def test_air_fryer_conditions_save_new_version_without_rewriting_old_steps(modification_api):
    api, directory = modification_api
    created, headers = create_recipe(api, "air-fryer@example.com")
    baseline = created["version"]["snapshot"]
    proposal = propose_cookware(api, directory, headers, created)
    assert proposal["error"] is None, proposal
    assert proposal["snapshot"] == baseline
    assert proposal["intent"] == CORPUS["intent"]
    selected = choice(
        api,
        headers,
        proposal,
        [
            {"operation_id": op["operation_id"], "decision": "accept"}
            for op in proposal["operations"]
        ],
    )
    step = selected["snapshot"]["steps"][1]
    assert step["cookware"] == "空气炸锅"
    assert step["temperature_celsius"] == 180
    assert step["duration_seconds"] == 60
    assert step["heat"] is None
    assert "耐热浅盘" in step["notes"]
    assert "表面变白" in step["doneness"]
    assert selected["snapshot"]["steps"][0] == baseline["steps"][0]
    assert selected["snapshot"]["ingredients"] == baseline["ingredients"]
    assert selected["safety"]["findings"], selected["safety"]
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{proposal['id']}/confirm",
        headers=headers,
        json={"revision": selected["revision"]},
    )
    assert response.status_code == 201, response.text
    saved = response.json()["version"]
    assert saved["snapshot"] == selected["snapshot"]
    assert saved["edit_operations"] and all(
        op["intent"] == "换空气炸锅" for op in saved["edit_operations"]
    )
    assert step["temperature_source"]["source"] == "ai_estimated"
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}",
        headers=headers,
    ).json()
    assert old["version"] == created["version"]
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    events = cli("ai", "audit", "--user", user_id)["modification_events"]
    saved_event = next(e for e in events if e["content"]["stage"] == "saved")
    assert saved_event["content"]["intent"] == CORPUS["intent"]
    assert saved_event["content"]["saved_version_id"] == saved["id"]


def test_rejecting_appliance_rejects_conditions_and_author_values_are_checked(modification_api):
    api, directory = modification_api
    created, headers = create_recipe(api, "air-fryer-dependencies@example.com")
    proposal = propose_cookware(api, directory, headers, created)
    assert proposal["error"] is None, proposal
    rejected = choice(
        api,
        headers,
        proposal,
        [
            {
                "operation_id": op["operation_id"],
                "decision": "reject" if op["operation_id"] == "appliance" else "accept",
            }
            for op in proposal["operations"]
        ],
    )
    assert rejected["snapshot"] == created["version"]["snapshot"]
    assert all(d["decision"] == "reject" for d in rejected["decisions"])
    assert rejected["decisions"][1]["blocked_by"] == ["appliance"]
    decisions = [
        {"operation_id": op["operation_id"], "decision": "accept"} for op in proposal["operations"]
    ]
    decisions[3] = {"operation_id": "duration", "decision": "modify", "after": 90}
    decisions[6] = {"operation_id": "doneness", "decision": "modify", "after": "适量加热"}
    selected = choice(api, headers, proposal, decisions)
    assert selected["snapshot"]["steps"][1]["duration_seconds"] == 90
    assert selected["snapshot"]["steps"][1]["duration_source"]["source"] == "author_filled"
    assert any(
        p["position"]["field"] == "doneness" for p in selected["reproducibility"]["problems"]
    )
    assert selected["safety"]["findings"]
    bad = copy.deepcopy(decisions)
    bad[3]["after"] = True
    response = api.client.post(
        f"/v1/ai/recipes/modifications/{proposal['id']}/decisions",
        headers=headers,
        json={"decisions": bad},
    )
    assert response.status_code == 422
    retained = api.client.get(
        f"/v1/ai/recipes/modifications/{proposal['id']}", headers=headers
    ).json()
    assert retained["snapshot"] == selected["snapshot"]
    assert retained["revision"] == selected["revision"]


@pytest.mark.parametrize(
    "kind",
    [
        "name_only",
        "missing_dependency",
        "missing_container",
        "wrong_target",
        "null_container",
        "null_doneness",
    ],
)
def test_incomplete_conversion_fails_one_repair_without_writing_recipe(modification_api, kind):
    api, directory = modification_api
    created, headers = create_recipe(api, f"air-fryer-invalid-{kind}@example.com")
    operations = cookware_operations(created["version"]["snapshot"])
    if kind == "name_only":
        operations = operations[:1]
    elif kind == "missing_dependency":
        operations[2]["depends_on"] = []
    elif kind == "missing_container":
        operations = [op for op in operations if op["field"] != "notes"]
    elif kind in ("null_container", "null_doneness"):
        field = "notes" if kind == "null_container" else "doneness"
        next(op for op in operations if op["field"] == field)["after"] = None
    else:
        operations[0]["after"] = "烤箱"
    proposal = propose_cookware(api, directory, headers, created, operations)
    assert proposal["error"] == "invalid_output", proposal
    assert proposal["operations"] == []
    assert proposal["snapshot"] == created["version"]["snapshot"]
    current = api.client.get(f"/v1/recipes/{created['id']}", headers=headers)
    assert current.status_code == 200, current.text
    assert current.json()["version"] == created["version"]


def test_unconvertible_recipe_has_honest_explanation_and_no_operations(modification_api):
    api, directory = modification_api
    created, headers = create_recipe(api, "air-fryer-unconvertible@example.com")
    proposal = recorded_proposal(
        api,
        directory,
        headers,
        created,
        CORPUS["text"],
        CORPUS["intent"],
        {"operations": [], "explanation": "缺少鸡肉厚度和装载量，无法安全估算转换条件，请补充信息"},
    )
    assert proposal["error"] == "cannot_modify", proposal
    assert proposal["warnings"] == ["缺少鸡肉厚度和装载量，无法安全估算转换条件，请补充信息"]
    assert proposal["snapshot"] == created["version"]["snapshot"]
    assert proposal["operations"] == []
