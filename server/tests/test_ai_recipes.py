"""One-line creation acceptance tests use HTTP and operator CLI, never ORM assertions."""

import copy
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input

TEXT = "想做一道小朋友能吃的、不辣的宫保鸡丁"
CORPUS = json.loads(
    Path(__file__)
    .with_name("fixtures")
    .joinpath("ai/recipe_corpus.json")
    .read_text(encoding="utf-8")
)


def cli(*args: str) -> dict:
    env = {**os.environ, "PYTHONIOENCODING": "utf-8"}
    result = subprocess.run(
        [sys.executable, "-m", "gramtree.cli", *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        env=env,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return (
        json.loads(result.stdout.splitlines()[-1]) if result.stdout.lstrip().startswith("{") else {}
    )


def configure(key: str, value) -> None:
    cli(
        "config",
        "set",
        key,
        json.dumps(value),
        "--by",
        "acceptance-test",
        "--reason",
        "SPEC-003.1 acceptance",
    )


def recording(directory: Path, capability: str, payload: dict, output) -> None:
    raw = json.dumps(
        {"capability": capability, "prompt_version": "one-line-v1", "input": payload},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    key = hashlib.sha256(raw.encode()).hexdigest()
    directory.joinpath(key + ".json").write_text(
        json.dumps({"output": output, "usage": CORPUS["usage"]}, ensure_ascii=False),
        encoding="utf-8",
    )


def generation_payload() -> dict:
    return {
        "text": TEXT,
        "intent": {**CORPUS["intent"], "servings": 2},
        "profile": None,
        "family": None,
        "cookware_profile": None,
    }


@pytest.fixture
def recordings(monkeypatch, tmp_path: Path) -> Path:
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    recording(tmp_path, "intent", {"text": TEXT}, CORPUS["intent"])
    recording(tmp_path, "embedding", {"text": "宫保鸡丁"}, CORPUS["embedding"])
    recording(tmp_path, "generate", generation_payload(), CORPUS["valid"])
    recording(
        tmp_path,
        "normalize",
        {"names": ["鸡腿肉", "盐"], "candidates": []},
        CORPUS["normalization"],
    )
    return tmp_path


@pytest.fixture
def replay_api(recordings: Path, api: Api) -> Api:
    return api


def begin(api: Api, headers: dict) -> dict:
    response = api.client.post("/v1/ai/recipes/requests", headers=headers, json={"text": TEXT})
    assert response.status_code == 200, response.text
    return response.json()


def generate(api: Api, headers: dict, request_id: str) -> dict:
    response = api.client.post(
        f"/v1/ai/recipes/requests/{request_id}/generate", headers=headers, json={}
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_disabled_gateway_does_not_disable_recipe_apis(api: Api) -> None:
    headers = bearer(api.login("ai-status@example.com"))
    response = api.client.get("/v1/ai/recipes/status", headers=headers)
    assert response.status_code == 200
    assert response.json() == {"available": False, "remaining": 50, "reason": "model_unavailable"}
    saved = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert saved.status_code == 201, saved.text
    recipe_id = saved.json()["id"]
    assert api.client.get(f"/v1/recipes/{recipe_id}", headers=headers).status_code == 200
    assert (
        api.client.get(
            f"/v1/recipes/{recipe_id}/servings?target_servings=4", headers=headers
        ).status_code
        == 200
    )


def test_ai_status_requires_auth(api: Api) -> None:
    assert api.client.get("/v1/ai/recipes/status").status_code == 401


def test_retrieval_first_generate_edit_save_index_and_events(
    replay_api: Api, recordings: Path
) -> None:
    api = replay_api
    tokens = api.login("ai-author@example.com")
    headers = bearer(tokens)
    private_headers = bearer(api.login("ai-other@example.com"))
    own = api.client.post("/v1/recipes", json=recipe_input(), headers=headers).json()
    other = api.client.post("/v1/recipes", json=recipe_input(), headers=private_headers).json()
    found = begin(api, headers)
    assert found["local_fallback"] is False
    assert {r["recipe_id"] for r in found["recipes"]} == {own["id"]}
    assert other["id"] not in json.dumps(found)
    assert len(found["questions"]) == 2
    assert found["intent"]["taste"] == ["不辣"]
    user = api.client.get("/v1/me", headers=headers).json()
    audit = cli("ai", "audit", "--user", user["id"])
    assert not any(c["capability"] == "generate" for c in audit["calls"])
    result = generate(api, headers, found["request_id"])
    assert result["error"] is None, result
    assert result["status"]["remaining"] == 49
    draft = result["draft"]
    assert draft["recipe"]["ai_assisted"] is True
    assert draft["recipe"]["snapshot"]["servings"] == 2
    assert draft["cuisine"] and draft["rationale"]
    assert all(
        i["quantity_source"]["source"] == "ai_estimated"
        for i in draft["recipe"]["snapshot"]["ingredients"]
    )
    assert result["safety"]["can_save"] is True
    edited = copy.deepcopy(draft["recipe"])
    edited["snapshot"]["ingredients"][0]["quantity"] = 320
    saved = api.client.post(
        f"/v1/ai/recipes/requests/{found['request_id']}/save", headers=headers, json=edited
    )
    assert saved.status_code == 201, saved.text
    detail = saved.json()
    assert detail["author"]["id"] == user["id"]
    assert detail["visibility"] == "private"
    assert detail["version"]["version_number"] == 1
    assert detail["version"]["ai_assisted"] is True
    assert (
        detail["version"]["snapshot"]["ingredients"][0]["quantity_source"]["source"]
        == "author_filled"
    )
    assert (
        detail["version"]["snapshot"]["ingredients"][1]["quantity_source"]["source"]
        == "ai_estimated"
    )
    # Retrying save returns the same immutable recipe, not a duplicate.
    retry = api.client.post(
        f"/v1/ai/recipes/requests/{found['request_id']}/save", headers=headers, json=edited
    )
    assert retry.json()["id"] == detail["id"]
    text = "宫保鸡丁 鸡腿肉 盐 鸡腿肉切丁 炒"
    recording(recordings, "embedding", {"text": text}, CORPUS["embedding"])
    # Manual recipe fixtures have a different snapshot text; record those too.
    recording(
        recordings, "embedding", {"text": "宫保鸡丁 鸡腿肉 干辣椒 腌 炒"}, CORPUS["embedding"]
    )
    configure(
        "ai.models",
        {
            "small": {"provider": "replay", "model": "small", "input_price": 1, "output_price": 2},
            "large": {"provider": "replay", "model": "large", "input_price": 1, "output_price": 2},
            "vector": {"provider": "replay", "model": "vector", "input_price": 1},
        },
    )
    assert cli("ai", "index")["completed"] == 3
    audit = cli("ai", "audit", "--user", user["id"])
    assert audit["embeddings"] == {"ready": 3}
    assert audit["log_count"] == len(audit["calls"])
    assert audit["totals"]["embedding"]["cost"] > 0
    assert all(c["prompt_version"] == "one-line-v1" for c in audit["calls"])
    assert {e["stage"] for e in audit["events"]} == {"request", "choice", "questions", "result"}
    saved_event = next(e for e in audit["events"] if e.get("saved"))
    assert saved_event["version_id"] == detail["version"]["id"]
    assert TEXT not in json.dumps(audit["events"], ensure_ascii=False)
    assert api.client.get(f"/v1/recipes/{detail['id']}", headers=private_headers).status_code == 404


@pytest.mark.parametrize("one_line", ["野生菌炖鸡", "河豚汤"])
def test_high_risk_request_is_rejected_without_model_calls(replay_api: Api, one_line: str) -> None:
    headers = bearer(replay_api.login("risk@example.com"))
    response = replay_api.client.post(
        "/v1/ai/recipes/requests", headers=headers, json={"text": one_line}
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "unsafe_ai_request"


def test_local_fallback_preserves_input_and_existing_recipes(api: Api) -> None:
    headers = bearer(api.login("local@example.com"))
    own = api.client.post("/v1/recipes", json=recipe_input(), headers=headers).json()
    found = begin(api, headers)
    assert found["text"] == TEXT
    assert found["local_fallback"] is True
    assert found["recipes"][0]["recipe_id"] == own["id"]
    existing = api.client.post(
        f"/v1/ai/recipes/requests/{found['request_id']}/existing",
        headers=headers,
        json={"recipe_id": own["id"]},
    )
    assert existing.json()["id"] == own["id"]
    result = generate(api, headers, found["request_id"])
    assert result["error"] == "model_unavailable"
    assert result["draft"] is None
    assert api.client.get("/v1/recipes", headers=headers).status_code == 200


@pytest.mark.parametrize("reason", ["daily_quota", "monthly_budget", "model_unavailable"])
def test_generation_degradation_is_explicit_and_manual_apis_survive(
    replay_api: Api, reason: str, recordings: Path
) -> None:
    headers = bearer(replay_api.login("quota@example.com"))
    found = begin(replay_api, headers)
    if reason == "daily_quota":
        configure(
            "ai.policies",
            {"intent": {}, "embedding": {}, "normalize": {}, "generate": {"daily_limit": 0}},
        )
    elif reason == "monthly_budget":
        configure("ai.monthly_budget", 0)
    else:
        recording(recordings, "generate", generation_payload(), None)
        raw = json.dumps(
            {
                "capability": "generate",
                "prompt_version": "one-line-v1",
                "input": generation_payload(),
            },
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        recordings.joinpath(hashlib.sha256(raw.encode()).hexdigest() + ".json").write_text(
            '{"error":"timeout"}', encoding="utf-8"
        )
    result = generate(replay_api, headers, found["request_id"])
    assert result["error"] == reason
    assert result["status"]["available"] is False
    assert (
        replay_api.client.post("/v1/recipes", headers=headers, json=recipe_input()).status_code
        == 201
    )
    assert replay_api.client.get("/v1/recipes", headers=headers).status_code == 200


@pytest.mark.parametrize("kind", ["missing", "quantity_text", "claims"])
def test_bad_output_gets_one_repair(replay_api: Api, recordings: Path, kind: str) -> None:
    headers = bearer(replay_api.login("repair@example.com"))
    found = begin(replay_api, headers)
    bad = copy.deepcopy(CORPUS["valid"])
    if kind == "missing":
        del bad["recipe"]["snapshot"]["servings"]
        errors = ["recipe.snapshot.servings:missing"]
    elif kind == "quantity_text":
        bad["recipe"]["snapshot"]["ingredients"][0]["quantity"] = "少许"
        errors = ["recipe.snapshot.ingredients.0.quantity:float_parsing"]
    else:
        bad["rationale"] = "降血糖"
        errors = ["禁止疗效措辞：降血糖"]
    recording(recordings, "generate", generation_payload(), bad)
    repair = {**generation_payload(), "repair": {"errors": errors, "previous": bad}}
    recording(recordings, "generate", repair, CORPUS["valid"])
    result = generate(replay_api, headers, found["request_id"])
    assert result["error"] is None, result
    user = replay_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len([c for c in calls if c["capability"] == "generate"]) == 2
    assert result["status"]["remaining"] == 49


def test_second_bad_output_fails_without_saving(replay_api: Api, recordings: Path) -> None:
    headers = bearer(replay_api.login("bad@example.com"))
    found = begin(replay_api, headers)
    bad = {}
    recording(recordings, "generate", generation_payload(), bad)
    repair = {
        **generation_payload(),
        "repair": {
            "errors": ["recipe:missing", "rationale:missing", "cuisine:missing"],
            "previous": bad,
        },
    }
    recording(recordings, "generate", repair, bad)
    result = generate(replay_api, headers, found["request_id"])
    assert result["error"] == "invalid_output"
    assert replay_api.client.get("/v1/recipes", headers=headers).json()["items"] == []
    assert found["text"] == TEXT


def test_dangerous_doneness_and_numeric_ratio_are_visible_warnings(
    replay_api: Api, recordings: Path
) -> None:
    headers = bearer(replay_api.login("warnings@example.com"))
    found = begin(replay_api, headers)
    unsafe = copy.deepcopy(CORPUS["valid"])
    step = unsafe["recipe"]["snapshot"]["steps"][1]
    step["instruction"] = "鸡肉炒至表面变白"
    step["doneness"] = "表面变白"
    unsafe["recipe"]["snapshot"]["ingredients"][1]["quantity"] = 30
    recording(recordings, "generate", generation_payload(), unsafe)
    result = generate(replay_api, headers, found["request_id"])
    assert result["error"] is None
    assert result["numeric_warnings"]
    assert any(f["rule_id"] == "poultry-cook-through" for f in result["safety"]["findings"])


def test_generation_session_does_not_cross_accounts(replay_api: Api) -> None:
    author = bearer(replay_api.login("owner@example.com"))
    other = bearer(replay_api.login("intruder@example.com"))
    found = begin(replay_api, author)
    response = replay_api.client.post(
        f"/v1/ai/recipes/requests/{found['request_id']}/generate", headers=other, json={}
    )
    assert response.status_code == 404
