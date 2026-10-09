"""Display-only comparison assistance through HTTP and recorded model boundaries."""

import json
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from contextlib import suppress
from copy import deepcopy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import cli, configure, recording
from tests.test_full_comparison import compare, create, ingredient, save, step


@pytest.fixture
def recordings(monkeypatch, tmp_path: Path) -> Path:
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def replay_api(recordings: Path, api: Api) -> Api:
    return api


def ambiguous_payload() -> dict:
    def uncertain(id: str) -> dict:
        return {
            "id": id,
            "action": "炒",
            "instruction": "炒熟",
            "ingredient_names": ["生抽"],
            "duration_seconds": 100,
            "unattended": False,
            "heat": None,
            "temperature_celsius": None,
            "cookware": "炒锅",
            "doneness": None,
            "depends_on": [],
        }

    return {
        "versions": {
            "before": {"dish_name": "完整比较菜", "servings": 2, "duration_seconds": 100},
            "after": {"dish_name": "完整比较菜", "servings": 2, "duration_seconds": 200},
        },
        "uncertain_steps": {
            "before": [uncertain("cook")],
            "after": [uncertain("a"), uncertain("b")],
        },
        "differences": {
            "conclusion": "general",
            "ingredients": [],
            "snapshot_fields": [],
            "steps": [
                {
                    "kind": "removed",
                    "field": "step",
                    "grade": "general",
                    "before_index": 1,
                    "after_index": None,
                },
                {
                    "kind": "added",
                    "field": "step",
                    "grade": "general",
                    "before_index": None,
                    "after_index": 1,
                },
                {
                    "kind": "added",
                    "field": "step",
                    "grade": "general",
                    "before_index": None,
                    "after_index": 2,
                },
            ],
            "methods": [],
        },
    }


def assist(api: Api, headers: dict, first: dict, second: dict):
    return api.client.get(
        f"/v1/recipes/{first['id']}/comparison-assistance",
        headers=headers,
        params={
            "from_version_id": first["version"]["id"],
            "to_version_id": second["version"]["id"],
        },
    )


def test_disabled_assistance_preserves_complete_deterministic_comparison(api: Api) -> None:
    headers = bearer(api.login("assistance-disabled@example.com"))
    first = create(api, headers)
    second = save(api, headers, first, steps=[step("a"), step("b")])
    deterministic = compare(api, headers, first, second).json()
    response = assist(api, headers, first, second)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["status"] == "unavailable"
    assert result["reason_code"] == "model_unavailable"
    assert result["alignments"] == [] and result["interpretation"] is None
    assert result["rules_version"] == deterministic["rules_version"]
    assert result["from_version_id"] == first["version"]["id"]
    assert result["to_version_id"] == second["version"]["id"]
    assert compare(api, headers, first, second).json() == deterministic


@pytest.mark.parametrize("target", ["a", "b"])
def test_replayed_high_confidence_overlay_preserves_rules_history_and_quota(
    replay_api: Api, recordings: Path, target: str
) -> None:
    recording(
        recordings,
        "comparison",
        ambiguous_payload(),
        {
            "alignments": [{"before_step_id": "cook", "after_step_id": target, "confidence": 0.95}],
            "interpretation": "两版都炒熟，后一版分成两步，更适合分批操作。",
        },
    )
    policies = cli("config", "get", "ai.policies")
    policies["comparison"] = {"timeout": 15, "retries": 0, "daily_limit": 0}
    configure("ai.policies", policies)
    models = cli("config", "get", "ai.models")
    models["small"].update(input_price=1, output_price=2)
    configure("ai.models", models)
    headers = bearer(replay_api.login("assistance-ready@example.com"))
    first = create(replay_api, headers)
    second = save(replay_api, headers, first, steps=[step("a"), step("b")])
    deterministic = compare(replay_api, headers, first, second).json()
    history = replay_api.client.get(f"/v1/recipes/{first['id']}/versions", headers=headers).json()
    quota = replay_api.client.get("/v1/ai/recipes/status", headers=headers).json()["remaining"]
    result = assist(replay_api, headers, first, second).json()
    assert result["status"] == "ready", result
    assert len(result["alignments"]) == 1
    pair = result["alignments"][0]
    assert (pair["before_step_id"], pair["after_step_id"]) == ("cook", target)
    assert pair["alignment"] == "ai_assisted" and pair["confidence"] == 0.95
    assert pair["source_type"] == "ai_estimated" and pair["basis"]["text"]
    assert result["interpretation"]["source_type"] == "ai_estimated"
    assert result["interpretation"]["basis"]["reason_code"] == "general_experience"
    assert compare(replay_api, headers, first, second).json() == deterministic
    assert (
        replay_api.client.get(f"/v1/recipes/{first['id']}/versions", headers=headers).json()
        == history
    )
    assert (
        replay_api.client.get("/v1/ai/recipes/status", headers=headers).json()["remaining"] == quota
    )
    user = replay_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["capability"] == "comparison"
    assert calls[0]["status"] == "succeeded" and calls[0]["cost"] > 0


def test_directional_shared_reuse_checks_permissions_before_cached_reads(
    replay_api: Api, recordings: Path
) -> None:
    payload = ambiguous_payload()
    recording(
        recordings,
        "comparison",
        payload,
        {
            "alignments": [{"before_step_id": "cook", "after_step_id": "a", "confidence": 0.95}],
            "interpretation": None,
        },
    )
    owner = bearer(replay_api.login("assistance-cache@example.com"))
    first = create(replay_api, owner)
    second = save(replay_api, owner, first, steps=[step("a"), step("b")])
    original = assist(replay_api, owner, first, second).json()
    assert original["status"] == "ready"
    recording(
        recordings,
        "comparison",
        payload,
        {
            "alignments": [{"before_step_id": "cook", "after_step_id": "b", "confidence": 0.95}],
            "interpretation": None,
        },
    )
    assert assist(replay_api, owner, first, second).json() == original
    other = bearer(replay_api.login("assistance-cache-other@example.com"))
    anchor = create(replay_api, other)
    assert assist(replay_api, other, first, second).status_code == 404
    assert assist(replay_api, other, {**first, "id": anchor["id"]}, second).status_code == 404
    for a, b in [(first, anchor), (anchor, first)]:
        assert assist(replay_api, owner, a, b).status_code == 404
    assert assist(replay_api, {}, first, second).status_code == 401
    different = replay_api.client.post(
        "/v1/recipes",
        headers=owner,
        json={"dish_name": "另一道比较菜", "snapshot": first["version"]["snapshot"]},
    )
    assert different.status_code == 201, different.text
    assert (
        assist(replay_api, owner, {**first, "id": different.json()["id"]}, second).status_code
        == 422
    )
    user = replay_api.client.get("/v1/me", headers=owner).json()
    assert len(cli("ai", "audit", "--user", user["id"])["calls"]) == 1


def prepared(api: Api):
    headers = bearer(api.login("assistance-matrix@example.com"))
    first = create(api, headers)
    second = save(api, headers, first, steps=[step("a"), step("b")])
    return headers, first, second


def model_output(confidence=0.95, target="a", interpretation=None):
    return {
        "alignments": [
            {"before_step_id": "cook", "after_step_id": target, "confidence": confidence}
        ],
        "interpretation": interpretation,
    }


@pytest.mark.parametrize(
    "confidence,accepted", [(0.2, False), (0.74999, False), (0.75, True), (1, True)]
)
def test_confidence_threshold_is_server_owned_and_low_outputs_stay_unaligned(
    replay_api: Api, recordings: Path, confidence, accepted
) -> None:
    recording(recordings, "comparison", ambiguous_payload(), model_output(confidence))
    headers, first, second = prepared(replay_api)
    deterministic = compare(replay_api, headers, first, second).json()
    result = assist(replay_api, headers, first, second).json()
    assert result["status"] == ("ready" if accepted else "unavailable")
    assert len(result["alignments"]) == int(accepted)
    assert result["interpretation"] is None
    if not accepted:
        assert result["reason_code"] == "low_confidence"
    assert compare(replay_api, headers, first, second).json() == deterministic


@pytest.mark.parametrize(
    "mode",
    [
        "illegal_before",
        "illegal_after",
        "duplicate_before",
        "nan",
        "infinity",
        "negative",
        "above_one",
        "string_confidence",
        "bad_json",
        "wrong_root",
        "missing_fields",
        "extra_grade",
        "multiline",
        "unicode_line",
        "oversized_summary",
        "verified_claim",
    ],
)
def test_malformed_or_unauthorized_outputs_are_failed_cached_attempts(
    replay_api: Api, recordings: Path, mode
) -> None:
    output = model_output()
    pair = output["alignments"][0]
    if mode == "illegal_before":
        pair["before_step_id"] = "private-other-step"
    elif mode == "illegal_after":
        pair["after_step_id"] = "private-other-step"
    elif mode == "duplicate_before":
        output["alignments"].append({**pair, "after_step_id": "b"})
    elif mode in {"nan", "infinity", "negative", "above_one", "string_confidence"}:
        pair["confidence"] = {
            "nan": float("nan"),
            "infinity": float("inf"),
            "negative": -0.1,
            "above_one": 1.1,
            "string_confidence": "high",
        }[mode]
    elif mode == "bad_json":
        output = "not JSON"
    elif mode == "wrong_root":
        output = []
    elif mode == "missing_fields":
        output = {}
    elif mode == "extra_grade":
        output["conclusion"] = "no_change"
    else:
        output["interpretation"] = {
            "multiline": "前一版\n后一版",
            "unicode_line": "前一版 后一版",
            "oversized_summary": "长" * 401,
            "verified_claim": "这个版本已验证更适合所有人。",
        }[mode]
    recording(recordings, "comparison", ambiguous_payload(), output)
    headers, first, second = prepared(replay_api)
    deterministic = compare(replay_api, headers, first, second).json()
    response = assist(replay_api, headers, first, second)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["status"] == "unavailable", result
    assert result["reason_code"] == "invalid_model_output"
    assert result["alignments"] == [] and result["interpretation"] is None
    assert assist(replay_api, headers, first, second).json() == result
    assert compare(replay_api, headers, first, second).json() == deterministic
    user = replay_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "failed"


def test_rule_and_confidence_policy_invalidation_does_not_rewrite_history(
    replay_api: Api, recordings: Path
) -> None:
    payload = ambiguous_payload()
    recording(recordings, "comparison", payload, model_output())
    headers, first, second = prepared(replay_api)
    original = assist(replay_api, headers, first, second).json()
    history = replay_api.client.get(f"/v1/recipes/{first['id']}/versions", headers=headers).json()
    recording(recordings, "comparison", payload, model_output(target="b"))
    configure("recipe.comparison_minor_threshold", 0.3)
    updated = assist(replay_api, headers, first, second).json()
    assert updated["rules_version"] != original["rules_version"]
    assert updated["alignments"][0]["after_step_id"] == "b"
    deterministic = compare(replay_api, headers, first, second).json()
    configure("recipe.comparison_ai_min_confidence", 0.99)
    stricter = assist(replay_api, headers, first, second).json()
    assert stricter["rules_version"] == updated["rules_version"]
    assert stricter["status"] == "unavailable" and stricter["reason_code"] == "low_confidence"
    assert stricter["alignments"] == []
    assert assist(replay_api, headers, first, second).json() == stricter
    assert compare(replay_api, headers, first, second).json() == deterministic
    assert (
        replay_api.client.get(f"/v1/recipes/{first['id']}/versions", headers=headers).json()
        == history
    )
    user = replay_api.client.get("/v1/me", headers=headers).json()
    assert len(cli("ai", "audit", "--user", user["id"])["calls"]) == 3


def test_reversed_pair_has_separate_cached_alignment(replay_api: Api, recordings: Path) -> None:
    payload = ambiguous_payload()
    recording(recordings, "comparison", payload, model_output())
    reverse = deepcopy(payload)
    reverse["versions"] = {
        "before": payload["versions"]["after"],
        "after": payload["versions"]["before"],
    }
    reverse["uncertain_steps"] = {
        "before": payload["uncertain_steps"]["after"],
        "after": payload["uncertain_steps"]["before"],
    }
    reverse["differences"]["steps"] = [
        {
            "kind": "removed",
            "field": "step",
            "grade": "general",
            "before_index": 1,
            "after_index": None,
        },
        {
            "kind": "removed",
            "field": "step",
            "grade": "general",
            "before_index": 2,
            "after_index": None,
        },
        {
            "kind": "added",
            "field": "step",
            "grade": "general",
            "before_index": None,
            "after_index": 1,
        },
    ]
    recording(
        recordings,
        "comparison",
        reverse,
        {
            "alignments": [{"before_step_id": "b", "after_step_id": "cook", "confidence": 0.95}],
            "interpretation": None,
        },
    )
    headers, first, second = prepared(replay_api)
    forward = assist(replay_api, headers, first, second).json()
    backward = assist(replay_api, headers, second, first).json()
    assert backward["status"] == "ready", backward
    assert backward["alignments"][0]["before_step_id"] == "b"
    assert backward["alignments"][0]["after_step_id"] == "cook"
    assert assist(replay_api, headers, first, second).json() == forward
    assert assist(replay_api, headers, second, first).json() == backward
    user = replay_api.client.get("/v1/me", headers=headers).json()
    assert len(cli("ai", "audit", "--user", user["id"])["calls"]) == 2


@pytest.mark.parametrize("mode", ["missing", "recorded_error"])
def test_replay_failures_degrade_and_reuse_without_losing_differences(
    replay_api: Api, recordings: Path, mode
) -> None:
    if mode == "recorded_error":
        recording(recordings, "comparison", ambiguous_payload(), model_output())
        path = next(recordings.glob("*.json"))
        path.write_text(json.dumps({"error": "synthetic unavailable"}), encoding="utf-8")
    headers, first, second = prepared(replay_api)
    deterministic = compare(replay_api, headers, first, second).json()
    result = assist(replay_api, headers, first, second).json()
    assert result["status"] == "unavailable" and result["reason_code"] == "model_unavailable"
    assert result["alignments"] == [] and result["interpretation"] is None
    recording(recordings, "comparison", ambiguous_payload(), model_output())
    assert assist(replay_api, headers, first, second).json() == result
    assert compare(replay_api, headers, first, second).json() == deterministic
    user = replay_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "failed"


def test_budget_denial_can_recover_without_a_cached_attempt(
    replay_api: Api, recordings: Path
) -> None:
    recording(recordings, "comparison", ambiguous_payload(), model_output())
    headers, first, second = prepared(replay_api)
    configure("ai.monthly_budget", 0)
    denied = assist(replay_api, headers, first, second).json()
    assert denied["reason_code"] == "monthly_budget" and denied["status"] == "unavailable"
    user = replay_api.client.get("/v1/me", headers=headers).json()
    assert cli("ai", "audit", "--user", user["id"])["calls"] == []
    configure("ai.monthly_budget", 1000)
    recovered = assist(replay_api, headers, first, second).json()
    assert recovered["status"] == "ready"
    assert len(cli("ai", "audit", "--user", user["id"])["calls"]) == 1


@pytest.fixture
def provider(monkeypatch, tmp_path: Path):
    state = {
        "receipts": [],
        "output": model_output(),
        "malformed": False,
        "delay": 0,
        "hold": False,
        "started": threading.Event(),
        "release": threading.Event(),
    }

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args):
            pass

        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            state["receipts"].append(body)
            state["started"].set()
            if state["hold"]:
                state["release"].wait(timeout=10)
            time.sleep(state["delay"])
            response = (
                {"invalid": "synthetic"}
                if state["malformed"]
                else {
                    "choices": [{"message": {"content": json.dumps(state["output"])}}],
                    "usage": {"prompt_tokens": 120, "completion_tokens": 80},
                }
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            # Expected disconnects when the public gateway enforces its timeout.
            with suppress(BrokenPipeError, ConnectionResetError):
                self.wfile.write(json.dumps(response).encode())

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    state["url"] = f"http://127.0.0.1:{server.server_port}"
    state["recordings"] = tmp_path
    monkeypatch.setenv("GRAMTREE_AI_MODE", "record")
    monkeypatch.setenv("GRAMTREE_AI_API_KEY", "synthetic-test-placeholder")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    try:
        yield state
    finally:
        state["release"].set()
        server.shutdown()
        server.server_close()
        thread.join()


@pytest.fixture
def provider_api(provider, api: Api) -> Api:
    models = cli("config", "get", "ai.models")
    models["small"].update(
        provider="synthetic-comparison",
        base_url=provider["url"],
        model="comparison-small",
        input_price=1,
        output_price=2,
    )
    configure("ai.models", models)
    return api


@pytest.mark.parametrize("hold", [False, True])
def test_concurrent_requests_reuse_one_actual_attempt_across_gateway_commits(
    provider_api: Api, provider, hold: bool
) -> None:
    provider["hold"] = hold
    provider["delay"] = 0 if hold else 0.4
    headers, first, second = prepared(provider_api)
    deterministic = compare(provider_api, headers, first, second).json()
    with ThreadPoolExecutor(max_workers=4) as pool:
        leader = pool.submit(assist, provider_api, headers, first, second)
        assert provider["started"].wait(timeout=5)
        followers = [pool.submit(assist, provider_api, headers, first, second) for _ in range(3)]
        try:
            overlays = [future.result(timeout=8) for future in followers]
        finally:
            provider["release"].set()
        original = leader.result(timeout=8)
    assert original.status_code == 200 and original.json()["status"] == "ready"
    for response in overlays:
        assert response.status_code == 200, response.text
        result = response.json()
        if hold:
            assert result["status"] == "unavailable"
            assert result["reason_code"] == "comparison_in_progress"
        else:
            assert result == original.json()
    assert assist(provider_api, headers, first, second).json() == original.json()
    assert compare(provider_api, headers, first, second).json() == deterministic
    assert len(provider["receipts"]) == 1
    user = provider_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "succeeded" and calls[0]["cost"] > 0


@pytest.mark.parametrize(
    "failure", ["semantic_output", "malformed_response", "network_refusal", "timeout"]
)
def test_provider_failures_are_audited_and_attempted_outcomes_cached(
    provider_api: Api, provider, failure: str
) -> None:
    provider["malformed"] = failure == "malformed_response"
    if failure == "semantic_output":
        provider["output"] = model_output(target="illegal-step")
    provider["delay"] = 0.4 if failure == "timeout" else 0
    if failure == "network_refusal":
        models = cli("config", "get", "ai.models")
        models["small"]["base_url"] = "http://127.0.0.1:1"
        configure("ai.models", models)
    if failure == "timeout":
        policies = cli("config", "get", "ai.policies")
        policies["comparison"]["timeout"] = 0.1
        configure("ai.policies", policies)
    headers, first, second = prepared(provider_api)
    deterministic = compare(provider_api, headers, first, second).json()
    first_result = assist(provider_api, headers, first, second).json()
    assert first_result["status"] == "unavailable"
    assert first_result["reason_code"] == (
        "invalid_model_output" if failure == "semantic_output" else "model_unavailable"
    )
    assert first_result["alignments"] == [] and first_result["interpretation"] is None
    assert assist(provider_api, headers, first, second).json() == first_result
    assert compare(provider_api, headers, first, second).json() == deterministic
    user = provider_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "failed"
    assert calls[0]["cost"] == (0.00028 if failure == "semantic_output" else 0)


def test_signed_measure_and_private_snapshot_data_never_cross_model_boundary(
    provider_api: Api, provider
) -> None:
    headers = bearer(provider_api.login("assistance-boundary@example.com"))
    measure = provider_api.client.post(
        "/v1/me/measures",
        headers=headers,
        json={"name": "边界专用量具", "kind": "spoon", "capacity_ml": 12},
    )
    assert measure.status_code == 201, measure.text
    preview = provider_api.client.post(
        "/v1/me/measures/input",
        headers=headers,
        json={"measure_id": measure.json()["id"], "quantity": 2, "base_unit": "ml"},
    )
    assert preview.status_code == 200, preview.text
    token = preview.json()["measure_input_token"]
    private_marker = "PRIVATE_PROVENANCE_BOUNDARY_MARKER"
    private_source = {
        "source": "author_filled",
        "original": private_marker,
        "basis": private_marker,
    }
    before_ingredient = ingredient(
        24,
        id="water",
        display_name="水",
        group="原液体",
        measure_input_token=token,
        preparation_source=private_source,
    )
    after_ingredient = ingredient(
        24,
        id="vinegar",
        display_name="醋",
        group="新液体",
        measure_input_token=token,
        preparation_source=private_source,
    )
    first = create(
        provider_api,
        headers,
        ingredients=[ingredient(replacement=private_marker + " before"), before_ingredient],
        description=private_marker,
        design_rationale=private_marker,
        steps=[
            step(
                "cook", notes=private_marker, why=private_marker, instruction_source=private_source
            )
        ],
    )
    second = save(
        provider_api,
        headers,
        first,
        ingredients=[ingredient(replacement=private_marker + " after"), after_ingredient],
        steps=[
            step(id, notes=private_marker, why=private_marker, instruction_source=private_source)
            for id in ("a", "b")
        ],
    )
    deterministic = compare(provider_api, headers, first, second).json()
    raw_changes = [
        c
        for row in deterministic["ingredients"]
        for c in row["changes"]
        if c["kind"] in {"added", "removed"}
    ]
    assert {c["kind"] for c in raw_changes} == {"added", "removed"}
    assert all(token in json.dumps(c) for c in raw_changes)
    assert private_marker in json.dumps(first["version"]["snapshot"])
    assert private_marker in json.dumps(second["version"]["snapshot"])
    assert assist(provider_api, headers, first, second).json()["status"] == "ready"
    assert len(provider["receipts"]) == 1
    serialized = json.dumps(provider["receipts"][0], ensure_ascii=False)
    assert token not in serialized
    assert private_marker not in serialized
    assert "边界专用量具" not in serialized
    assert provider["receipts"][0]["messages"][1]["content"]
    assert "recipe_id" not in provider["receipts"][0]["messages"][1]["content"]
    assert "owner_id" not in provider["receipts"][0]["messages"][1]["content"]
    user = provider_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "succeeded"
    request = json.loads(provider["receipts"][0]["messages"][1]["content"])
    assert {
        row["before"]["display_name"]
        for row in request["differences"]["ingredients"]
        if row["before"]
    } == {"水", "生抽"}
    assert {
        row["after"]["display_name"]
        for row in request["differences"]["ingredients"]
        if row["after"]
    } == {"醋", "生抽"}
    replacement_changes = [
        change
        for row in request["differences"]["ingredients"]
        for change in row["changes"]
        if change["field"] == "replacement"
    ]
    assert replacement_changes and all(
        "before" not in c and "after" not in c for c in replacement_changes
    )
    for marker in (
        token,
        private_marker,
        "边界专用量具",
        user["id"],
        "assistance-boundary@example.com",
    ):
        assert marker not in serialized
        assert all(
            marker not in path.read_text(encoding="utf-8")
            for path in provider["recordings"].glob("*.json")
        )
    assert len(list(provider["recordings"].glob("*.json"))) == 1


@pytest.mark.parametrize("case", ["deterministic", "unpaired", "duplicate_after"])
def test_only_uncertain_rows_enter_model_and_one_to_one_accepted_pair_pool(
    provider_api: Api, provider, case: str
) -> None:
    headers = bearer(provider_api.login("assistance-pool@example.com"))
    if case == "deterministic":
        first = create(provider_api, headers, steps=[step("prep", action="切"), step("cook")])
        second = save(
            provider_api,
            headers,
            first,
            steps=[step("new-prep", action="切"), step("a"), step("b")],
        )
        provider["output"] = {
            "alignments": [
                {"before_step_id": "prep", "after_step_id": "new-prep", "confidence": 0.95}
            ],
            "interpretation": None,
        }
        expected_before, expected_after = {"cook"}, {"a", "b"}
    elif case == "unpaired":
        first = create(provider_api, headers)
        second = save(provider_api, headers, first, steps=[])
        provider["output"] = model_output()
        expected_before, expected_after = set(), set()
    else:
        first = create(provider_api, headers, steps=[step("cook"), step("cook2")])
        second = save(provider_api, headers, first, steps=[step("a"), step("b"), step("c")])
        provider["output"] = {
            "alignments": [
                {"before_step_id": id, "after_step_id": "a", "confidence": 0.95}
                for id in ("cook", "cook2")
            ],
            "interpretation": None,
        }
        expected_before, expected_after = {"cook", "cook2"}, {"a", "b", "c"}
    deterministic = compare(provider_api, headers, first, second).json()
    assert any(
        row["alignment"]
        == (
            "deterministic"
            if case == "deterministic"
            else "unpaired"
            if case == "unpaired"
            else "uncertain"
        )
        for row in deterministic["steps"]
    )
    result = assist(provider_api, headers, first, second).json()
    assert result["status"] == "unavailable" and result["reason_code"] == "invalid_model_output"
    assert result["alignments"] == []
    sent = json.loads(provider["receipts"][0]["messages"][1]["content"])["uncertain_steps"]
    assert {row["id"] for row in sent["before"]} == expected_before
    assert {row["id"] for row in sent["after"]} == expected_after
    assert compare(provider_api, headers, first, second).json() == deterministic
    user = provider_api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "failed" and calls[0]["cost"] > 0


def test_configuration_denial_is_recoverable_without_consuming_an_attempt(
    replay_api: Api, recordings: Path
) -> None:
    recording(recordings, "comparison", ambiguous_payload(), model_output())
    headers, first, second = prepared(replay_api)
    routes = cli("config", "get", "ai.routes")
    configure("ai.routes", {**routes, "comparison": "unknown-tier"})
    result = assist(replay_api, headers, first, second).json()
    assert result["status"] == "unavailable" and result["reason_code"] == "configuration"
    user = replay_api.client.get("/v1/me", headers=headers).json()
    assert cli("ai", "audit", "--user", user["id"])["calls"] == []
    configure("ai.routes", routes)
    assert assist(replay_api, headers, first, second).json()["status"] == "ready"
    assert len(cli("ai", "audit", "--user", user["id"])["calls"]) == 1


@pytest.mark.parametrize("interpretation", [None, "后一版分成两步，可分批操作。"])
def test_interpretation_is_independent_of_rejected_low_confidence_pairs(
    replay_api: Api, recordings: Path, interpretation: str | None
) -> None:
    recording(
        recordings,
        "comparison",
        ambiguous_payload(),
        model_output(0.2, interpretation=interpretation),
    )
    headers, first, second = prepared(replay_api)
    deterministic = compare(replay_api, headers, first, second).json()
    result = assist(replay_api, headers, first, second).json()
    assert result["alignments"] == []
    assert result["status"] == ("ready" if interpretation else "unavailable")
    if interpretation:
        assert result["interpretation"]["value"] == interpretation
        assert result["interpretation"]["source_type"] == "ai_estimated"
        assert result["interpretation"]["basis"]["reason_code"] == "general_experience"
    else:
        assert result["reason_code"] == "low_confidence" and result["interpretation"] is None
    assert assist(replay_api, headers, first, second).json() == result
    assert compare(replay_api, headers, first, second).json() == deterministic
