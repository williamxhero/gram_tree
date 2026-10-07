"""Recorded quantification acceptance at HTTP and operator CLI seams."""

import copy
import json
import subprocess
import sys
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import cli, recording
from tests.test_ingredients_attributes import FULL_ATTRIBUTES, FULL_ID, _record, _write
from tests.test_recipe_reproducibility import draft


def test_browser_corpus_materializes_a_real_saved_recipe_proposal(quantification_api):
    api, directory = quantification_api
    root = Path(__file__).resolve().parents[2]
    subprocess.run(
        [sys.executable, str(root / "tool/ai_replay_corpus.py"), "--out", str(directory)],
        check=True,
    )
    corpus = json.loads(
        (root / "server/tests/fixtures/ai/quantification_corpus.json").read_text("utf-8")
    )
    headers = bearer(api.login("quantification-browser-corpus@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=corpus["recipe"]).json()
    response = api.client.post(
        f"/v1/recipes/{created['id']}/quantification",
        headers=headers,
        json={"base_version_id": created["version"]["id"]},
    )
    assert response.status_code == 200, response.text
    assert response.json()["suggestions"][0]["value"] == "300"


def test_heating_suggestions_include_observable_heat_and_separate_doneness(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-heat@example.com"))
    body = draft()
    body["snapshot"]["ingredients"] = [
        {"id": "chicken", "display_name": "鸡肉", "quantity": 300, "unit": "g"}
    ]
    body["snapshot"]["steps"] = [{"id": "cook", "instruction": "煮鸡肉"}]
    created = api.client.post("/v1/recipes", headers=headers, json=body).json()
    problems = created["version"]["reproducibility"]["problems"]
    assert {p["position"]["field"] for p in problems} == {"duration_seconds", "heat", "doneness"}
    values = {
        "duration_seconds": "600",
        "heat": "水面持续冒小泡",
        "doneness": "食品温度计测中心温度达到 74°C",
    }
    proposal = suggest(
        api,
        directory,
        headers,
        created,
        output={
            "suggestions": [
                {
                    "problem_id": p["id"],
                    "value": values[p["position"]["field"]],
                    "basis": "按 300 克鸡肉估算，熟度另用温度计判断",
                    "confidence": "low",
                    "baseline": "两人份，鸡肉厚 2 厘米",
                    "adjustment": "较厚时延长加热并检查中心温度",
                }
                for p in problems
            ]
        },
    )
    response = api.client.post(
        f"/v1/recipes/{created['id']}/quantification/{proposal['id']}/decisions",
        headers=headers,
        json={"accept_all": True},
    )
    assert response.status_code == 201, response.text
    saved = response.json()
    step = saved["version"]["snapshot"]["steps"][0]
    assert step["duration_seconds"] == 600 and step["heat"] == "水面持续冒小泡"
    assert step["doneness"] == "食品温度计测中心温度达到 74°C"
    for field in ("duration_source", "heat_source", "doneness_source"):
        assert step[field]["source"] == "ai_estimated" and step[field]["confidence_level"] == "low"
    assert saved["version"]["reproducibility"]["remaining_count"] == 0


def test_library_role_density_and_count_weights_are_in_replay_context(quantification_api, tmp_path):
    api, directory = quantification_api
    library = _write(
        tmp_path / "library",
        "1.0.0",
        [_record(FULL_ID, "测试酱油", "ceshijiangyou", FULL_ATTRIBUTES)],
    )
    cli("ingredients", "import", str(library))
    headers = bearer(api.login("quantification-library@example.com"))
    body = draft()
    body["snapshot"]["ingredients"][0].update(
        ingredient_id=FULL_ID, display_name="测试酱油", group="调味", functional=True
    )
    first = api.client.post("/v1/recipes", headers=headers, json=body).json()
    proposed = suggest(
        api,
        directory,
        headers,
        first,
        context=[
            {
                "id": "salt",
                "role": "调味",
                "functional": True,
                "category": "调料",
                "density": {"value": 1.15, "source": "AI 起草、待核对", "status": "ai_draft"},
                "unit_weight": {
                    "value": [{"unit": "片", "grams": 5.0}],
                    "source": "AI 起草、待核对",
                    "status": "ai_draft",
                },
            },
            {
                "id": "water",
                "role": "未指定",
                "functional": False,
                "category": None,
                "density": None,
                "unit_weight": None,
            },
        ],
    )
    assert len(proposed["suggestions"]) == 2


@pytest.fixture
def quantification_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def quantification_api(quantification_recordings, api: Api):
    return api, quantification_recordings


def suggest(api, directory, headers, detail, *, output=None, expected_status=200, context=None):
    version = detail["version"]
    problems = version["reproducibility"]["problems"]
    suggestions = [
        {
            "problem_id": p["id"],
            "value": "3" if p["position"]["item_id"] == "salt" else "300",
            "unit": "g" if p["position"]["item_id"] == "salt" else "ml",
            "basis": "按同方 300 毫升水的调味比例估算"
            if p["position"]["item_id"] == "salt"
            else "以常见中号碗容量为基准",
            "confidence": "medium",
            "baseline": "以 300 毫升水为基准"
            if p["position"]["item_id"] == "salt"
            else "中号碗约 300 毫升",
            "adjustment": "偏淡时每次加 1 克盐"
            if p["position"]["item_id"] == "salt"
            else "按实际碗容量用量杯测量",
        }
        for p in problems
    ]
    payload = {
        "snapshot": version["snapshot"],
        "problems": problems,
        "ingredient_context": context
        if context is not None
        else [
            {
                "id": i["id"],
                "role": i.get("group") or "未指定",
                "category": None,
                "density": None,
                "unit_weight": None,
                "functional": i["functional"],
            }
            for i in version["snapshot"]["ingredients"]
        ],
    }
    recording(directory, "quantify", payload, output or {"suggestions": suggestions})
    response = api.client.post(
        f"/v1/recipes/{detail['id']}/quantification",
        headers=headers,
        json={"base_version_id": version["id"]},
    )
    assert response.status_code == expected_status, response.text
    return response.json()


def test_accept_creates_immutable_ai_version_and_durable_decision(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantifier@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    proposed = suggest(api, directory, headers, created)
    assert len(proposed["suggestions"]) == 2
    salt = proposed["suggestions"][0]
    assert salt["confidence"] == "medium"
    assert salt["basis"] and salt["baseline"] and salt["adjustment"]
    response = api.client.post(
        f"/v1/recipes/{created['id']}/quantification/{proposed['id']}/decisions",
        headers=headers,
        json={"decisions": [{"problem_id": salt["problem_id"], "decision": "accept"}]},
    )
    assert response.status_code == 201, response.text
    saved = response.json()
    assert saved["version"]["id"] != created["version"]["id"]
    assert saved["version"]["reproducibility"]["remaining_count"] == 1
    amount = saved["version"]["snapshot"]["ingredients"][0]
    assert (amount["quantity"], amount["unit"]) == (3, "g")
    assert amount["quantity_source"] == {
        "source": "ai_estimated",
        "original": "0 少许",
        "confidence": 0.7,
        "confidence_level": "medium",
        "basis": salt["basis"],
        "baseline": salt["baseline"],
        "adjustment": salt["adjustment"],
    }
    old = api.client.get(
        f"/v1/recipes/{created['id']}/versions/{created['version']['id']}", headers=headers
    ).json()
    assert old["version"] == created["version"]
    user = api.client.get("/v1/me", headers=headers).json()
    events = cli("recipes", "quantification-receipts", "--user", user["id"])["items"]
    assert len(events) == 1
    assert events[0]["content"] == {
        "recipe_version_id": saved["version"]["id"],
        "problem_id": salt["problem_id"],
        "problem_type": "ambiguous",
        "ai_value": "3",
        "ai_unit": "g",
        "ai_confidence": "medium",
        "decision": "accept",
        "final_value": "3",
        "final_unit": "g",
    }
    retry = api.client.post(
        f"/v1/recipes/{created['id']}/quantification/{proposed['id']}/decisions",
        headers=headers,
        json={"decisions": [{"problem_id": salt["problem_id"], "decision": "accept"}]},
    )
    assert retry.status_code == 201 and retry.json()["version"]["id"] == saved["version"]["id"]


def test_modify_ignore_and_accept_all_preserve_honest_sources(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-decisions@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    proposed = suggest(api, directory, headers, created)
    salt, water = proposed["suggestions"]
    route = f"/v1/recipes/{created['id']}/quantification/{proposed['id']}/decisions"
    response = api.client.post(
        route,
        headers=headers,
        json={
            "decisions": [
                {"problem_id": salt["problem_id"], "decision": "modify", "value": "2", "unit": "g"},
                {"problem_id": water["problem_id"], "decision": "ignore"},
            ]
        },
    )
    assert response.status_code == 201, response.text
    saved = response.json()
    assert (
        saved["version"]["snapshot"]["ingredients"][0]["quantity_source"]["source"]
        == "author_filled"
    )
    assert saved["version"]["snapshot"]["ingredients"][1]["quantity"] == 1
    result = saved["version"]["reproducibility"]
    assert result["remaining_count"] == 1 and result["state"] == "incomplete"
    assert result["problems"][0]["status"] == "ignored"
    assert api.client.post(route, headers=headers, json={"accept_all": True}).status_code == 409
    remaining = suggest(api, directory, headers, saved)
    accepted = api.client.post(
        f"/v1/recipes/{created['id']}/quantification/{remaining['id']}/decisions",
        headers=headers,
        json={"accept_all": True},
    )
    assert accepted.status_code == 201, accepted.text
    final = accepted.json()
    assert final["version"]["reproducibility"]["state"] == "reproducible"
    assert final["version"]["reproducibility"]["field_completeness"] == 1
    assert (
        final["version"]["snapshot"]["ingredients"][0]["quantity_source"]["source"]
        == "author_filled"
    )
    user = api.client.get("/v1/me", headers=headers).json()
    receipts = cli("recipes", "quantification-receipts", "--user", user["id"])["items"]
    assert {(e["content"]["decision"], e["content"]["final_value"]) for e in receipts} == {
        ("modify", "2"),
        ("ignore", "1"),
        ("accept", "300"),
    }


def test_quantification_permissions_stale_base_and_untrusted_decisions(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-owner@example.com"))
    other = bearer(api.login("quantification-outsider@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    proposed = suggest(api, directory, headers, created)
    proposal_route = f"/v1/recipes/{created['id']}/quantification"
    route = f"{proposal_route}/{proposed['id']}/decisions"
    assert (
        api.client.post(
            proposal_route, json={"base_version_id": created["version"]["id"]}
        ).status_code
        == 401
    )
    assert (
        api.client.post(
            proposal_route, headers=other, json={"base_version_id": created["version"]["id"]}
        ).status_code
        == 404
    )
    assert api.client.post(route, headers=other, json={"accept_all": True}).status_code == 404
    problem_id = proposed["suggestions"][0]["problem_id"]
    for decision in [
        {"problem_id": problem_id, "decision": "accept", "value": "100", "unit": "g"},
        {
            "problem_id": problem_id,
            "decision": "modify",
            "value": "4",
            "unit": "g",
            "source": "verified",
        },
        {"problem_id": problem_id, "decision": "modify", "value": "NaN", "unit": "g"},
        {"problem_id": problem_id, "decision": "modify", "value": "4", "unit": "碗"},
        {"problem_id": "invented", "decision": "ignore"},
    ]:
        assert (
            api.client.post(route, headers=headers, json={"decisions": [decision]}).status_code
            == 422
        )
    newer = copy.deepcopy(created["version"]["snapshot"])
    newer["ingredients"][0].update(quantity=5, unit="g")
    edited = api.client.post(
        f"/v1/recipes/{created['id']}/versions", headers=headers, json={"snapshot": newer}
    )
    assert edited.status_code == 201, edited.text
    assert api.client.post(route, headers=headers, json={"accept_all": True}).status_code == 409
    assert (
        api.client.post(
            proposal_route, headers=headers, json={"base_version_id": created["version"]["id"]}
        ).status_code
        == 409
    )
    assert (
        api.client.get(f"/v1/recipes/{created['id']}", headers=headers).json()["version"][
            "snapshot"
        ]["ingredients"][0]["quantity"]
        == 5
    )


@pytest.mark.parametrize("ignore_sibling", [True, False])
def test_ambiguous_modification_cannot_hide_beside_unhandled_fragment(
    quantification_api, ignore_sibling
):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-ambiguous-modify@example.com"))
    body = draft()
    body["snapshot"]["ingredients"] = [
        {"id": "water", "display_name": "水", "quantity": 300, "unit": "ml"}
    ]
    body["snapshot"]["steps"] = [{"id": "mix", "instruction": "先加少许水，再加适量水"}]
    first = api.client.post("/v1/recipes", headers=headers, json=body).json()
    problems = first["version"]["reproducibility"]["problems"]
    proposal = suggest(
        api,
        directory,
        headers,
        first,
        output={
            "suggestions": [
                {
                    "problem_id": p["id"],
                    "value": "10 毫升",
                    "basis": "润湿容器",
                    "confidence": "low",
                }
                for p in problems
            ]
        },
    )
    decisions = [{"problem_id": problems[0]["id"], "decision": "modify", "value": "适量"}]
    if ignore_sibling:
        decisions.append({"problem_id": problems[1]["id"], "decision": "ignore"})
    response = api.client.post(
        f"/v1/recipes/{first['id']}/quantification/{proposal['id']}/decisions",
        headers=headers,
        json={"decisions": decisions},
    )
    assert response.status_code == 422, response.text
    current = api.client.get(f"/v1/recipes/{first['id']}", headers=headers).json()
    assert current["version"]["id"] == first["version"]["id"]


def test_new_manual_nodes_cannot_manufacture_ai_sources(quantification_api):
    api, _ = quantification_api
    headers = bearer(api.login("quantification-new-node@example.com"))
    first = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    snapshot = copy.deepcopy(first["version"]["snapshot"])
    forged = {
        "source": "ai_estimated",
        "original": "模型建议",
        "basis": "伪造依据",
        "confidence": 0.9,
    }
    snapshot["ingredients"].append(
        {
            "id": "manual-new",
            "display_name": "糖",
            "quantity": 10,
            "unit": "g",
            "quantity_source": forged,
            "preparation_source": forged,
        }
    )
    snapshot["steps"].append(
        {
            "id": "manual-step",
            "instruction": "搅拌均匀",
            "instruction_source": forged,
            "duration_source": forged,
            "heat_source": forged,
            "temperature_source": forged,
            "doneness_source": forged,
        }
    )
    response = api.client.post(
        f"/v1/recipes/{first['id']}/versions", headers=headers, json={"snapshot": snapshot}
    )
    assert response.status_code == 201, response.text
    saved = response.json()["version"]["snapshot"]
    for node in (saved["ingredients"][-1], saved["steps"][-1]):
        for key, source in node.items():
            if key.endswith("_source"):
                assert source["source"] == "author_filled"
                assert source["basis"] is None


def test_same_field_fragments_compose_without_overwrite(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-fragments@example.com"))
    body = draft()
    body["snapshot"]["ingredients"] = [
        {"id": "water", "display_name": "水", "quantity": 300, "unit": "ml"}
    ]
    body["snapshot"]["steps"] = [{"id": "mix", "instruction": "先加少许水，再加适量水"}]
    created = api.client.post("/v1/recipes", headers=headers, json=body).json()
    problems = created["version"]["reproducibility"]["problems"]
    assert len(problems) == 2
    proposed = suggest(
        api,
        directory,
        headers,
        created,
        output={
            "suggestions": [
                {
                    "problem_id": problems[0]["id"],
                    "value": "10 毫升",
                    "basis": "先润湿容器",
                    "confidence": "high",
                },
                {
                    "problem_id": problems[1]["id"],
                    "value": "20 毫升",
                    "basis": "按剩余水量补足",
                    "confidence": "low",
                },
            ]
        },
    )
    saved = api.client.post(
        f"/v1/recipes/{created['id']}/quantification/{proposed['id']}/decisions",
        headers=headers,
        json={"accept_all": True},
    )
    assert saved.status_code == 201, saved.text
    step = saved.json()["version"]["snapshot"]["steps"][0]
    assert step["instruction"] == "先加10 毫升水，再加20 毫升水"
    assert step["instruction_source"]["original"] == "少许；适量"
    assert step["instruction_source"]["confidence_level"] == "low"
    assert saved.json()["version"]["reproducibility"]["remaining_count"] == 0


def test_sequential_fragments_retain_ignored_status_and_prior_evidence(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-sequential@example.com"))
    body = draft()
    body["snapshot"]["ingredients"] = [
        {"id": "water", "display_name": "水", "quantity": 300, "unit": "ml"}
    ]
    body["snapshot"]["steps"] = [{"id": "mix", "instruction": "先加少许水，再加适量水"}]
    first = api.client.post("/v1/recipes", headers=headers, json=body).json()
    problems = first["version"]["reproducibility"]["problems"]
    proposal = suggest(
        api,
        directory,
        headers,
        first,
        output={
            "suggestions": [
                {
                    "problem_id": problems[0]["id"],
                    "value": "10 毫升",
                    "basis": "先润湿容器",
                    "confidence": "high",
                },
                {
                    "problem_id": problems[1]["id"],
                    "value": "20 毫升",
                    "basis": "按剩余水量补足",
                    "confidence": "low",
                },
            ]
        },
    )
    saved = api.client.post(
        f"/v1/recipes/{first['id']}/quantification/{proposal['id']}/decisions",
        headers=headers,
        json={
            "decisions": [
                {"problem_id": problems[0]["id"], "decision": "accept"},
                {"problem_id": problems[1]["id"], "decision": "ignore"},
            ]
        },
    ).json()
    remaining = saved["version"]["reproducibility"]["problems"]
    assert len(remaining) == 1 and remaining[0]["status"] == "ignored"
    assert remaining[0]["position"]["start"] == 11
    second = suggest(
        api,
        directory,
        headers,
        saved,
        output={
            "suggestions": [
                {
                    "problem_id": remaining[0]["id"],
                    "value": "20 毫升",
                    "basis": "按剩余水量补足",
                    "confidence": "low",
                },
            ]
        },
    )
    final = api.client.post(
        f"/v1/recipes/{first['id']}/quantification/{second['id']}/decisions",
        headers=headers,
        json={"accept_all": True},
    ).json()
    step = final["version"]["snapshot"]["steps"][0]
    assert step["instruction"] == "先加10 毫升水，再加20 毫升水"
    assert step["instruction_source"]["original"] == "少许；适量"
    assert step["instruction_source"]["basis"] == "先润湿容器；按剩余水量补足"
    assert step["instruction_source"]["confidence_level"] == "low"
    assert final["version"]["reproducibility"]["state"] == "reproducible"


def test_cutting_and_amount_suggestions_in_one_field_are_consistent(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-overlap@example.com"))
    body = draft()
    body["snapshot"]["ingredients"] = [
        {
            "id": "carrot",
            "display_name": "胡萝卜",
            "quantity": 100,
            "unit": "g",
            "preparation": "取少许切丁",
        }
    ]
    created = api.client.post("/v1/recipes", headers=headers, json=body).json()
    problems = created["version"]["reproducibility"]["problems"]
    assert len(problems) == 2
    proposal = suggest(
        api,
        directory,
        headers,
        created,
        output={
            "suggestions": [
                {
                    "problem_id": p["id"],
                    "value": "取10 克切成 1 厘米丁" if p["position"]["start"] is None else "10 克",
                    "basis": "按小块均匀受热",
                    "confidence": "medium",
                }
                for p in problems
            ]
        },
    )
    route = f"/v1/recipes/{created['id']}/quantification/{proposal['id']}/decisions"
    # A whole-field replacement may not silently accept an ignored overlapping problem.
    whole = next(p for p in problems if p["position"]["start"] is None)
    fragment = next(p for p in problems if p["position"]["start"] is not None)
    partial = api.client.post(
        route,
        headers=headers,
        json={
            "decisions": [
                {"problem_id": whole["id"], "decision": "accept"},
                {"problem_id": fragment["id"], "decision": "ignore"},
            ]
        },
    )
    assert partial.status_code == 422, partial.text
    saved = api.client.post(route, headers=headers, json={"accept_all": True})
    assert saved.status_code == 201, saved.text
    item = saved.json()["version"]["snapshot"]["ingredients"][0]
    assert item["preparation"] == "取10 克切成 1 厘米丁"
    assert item["preparation_source"]["source"] == "ai_estimated"
    assert saved.json()["version"]["reproducibility"]["remaining_count"] == 0


@pytest.mark.parametrize(
    "invalid",
    [
        "no_baseline",
        "missing",
        "duplicate",
        "blank",
        "nonfinite",
        "unknown_unit",
        "confidence",
        "extra_source",
    ],
)
def test_invalid_model_output_never_creates_a_version(quantification_api, invalid):
    api, directory = quantification_api
    headers = bearer(api.login(f"quantification-invalid-{invalid}@example.com"))
    first = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    suggestions = [
        {
            "problem_id": p["id"],
            "value": "3",
            "unit": "g",
            "basis": "按同方用量估算",
            "confidence": "medium",
            "baseline": "两人份",
            "adjustment": "每次加一克",
        }
        for p in first["version"]["reproducibility"]["problems"]
    ]
    if invalid == "no_baseline":
        suggestions[0].pop("baseline")
        suggestions[0].pop("adjustment")
    elif invalid == "missing":
        suggestions.pop()
    elif invalid == "duplicate":
        suggestions[1] = suggestions[0]
    elif invalid == "blank":
        suggestions[0]["basis"] = "   "
    elif invalid == "nonfinite":
        suggestions[0]["value"] = "Infinity"
    elif invalid == "unknown_unit":
        suggestions[0]["unit"] = "碗"
    elif invalid == "confidence":
        suggestions[0]["confidence"] = "certain"
    else:
        suggestions[0]["source"] = "verified"
    error = suggest(
        api, directory, headers, first, output={"suggestions": suggestions}, expected_status=503
    )
    assert error["error"]["code"] == "invalid_quantification"
    current = api.client.get(f"/v1/recipes/{first['id']}", headers=headers).json()
    assert current["version"] == first["version"]
    user = api.client.get("/v1/me", headers=headers).json()
    assert cli("recipes", "quantification-receipts", "--user", user["id"])["items"] == []


def test_quantification_presave_guard_does_not_overwrite_newer_edits(quantification_api):
    api, _ = quantification_api
    headers = bearer(api.login("quantification-draft-guard@example.com"))
    first = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    newer = copy.deepcopy(first["version"]["snapshot"])
    newer["servings"] = 4
    current = api.client.post(
        f"/v1/recipes/{first['id']}/versions", headers=headers, json={"snapshot": newer}
    ).json()
    stale = api.client.post(
        f"/v1/recipes/{first['id']}/versions",
        headers=headers,
        json={
            "snapshot": first["version"]["snapshot"],
            "base_version_id": first["version"]["id"],
            "expected_current_version_id": first["version"]["id"],
        },
    )
    assert stale.status_code == 409, stale.text
    assert (
        api.client.get(f"/v1/recipes/{first['id']}", headers=headers).json()["version"]["id"]
        == current["version"]["id"]
    )


def test_manual_edit_cannot_replace_unchanged_owned_basis(quantification_api):
    api, directory = quantification_api
    headers = bearer(api.login("quantification-provenance@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=draft()).json()
    proposal = suggest(api, directory, headers, created)
    accepted = api.client.post(
        f"/v1/recipes/{created['id']}/quantification/{proposal['id']}/decisions",
        headers=headers,
        json={"accept_all": True},
    ).json()
    edited = copy.deepcopy(accepted["version"]["snapshot"])
    edited["ingredients"][0]["quantity_source"]["basis"] = "客户端编造的依据"
    edited["ingredients"][1]["quantity"] = 350
    saved = api.client.post(
        f"/v1/recipes/{created['id']}/versions", headers=headers, json={"snapshot": edited}
    )
    assert saved.status_code == 201, saved.text
    items = saved.json()["version"]["snapshot"]["ingredients"]
    assert (
        items[0]["quantity_source"]
        == accepted["version"]["snapshot"]["ingredients"][0]["quantity_source"]
    )
    assert items[1]["quantity_source"]["source"] == "author_filled"
