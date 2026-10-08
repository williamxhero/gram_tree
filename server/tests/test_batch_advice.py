"""Large-batch advice through HTTP and synthetic gateway replay, without ORM assertions."""

import copy
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import cli, configure, recording
from tests.test_recipes import recipe_input

CORPUS = json.loads(
    Path(__file__).with_name("fixtures").joinpath("ai/batch_advice_corpus.json").read_text("utf-8")
)


@pytest.fixture
def replay_dir(monkeypatch, tmp_path: Path) -> Path:
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def batch_api(replay_dir: Path, api: Api) -> Api:
    return api


def create(api: Api) -> tuple[dict, dict]:
    headers = bearer(api.login("batch-author@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    return response.json(), headers


def path(saved: dict) -> str:
    return f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}/batch-advice"


def request(api: Api, saved: dict, headers: dict, target: int = 4) -> dict:
    response = api.client.post(path(saved), headers=headers, json={"target_servings": target})
    assert response.status_code == 200, response.text
    return response.json()


def test_disabled_advice_preserves_conversion_and_version(api: Api) -> None:
    saved, headers = create(api)
    before = api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    low = request(api, saved, headers, 3)
    assert low["eligible"] is False
    assert low["error"] == "below_batch_threshold"
    result = request(api, saved, headers)
    assert result["eligible"] is True
    assert result["original_servings"] == 2
    assert result["target_servings"] == 4
    assert result["recipe_id"] == saved["id"]
    assert result["version_id"] == saved["version"]["id"]
    assert result["advice"] is None
    assert result["error"] == "model_unavailable"
    assert result["status"] == {"available": False, "remaining": 50, "reason": "model_unavailable"}
    conversion = api.client.get(
        f"/v1/recipes/{saved['id']}/servings?target_servings=4", headers=headers
    ).json()["conversion"]
    assert [s["duration_seconds"] for s in conversion["steps"]] == [900, 120]
    assert conversion["steps"][1]["batch_warning"] is True
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved
    assert api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json() == before
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    assert cli("ai", "audit", "--user", user_id)["calls"] == []


def synthetic(api: Api) -> tuple[dict, dict]:
    headers = bearer(api.login("batch-replay@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=CORPUS["recipe"])
    assert response.status_code == 201, response.text
    saved = response.json()
    assert saved["version"]["snapshot"] == CORPUS["snapshot"]
    return saved, headers


def audit(api: Api, headers: dict) -> dict:
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    return cli("ai", "audit", "--user", user_id)


def replay_payload(saved: dict, target: int = 4) -> dict:
    return {"snapshot": saved["version"]["snapshot"], "target_servings": target}


def unchanged(api: Api, saved: dict, headers: dict, history: dict) -> None:
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved
    assert api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json() == history
    conversion = api.client.get(
        f"/v1/recipes/{saved['id']}/servings?target_servings=4", headers=headers
    ).json()["conversion"]
    assert [s["duration_seconds"] for s in conversion["steps"]] == [900, 300]
    assert conversion["ingredients"][0]["display_quantity"] == 600


def test_materialized_browser_replay_is_read_only_and_accounted(
    batch_api: Api, replay_dir: Path
) -> None:
    # Exercise the same operator tool and corpus used for real browser integration.
    result = subprocess.run(
        [
            sys.executable,
            str(Path(__file__).parents[2] / "tool/ai_replay_corpus.py"),
            "--out",
            str(replay_dir),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"},
    )
    assert result.returncode == 0, result.stderr
    configure(
        "ai.models",
        {
            "small": {
                "provider": "replay",
                "model": "batch-small",
                "input_price": 1,
                "output_price": 2,
            }
        },
    )
    saved, headers = synthetic(batch_api)
    history = batch_api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    advice = request(batch_api, saved, headers)
    assert advice["error"] is None, advice
    assert advice["advice"] == CORPUS["valid"]
    assert advice["status"] == {"available": True, "remaining": 49, "reason": None}
    assert advice["advice"]["steps"][0]["suggested_duration_seconds"] == 900
    assert advice["advice"]["steps"][1]["suggested_duration_seconds"] == 360
    assert advice["advice"]["steps"][1]["batch_count"] == 2
    assert all(s["source"] == "ai_estimated" for s in advice["advice"]["steps"])
    unchanged(batch_api, saved, headers, history)
    operator = audit(batch_api, headers)
    assert len(operator["calls"]) == 1
    assert operator["calls"][0]["capability"] == "batch_advice"
    assert operator["calls"][0]["model"] == "batch-small"
    assert operator["calls"][0]["status"] == "succeeded"
    assert operator["log_count"] == 1
    assert operator["totals"]["batch_advice"]["cost"] > 0


def test_threshold_config_and_selected_version_are_authoritative(
    batch_api: Api, replay_dir: Path
) -> None:
    saved, headers = synthetic(batch_api)
    configure("recipe.scaling_batch_multiplier", 3)
    assert request(batch_api, saved, headers, 5)["eligible"] is False
    recording(replay_dir, "batch_advice", replay_payload(saved, 6), CORPUS["valid"])
    assert request(batch_api, saved, headers, 6)["advice"] == CORPUS["valid"]
    converted = batch_api.client.get(
        f"/v1/recipes/{saved['id']}/servings?target_servings=6", headers=headers
    ).json()["conversion"]
    assert all(s["batch_warning"] for s in converted["steps"])
    configure("recipe.scaling_batch_multiplier", 2)
    snapshot = copy.deepcopy(saved["version"]["snapshot"])
    snapshot["servings"] = 4
    newer = batch_api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        headers=headers,
        json={"snapshot": snapshot, "change_note": "四人份原版"},
    )
    assert newer.status_code == 201, newer.text
    current = newer.json()
    history = batch_api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    old_path = f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}"
    old_before = batch_api.client.get(old_path, headers=headers).json()
    assert request(batch_api, current, headers, 4)["eligible"] is False
    recording(replay_dir, "batch_advice", replay_payload(saved), CORPUS["valid"])
    selected = request(batch_api, saved, headers, 4)
    assert selected["original_servings"] == 2
    assert selected["version_id"] == saved["version"]["id"]
    assert selected["advice"] == CORPUS["valid"]
    assert batch_api.client.get(old_path, headers=headers).json() == old_before
    assert batch_api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == current
    assert (
        batch_api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
        == history
    )
    assert len(audit(batch_api, headers)["calls"]) == 2


def test_advice_is_private_and_rejects_foreign_recipe_versions(batch_api: Api) -> None:
    saved, headers = synthetic(batch_api)
    assert batch_api.client.post(path(saved), json={"target_servings": 4}).status_code == 401
    other_headers = bearer(batch_api.login("batch-intruder@example.com"))
    assert (
        batch_api.client.post(
            path(saved), headers=other_headers, json={"target_servings": 4}
        ).status_code
        == 404
    )
    another = batch_api.client.post("/v1/recipes", headers=headers, json=CORPUS["recipe"]).json()
    mismatched = f"/v1/recipes/{another['id']}/versions/{saved['version']['id']}/batch-advice"
    assert (
        batch_api.client.post(mismatched, headers=headers, json={"target_servings": 4}).status_code
        == 404
    )
    assert audit(batch_api, headers)["calls"] == []
    assert audit(batch_api, other_headers)["calls"] == []


@pytest.mark.parametrize("target", [0, 21, True, "4", 4.5])
def test_invalid_target_never_calls_model(batch_api: Api, target) -> None:
    saved, headers = synthetic(batch_api)
    response = batch_api.client.post(path(saved), headers=headers, json={"target_servings": target})
    assert response.status_code == 422
    assert audit(batch_api, headers)["calls"] == []


@pytest.mark.parametrize(
    "reason", ["monthly_budget", "daily_quota", "model_unavailable", "configuration"]
)
def test_unavailable_advice_does_not_affect_manual_conversion(
    batch_api: Api, replay_dir: Path, reason: str
) -> None:
    saved, headers = synthetic(batch_api)
    history = batch_api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    if reason == "monthly_budget":
        configure("ai.monthly_budget", 0)
    elif reason == "daily_quota":
        configure("ai.policies", {"batch_advice": {"daily_limit": 0}})
    elif reason == "configuration":
        configure("ai.routes", {})
    else:
        # Gateway replay explicitly records provider failure (including timeout).
        recording(replay_dir, "batch_advice", replay_payload(saved), CORPUS["valid"])
        for entry in replay_dir.glob("*.json"):
            entry.write_text(json.dumps({"error": "timeout"}), encoding="utf-8")
    result = request(batch_api, saved, headers)
    assert result["advice"] is None
    assert result["eligible"] is True
    assert result["error"] == reason
    assert result["status"]["available"] is False
    assert result["status"]["reason"] == reason
    unchanged(batch_api, saved, headers, history)
    calls = audit(batch_api, headers)["calls"]
    assert len(calls) == (1 if reason == "model_unavailable" else 0)
    if calls:
        assert calls[0]["status"] == "failed"


def test_daily_quota_consumed_once_per_request_and_manual_save_survives(
    batch_api: Api, replay_dir: Path
) -> None:
    configure("ai.policies", {"batch_advice": {"daily_limit": 1}})
    saved, headers = synthetic(batch_api)
    recording(replay_dir, "batch_advice", replay_payload(saved), CORPUS["valid"])
    first = request(batch_api, saved, headers)
    assert first["advice"] == CORPUS["valid"]
    assert first["status"]["remaining"] == 0
    second = request(batch_api, saved, headers)
    assert second["error"] == "daily_quota"
    assert second["advice"] is None
    assert len(audit(batch_api, headers)["calls"]) == 1
    manual = batch_api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        headers=headers,
        json={"snapshot": saved["version"]["snapshot"], "change_note": "手动保存照常可用"},
    )
    assert manual.status_code == 201, manual.text
    assert manual.json()["version"]["version_number"] == 2


def bad_output(kind: str) -> object:
    bad = copy.deepcopy(CORPUS["valid"])
    step = bad["steps"][0]
    if kind == "unknown_step":
        step["step_id"] = "not-in-selected-version"
    elif kind == "duplicate":
        bad["steps"].append(copy.deepcopy(step))
    elif kind == "whole_rewrite":
        bad["snapshot"] = CORPUS["snapshot"]
    elif kind == "temperature_write":
        step["temperature_celsius"] = 200
    elif kind == "negative_duration":
        step["suggested_duration_seconds"] = -1
    elif kind == "duration_overflow":
        step["suggested_duration_seconds"] = 86401
    elif kind == "coerced_duration":
        step["suggested_duration_seconds"] = "900"
    elif kind == "boolean_duration":
        step["suggested_duration_seconds"] = True
    elif kind == "too_many_batches":
        step["batch_count"] = 101
    elif kind == "nonfinite_confidence":
        step["confidence"] = float("nan")
    elif kind == "false_source":
        step["source"] = "verified"
    elif kind == "missing_source":
        del step["source"]
    elif kind == "blank_basis":
        step["basis"] = "   "
    elif kind == "empty":
        bad["steps"] = []
    elif kind == "invalid_json":
        return "not valid JSON"
    return bad


@pytest.mark.parametrize(
    "kind",
    [
        "unknown_step",
        "duplicate",
        "whole_rewrite",
        "temperature_write",
        "negative_duration",
        "duration_overflow",
        "coerced_duration",
        "boolean_duration",
        "too_many_batches",
        "nonfinite_confidence",
        "false_source",
        "missing_source",
        "blank_basis",
        "empty",
        "invalid_json",
    ],
)
def test_invalid_output_is_repaired_at_most_once_without_recipe_writes(
    batch_api: Api, replay_dir: Path, kind: str
) -> None:
    saved, headers = synthetic(batch_api)
    history = batch_api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    payload = replay_payload(saved)
    bad = bad_output(kind)
    recording(replay_dir, "batch_advice", payload, bad)
    recording(replay_dir, "batch_advice", {**payload, "repair": True}, bad)
    result = request(batch_api, saved, headers)
    assert result["error"] == "invalid_model_output"
    assert result["advice"] is None
    assert result["status"] == {
        "available": False,
        "remaining": 49,
        "reason": "invalid_model_output",
    }
    calls = audit(batch_api, headers)["calls"]
    assert len(calls) == 2
    assert {c["capability"] for c in calls} == {"batch_advice"}
    unchanged(batch_api, saved, headers, history)


def test_one_successful_repair_uses_one_daily_request_and_original_snapshot(
    batch_api: Api, replay_dir: Path
) -> None:
    configure("ai.policies", {"batch_advice": {"daily_limit": 1}})
    saved, headers = synthetic(batch_api)
    payload = replay_payload(saved)
    recording(replay_dir, "batch_advice", payload, bad_output("unknown_step"))
    recording(replay_dir, "batch_advice", {**payload, "repair": True}, json.dumps(CORPUS["valid"]))
    result = request(batch_api, saved, headers)
    assert result["advice"] == CORPUS["valid"]
    assert result["error"] is None
    assert result["status"]["remaining"] == 0
    assert len(audit(batch_api, headers)["calls"]) == 2


def test_repair_cannot_bypass_reserved_monthly_budget(batch_api: Api, replay_dir: Path) -> None:
    saved, headers = synthetic(batch_api)
    history = batch_api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    configure("ai.monthly_budget", 1.5)
    payload = replay_payload(saved)
    recording(replay_dir, "batch_advice", payload, bad_output("unknown_step"))
    for entry in replay_dir.glob("*.json"):
        data = json.loads(entry.read_text("utf-8"))
        data["usage"] = {}
        entry.write_text(json.dumps(data), encoding="utf-8")
    recording(replay_dir, "batch_advice", {**payload, "repair": True}, CORPUS["valid"])
    result = request(batch_api, saved, headers)
    assert result["error"] == "monthly_budget"
    assert result["advice"] is None
    assert len(audit(batch_api, headers)["calls"]) == 1
    unchanged(batch_api, saved, headers, history)


def test_standalone_steps_are_not_related_and_no_steps_do_not_call_model(
    batch_api: Api, replay_dir: Path
) -> None:
    saved, headers = synthetic(batch_api)
    body = copy.deepcopy(CORPUS["recipe"])
    body["snapshot"]["steps"].append(
        {"id": "rest", "instruction": "等待下次做饭", "duration_seconds": 60}
    )
    saved = batch_api.client.post("/v1/recipes", headers=headers, json=body).json()
    bad = copy.deepcopy(CORPUS["valid"])
    bad["steps"][0]["step_id"] = "rest"
    payload = replay_payload(saved)
    recording(replay_dir, "batch_advice", payload, bad)
    recording(replay_dir, "batch_advice", {**payload, "repair": True}, bad)
    assert request(batch_api, saved, headers)["error"] == "invalid_model_output"
    body["snapshot"]["steps"] = [{"id": "rest", "instruction": "稍候", "duration_seconds": 60}]
    unrelated = batch_api.client.post("/v1/recipes", headers=headers, json=body).json()
    assert request(batch_api, unrelated, headers)["error"] == "no_related_steps"
    assert len(audit(batch_api, headers)["calls"]) == 2
