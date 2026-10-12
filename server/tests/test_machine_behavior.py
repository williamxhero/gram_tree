"""HTTP coverage for rule-based machine behaviour enforcement."""

import subprocess

from tests.accounts_support import Api


def _set_config(key: str, value: str) -> None:
    result = subprocess.run(
        ["gramtree", "config", "set", key, value, "--by", "test", "--reason", "risk http test"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr


def test_burst_requires_captcha_then_restores_access(api: Api) -> None:
    api.client.app.state.captcha = __import__(
        "gramtree.risk.captcha", fromlist=["MemoryCaptchaAdapter"]
    ).MemoryCaptchaAdapter()
    _set_config("risk.short_request_limit", "2")
    _set_config("risk.throttle_points", "10")
    _set_config("risk.temporary_block_points", "30")
    _set_config("risk.permanent_block_points", "100")

    assert api.client.get("/v1/me").status_code == 401
    challenged = api.client.get("/v1/me")
    assert challenged.status_code == 403
    assert challenged.json()["error"]["code"] == "risk_captcha_required"
    challenge = challenged.headers["X-Risk-Challenge"]
    assert "access_token" not in challenged.text
    assert api.client.post(
        "/v1/risk/captcha", json={"challenge_id": challenge, "response": "ok"}
    ).json() == {"accepted": True, "access_restored": True}
    assert api.client.get("/v1/me").status_code == 401


def test_repeated_burst_escalates_to_slowdown(api: Api) -> None:
    api.client.app.state.captcha = __import__(
        "gramtree.risk.captcha", fromlist=["MemoryCaptchaAdapter"]
    ).MemoryCaptchaAdapter()
    _set_config("risk.short_request_limit", "2")
    _set_config("risk.throttle_points", "10")
    _set_config("risk.temporary_block_points", "30")
    _set_config("risk.permanent_block_points", "100")

    api.client.get("/v1/me")
    challenged = api.client.get("/v1/me")
    challenge = challenged.headers["X-Risk-Challenge"]
    assert (
        api.client.post(
            "/v1/risk/captcha", json={"challenge_id": challenge, "response": "ok"}
        ).status_code
        == 200
    )
    # The retained escalation state makes the next violation a slowdown, not another
    # CAPTCHA. The response remains the normal error envelope and has a retry delay.
    api.client.get("/v1/me")
    slowed = api.client.get("/v1/me")
    assert slowed.status_code == 429
    assert slowed.json()["error"]["code"] == "risk_slowed"
    assert int(slowed.headers["Retry-After"]) > 0
