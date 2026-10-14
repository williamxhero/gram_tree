"""Real HTTP observations exercise rules; no Redis counter/state injection."""

import base64
import json
import subprocess
import uuid
from concurrent.futures import ThreadPoolExecutor
from typing import Any, cast

from gramtree.cli import main as cli
from gramtree.risk.captcha import MemoryCaptchaAdapter
from tests.accounts_support import Api, bearer


def set_config(key: str, value: str) -> None:
    result = subprocess.run(
        [
            "gramtree",
            "config",
            "set",
            key,
            value,
            "--by",
            "test",
            "--reason",
            "risk HTTP acceptance",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr


def configure(**values: int) -> None:
    for name, value in values.items():
        set_config(f"risk.{name}", str(value))


def actions(capsys) -> list[dict[str, Any]]:
    assert cli(["risk", "actions"]) == 0
    return json.loads(capsys.readouterr().out)


def solve(api: Api, response, headers: dict[str, str] | None = None) -> None:
    assert response.status_code == 403, response.text
    assert response.json()["error"]["code"] == "risk_captcha_required"
    accepted = api.client.post(
        "/v1/risk/captcha",
        headers=headers or {},
        json={"challenge_id": response.headers["X-Risk-Challenge"], "response": "ok"},
    )
    assert accepted.status_code == 200, accepted.text
    assert accepted.json() == {"accepted": True, "access_restored": True}


def test_captcha_is_bound_to_requester_and_consumed_once(api: Api) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=2, throttle_points=10)
    headers = {"X-Device-ID": "owner-device"}
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    challenged = api.client.get("/v1/me", headers=headers)
    assert challenged.status_code == 403
    body = {"challenge_id": challenged.headers["X-Risk-Challenge"], "response": "ok"}
    assert (
        api.client.post(
            "/v1/risk/captcha", json=body, headers={"X-Device-ID": "other-device"}
        ).status_code
        == 400
    )
    assert api.client.post("/v1/risk/captcha", json=body, headers=headers).status_code == 200
    assert api.client.post("/v1/risk/captcha", json=body, headers=headers).status_code == 400
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    assert api.client.get("/v1/me", headers=headers).status_code == 429


def test_rule_tiers_audit_expiration_and_manual_device_release(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(
        short_request_limit=2,
        throttle_seconds=1,
        temporary_block_seconds=1,
        throttle_points=10,
        temporary_block_points=10,
        permanent_block_points=10,
    )
    device = {"X-Device-ID": "tier-device"}
    assert api.client.get("/v1/me", headers=device).status_code == 401
    challenged = api.client.get("/v1/me", headers=device)
    solve(api, challenged, device)
    assert api.client.get("/v1/me", headers=device).status_code == 401
    slowed = api.client.get("/v1/me", headers=device)
    assert slowed.status_code == 429
    assert slowed.json()["error"]["code"] == "risk_slowed"
    assert int(slowed.headers["Retry-After"]) >= 1
    api.clock.advance(seconds=2)
    temporary = api.client.get("/v1/me", headers=device)
    assert temporary.status_code == 403
    assert temporary.json()["error"]["code"] == "risk_temporarily_blocked"
    api.clock.advance(seconds=2)
    permanent = api.client.get("/v1/me", headers=device)
    assert permanent.status_code == 403
    assert permanent.json()["error"]["code"] == "risk_permanently_blocked"
    rows = [row for row in actions(capsys) if row["subject_type"] == "device"]
    assert [row["level"] for row in rows] == [
        "captcha",
        "throttle",
        "temporary_block",
        "permanent_block",
    ]
    assert rows[0]["lift_reason"] == "captcha"
    assert rows[1]["lift_reason"] == rows[2]["lift_reason"] == "expired"
    assert rows[3]["ends_at"] is None and rows[3]["lifted_at"] is None
    assert all(row["rule"] == "short_burst" and row["evidence"]["count"] >= 2 for row in rows)
    assert "tier-device" not in json.dumps(rows)
    # Permanent enforcement has no business-clock expiration.
    api.clock.advance(days=8)
    assert (
        api.client.get("/v1/me", headers=device).json()["error"]["code"]
        == "risk_permanently_blocked"
    )
    assert cli(["risk", "lift", rows[-1]["id"], "--by", "reviewer"]) == 0
    assert json.loads(capsys.readouterr().out) == {"lifted": True}
    assert api.client.get("/v1/me", headers=device).status_code == 401
    updated = next(row for row in actions(capsys) if row["id"] == rows[-1]["id"])
    assert updated["lift_reason"] == "manual:reviewer" and updated["lifted_at"]


def test_throttle_allows_reduced_budget_without_new_rule(api: Api) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(
        short_request_limit=2, short_window_seconds=10, throttle_seconds=30, throttle_points=10
    )
    headers = {"X-Device-ID": "throttle-budget-device"}
    api.client.get("/v1/me", headers=headers)
    solve(api, api.client.get("/v1/me", headers=headers), headers)
    api.client.get("/v1/me", headers=headers)
    assert api.client.get("/v1/me", headers=headers).status_code == 429
    api.clock.advance(seconds=11)
    # Change the live threshold so only the reduced quota, not another rule, is active.
    configure(short_request_limit=100)
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    limited = api.client.get("/v1/me", headers=headers)
    assert limited.status_code == 429 and limited.headers["X-Risk-Level"] == "throttle"


def test_detail_scanning_one_thousand_distinct_ids_in_ten_minutes(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=1000000, detail_repeat_limit=10000, sequential_limit=1000)
    set_config("rate.detail.ip_per_minute", "10000")
    set_config("rate.detail.device_per_minute", "10000")
    headers = {"X-Device-ID": "scanner-device"}
    for _ in range(999):
        response = api.client.get(f"/v1/recipes/{uuid.uuid4()}", headers=headers)
        assert response.status_code == 401, response.text
        api.clock.advance(milliseconds=500)
    challenged = api.client.get(f"/v1/recipes/{uuid.uuid4()}", headers=headers)
    assert challenged.json()["error"]["code"] == "risk_captcha_required"
    row = actions(capsys)[0]
    assert row["rule"] == "sequential_detail"
    assert row["evidence"]["distinct_count"] == 1000
    solve(api, challenged, headers)
    assert api.client.get("/v1/me", headers=headers).status_code == 401


def test_stable_zero_dwell_detail_pattern_and_isolation(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(detail_repeat_limit=3, sequential_limit=10000)
    headers = {"X-Device-ID": "rapid-device"}
    for _ in range(3):
        assert api.client.get(f"/v1/recipes/{uuid.uuid4()}", headers=headers).status_code == 401
        api.clock.advance(milliseconds=100)
    challenged = api.client.get(f"/v1/recipes/{uuid.uuid4()}", headers=headers)
    assert challenged.json()["error"]["code"] == "risk_captcha_required"
    row = actions(capsys)[0]
    assert row["rule"] == "rapid_detail" and row["evidence"]["repeat_count"] == 3
    assert api.client.get("/v1/me", headers={"X-Device-ID": "unrelated-device"}).status_code == 401
    solve(api, challenged, headers)


def test_three_full_days_of_uniform_http_requests(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(uniform_daily_limit=24, uniform_days=3, uniform_bucket_seconds=3600)
    # Observe all 72 completed hourly buckets, then enter the next bucket.
    api.clock.now = api.clock.now.replace(minute=0, second=0, microsecond=0)
    headers = {"X-Device-ID": "uniform-device"}
    for _ in range(72):
        response = api.client.get("/v1/me", headers=headers)
        assert response.status_code == 401, response.text
        api.clock.advance(hours=1)
    challenged = api.client.get("/v1/me", headers=headers)
    assert challenged.json()["error"]["code"] == "risk_captcha_required"
    row = actions(capsys)[0]
    assert row["rule"] == "uniform_daily_access"
    assert row["evidence"]["days"] == 3 and row["evidence"]["count"] == 72
    solve(api, challenged, headers)
    assert api.client.get("/v1/me", headers=headers).status_code == 401


def test_five_accounts_on_one_device_and_verified_captcha_recovery(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    tokens = [
        api.login(f"multi-{number}@example.com", device="shared-device") for number in range(5)
    ]
    headers = bearer(tokens[-1])
    challenged = api.client.get("/v1/me", headers=headers)
    assert challenged.json()["error"]["code"] == "risk_captcha_required"
    row = actions(capsys)[0]
    assert row["rule"] == "multi_account_device" and row["evidence"]["account_count"] == 5
    solve(api, challenged, headers)
    assert api.client.get("/v1/me", headers=headers).status_code == 200


def test_subnet_new_accounts_trigger_but_repeated_existing_login_does_not(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    # TestClient's numeric source is supplied through the ASGI transport, never X-Forwarded-For.
    cast(Any, api.client._transport).client = ("192.0.2.5", 50000)
    configure(subnet_new_account_limit=3)
    first = api.login("subnet-first@example.com")
    api.login("subnet-first@example.com")
    assert actions(capsys) == []
    api.login("subnet-second@example.com")
    last = api.login("subnet-third@example.com")
    # Subnet-scoped login policy must bind its challenge to the actual requester subnet.
    response = api.client.get("/v1/me", headers=bearer(last))
    assert response.json()["error"]["code"] == "risk_captcha_required"
    solve(api, response, bearer(last))
    assert api.client.get("/v1/me", headers=bearer(last)).status_code == 200
    rows = actions(capsys)
    assert any(row["rule"] == "subnet_new_accounts" for row in rows)
    assert "192.0.2.5" not in json.dumps(rows)
    assert first["user"]["id"] != last["user"]["id"]


def test_captcha_expiry_cannot_reuse_old_answer(api: Api) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=2, captcha_seconds=1)
    api.client.get("/v1/me")
    challenged = api.client.get("/v1/me")
    api.clock.advance(seconds=2)
    rejected = api.client.post(
        "/v1/risk/captcha",
        json={
            "challenge_id": challenged.headers["X-Risk-Challenge"],
            "response": "ok",
        },
    )
    assert rejected.status_code == 400


def test_authenticated_account_burst_can_recover_without_risk_dependency_deadlock(
    api: Api, capsys
) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    headers = bearer(api.login("account-recovery@example.com"))
    configure(short_request_limit=3)
    # Distinct ASGI source IPs keep the IP bucket below threshold while account risk accumulates.
    for number in range(2):
        cast(Any, api.client._transport).client = (f"198.51.100.{number + 1}", 50000)
        assert api.client.get("/v1/me", headers=headers).status_code == 200
    cast(Any, api.client._transport).client = ("198.51.100.3", 50000)
    challenged = api.client.get("/v1/me", headers=headers)
    assert challenged.json()["error"]["code"] == "risk_captcha_required"
    assert actions(capsys)[0]["subject_type"] == "account"
    solve(api, challenged, headers)
    assert api.client.get("/v1/me", headers=headers).status_code == 200


def test_recurrence_waits_for_configured_score_thresholds(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(
        short_request_limit=2,
        throttle_seconds=1,
        temporary_block_seconds=1,
        throttle_points=20,
        temporary_block_points=40,
        permanent_block_points=80,
    )
    headers = {"X-Device-ID": "configured-tier-device"}
    source = 0

    def request():
        nonlocal source
        source += 1
        cast(Any, api.client._transport).client = (f"198.51.100.{source}", 50000)
        return api.client.get("/v1/me", headers=headers)

    assert request().status_code == 401
    solve(api, request(), headers)
    assert request().status_code == 401  # one recovery grace observation
    assert request().status_code == 401  # score 10 is not throttle 20
    assert request().json()["error"]["code"] == "risk_slowed"
    api.clock.advance(seconds=2)
    assert request().status_code == 401  # score 30 is not temporary 40
    assert request().json()["error"]["code"] == "risk_temporarily_blocked"
    api.clock.advance(seconds=2)
    for _ in range(3):
        assert request().status_code == 401  # scores 50, 60, 70 are not permanent 80
    assert request().json()["error"]["code"] == "risk_permanently_blocked"
    assert [row["level"] for row in actions(capsys) if row["subject_type"] == "device"] == [
        "captcha",
        "throttle",
        "temporary_block",
        "permanent_block",
    ]


def test_one_captcha_recovers_companion_active_subjects_and_audits_each(api: Api, capsys) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=2)
    headers = {"X-Device-ID": "companion-device"}
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    device = api.client.get("/v1/me", headers=headers)
    ip = api.client.get("/v1/me")
    assert device.status_code == ip.status_code == 403
    assert device.headers["X-Risk-Challenge"] != ip.headers["X-Risk-Challenge"]
    solve(api, device, headers)
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    rows = actions(capsys)
    assert len(rows) == 2
    assert all(row["lifted_at"] and row["lift_reason"] == "captcha" for row in rows)


def test_parallel_challenges_and_single_use_recovery_keep_one_audited_action(
    api: Api, capsys
) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=2)
    headers = {"X-Device-ID": "parallel-challenge-device"}
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    with ThreadPoolExecutor(max_workers=6) as pool:
        challenged = list(pool.map(lambda _: api.client.get("/v1/me", headers=headers), range(6)))
    assert all(response.status_code == 403 for response in challenged)
    challenge_ids = {response.headers["X-Risk-Challenge"] for response in challenged}
    assert len(challenge_ids) == 1
    body = {"challenge_id": next(iter(challenge_ids)), "response": "ok"}
    with ThreadPoolExecutor(max_workers=6) as pool:
        responses = list(
            pool.map(
                lambda _: api.client.post("/v1/risk/captcha", headers=headers, json=body), range(6)
            )
        )
    assert sorted(response.status_code for response in responses) == [200, 400, 400, 400, 400, 400]
    rows = actions(capsys)
    assert len(rows) == 1 and rows[0]["lift_reason"] == "captcha" and rows[0]["lifted_at"]


def test_challenge_read_is_bound_non_issuing_no_store_and_expires_after_solve(api: Api) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=2)
    headers = {"X-Device-ID": "image-challenge-device"}
    api.client.get("/v1/me", headers=headers)
    challenged = api.client.get("/v1/me", headers=headers)
    challenge_id = challenged.headers["X-Risk-Challenge"]
    path = f"/v1/risk/captcha/{challenge_id}"
    assert api.client.get(path, headers={"X-Device-ID": "wrong-device"}).status_code == 400
    for _ in range(2):
        presentation = api.client.get(path, headers=headers)
        assert presentation.status_code == 200, presentation.text
        assert presentation.headers["Cache-Control"] == "no-store"
        body = presentation.json()
        assert set(body) == {"challenge_id", "prompt", "image_data_uri"}
        assert body["challenge_id"] == challenge_id and body["prompt"]
        assert body["image_data_uri"].startswith("data:image/png;base64,")
        assert base64.b64decode(body["image_data_uri"].split(",", 1)[1]).startswith(
            b"\x89PNG\r\n\x1a\n"
        )
    solve(api, challenged, headers)
    assert api.client.get(path, headers=headers).status_code == 400
    assert api.client.get("/v1/me", headers=headers).status_code == 401


def test_challenge_read_distinguishes_identity_failures_from_challenge_binding(api: Api) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    set_config("auth.access_token_minutes", "2")
    tokens = api.login("captcha-identity@example.com", "identity-challenge-device")
    # Login advances the business clock by 61s; use a fresh request window so
    # login observations cannot pre-issue the challenge under this lower limit.
    configure(short_request_limit=2, short_window_seconds=10)
    headers = {**bearer(tokens), "X-Device-ID": "identity-challenge-device"}
    assert api.client.get("/v1/me", headers=headers).status_code == 200
    challenged = api.client.get("/v1/me", headers=headers)
    assert challenged.status_code == 403, challenged.text
    path = f"/v1/risk/captcha/{challenged.headers['X-Risk-Challenge']}"
    anonymous = {"X-Device-ID": "identity-challenge-device"}

    # A bearer opts into the signed identity boundary, even on a recovery route.
    unsigned = api.client.get(path, headers={**headers, "X-Test-Unsigned": "true"})
    assert unsigned.status_code == 401, unsigned.text
    assert unsigned.json()["error"]["code"] == "signature_required"
    assert api.client.get(path, headers=anonymous).status_code == 200
    assert api.client.get(path, headers=headers).status_code == 200
    invalid = api.client.get(path, headers={**anonymous, "Authorization": "Bearer invalid-token"})
    assert invalid.status_code == 401, invalid.text
    assert invalid.json()["error"]["code"] == "unauthorized"

    # The access token expires before this still-active challenge. Anonymous
    # device/IP recovery remains possible without weakening bearer validation.
    api.clock.advance(seconds=60)
    expired = api.client.get(path, headers=headers)
    assert expired.status_code == 401, expired.text
    assert expired.json()["error"]["code"] == "token_expired"
    assert api.client.get(path, headers=anonymous).status_code == 200
    solve(api, challenged, anonymous)
    consumed = api.client.get(path, headers=anonymous)
    assert consumed.status_code == 400, consumed.text
    assert consumed.json()["error"]["code"] == "captcha_invalid"


def test_real_image_provider_rejects_wrong_answer_without_plaintext_answer(api: Api) -> None:
    configure(short_request_limit=2)
    headers = {"X-Device-ID": "real-image-device"}
    api.client.get("/v1/me", headers=headers)
    challenged = api.client.get("/v1/me", headers=headers)
    challenge_id = challenged.headers["X-Risk-Challenge"]
    presentation = api.client.get(f"/v1/risk/captcha/{challenge_id}", headers=headers)
    assert presentation.status_code == 200
    assert set(presentation.json()) == {"challenge_id", "prompt", "image_data_uri"}
    rejected = api.client.post(
        "/v1/risk/captcha",
        headers=headers,
        json={"challenge_id": challenge_id, "response": "wrong-answer"},
    )
    assert rejected.status_code == 400 and rejected.json()["error"]["code"] == "captcha_invalid"
    assert api.client.get(f"/v1/risk/captcha/{challenge_id}", headers=headers).status_code == 200


def test_cors_protection_headers_cover_early_risk_and_rate_responses(api: Api) -> None:
    api.client.app.state.captcha = MemoryCaptchaAdapter()
    configure(short_request_limit=2)
    origin = "http://localhost:40000"
    headers = {"Origin": origin, "X-Device-ID": "cors-device"}
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    challenged = api.client.get("/v1/me", headers=headers)
    assert challenged.status_code == 403
    assert challenged.headers["Access-Control-Allow-Origin"] == origin
    exposed = challenged.headers["Access-Control-Expose-Headers"].lower()
    assert "x-risk-challenge" in exposed and "retry-after" in exposed
    set_config("risk.enabled", "false")
    set_config("rate.detail.ip_per_minute", "1")
    api.clock.advance(seconds=61)
    assert api.client.get("/v1/me", headers=headers).status_code == 401
    limited = api.client.get("/v1/me", headers=headers)
    assert limited.status_code == 429 and limited.headers["Retry-After"]
    assert limited.headers["Access-Control-Allow-Origin"] == origin
    assert "retry-after" in limited.headers["Access-Control-Expose-Headers"].lower()
