"""Device signing acceptance through HTTP and the real Redis nonce store."""

import json
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

import pytest

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.signing_support import signed_headers


def configure(key: str, value: int | str) -> None:
    assert (
        cli(["config", "set", key, str(value), "--by", "http-test", "--reason", "acceptance"]) == 0
    )


def quiet_risk() -> None:
    # These tests isolate signature errors. Rule escalation has its own HTTP suite.
    configure("risk.enabled", "false")


def headers(api: Api, tokens: dict, method: str = "GET", url: str = "/v1/me", **kw) -> dict:
    return signed_headers(tokens, method, url, timestamp=int(api.clock().timestamp()), **kw)


def assert_signature_error(response, code: str, *secrets: str) -> None:
    assert response.status_code == 401, response.text
    error = response.json()["error"]
    assert error["code"] == code
    assert error["detail"] is None
    assert error["request_id"]
    for secret in secrets:
        assert secret not in response.text


def test_signed_login_contract_and_ordinary_responses_do_not_repeat_key(api: Api, caplog) -> None:
    tokens = api.login("signed@example.com", "device-a")
    key = tokens["request_signing_key"]
    assert len(key) == 64
    response = api.client.get("/v1/me", headers=headers(api, tokens, device="device-a"))
    assert response.status_code == 200, response.text
    assert key not in response.text
    assert key not in caplog.text
    assert "request_signing_key" not in response.json()
    schema = api.client.get("/openapi.json").json()
    assert "request_signing_key" in schema["components"]["schemas"]["TokenPair"]["required"]
    parameters = schema["paths"]["/v1/me"]["get"]["parameters"]
    assert {"X-Request-Signature", "X-Request-Timestamp", "X-Request-Nonce", "X-Device-ID"} <= {
        p["name"] for p in parameters
    }


@pytest.mark.parametrize(
    "missing", ["all", "X-Request-Signature", "X-Request-Timestamp", "X-Request-Nonce"]
)
def test_missing_signing_headers_are_rejected(api: Api, missing: str) -> None:
    quiet_risk()
    tokens = api.login("missing@example.com")
    supplied = bearer(tokens) if missing == "all" else headers(api, tokens)
    supplied.pop(missing, None)
    supplied["X-Test-Unsigned"] = "true"
    response = api.client.get("/v1/me", headers=supplied)
    assert_signature_error(response, "signature_required", tokens["request_signing_key"])


@pytest.mark.parametrize(
    "mutation",
    ["key", "signature", "timestamp", "nonce", "query", "query_order", "path", "method", "body"],
)
def test_mac_covers_every_request_component(api: Api, mutation: str) -> None:
    quiet_risk()
    tokens = api.login("mac@example.com")
    method, url, body = "GET", "/v1/me?a=1&b=2", b""
    if mutation == "body":
        method, url, body = "PATCH", "/v1/me", b'{"nickname":"Original"}'
    supplied = headers(api, tokens, method, url, body=body)
    if mutation == "key":
        supplied = headers(api, tokens, method, url, key="another-key")
    elif mutation == "signature":
        supplied["X-Request-Signature"] = "0" * 64
    elif mutation == "timestamp":
        supplied["X-Request-Timestamp"] = str(int(supplied["X-Request-Timestamp"]) + 1)
    elif mutation == "nonce":
        supplied["X-Request-Nonce"] = "changed"
    elif mutation == "query":
        url = "/v1/me?a=9&b=2"
    elif mutation == "query_order":
        url = "/v1/me?b=2&a=1"
    elif mutation == "path":
        url = "/v1/me/identities?a=1&b=2"
    elif mutation == "method":
        method, body = "PATCH", b'{"nickname":"Changed"}'
    elif mutation == "body":
        body = b'{"nickname":"Changed"}'
    response = api.client.request(
        method, url, content=body, headers={**supplied, "Content-Type": "application/json"}
    )
    assert_signature_error(response, "signature_invalid", tokens["request_signing_key"])
    assert (
        api.client.get("/v1/me", headers=bearer(tokens)).json()["nickname"]
        == tokens["user"]["nickname"]
    )


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("X-Request-Timestamp", "not-a-number"),
        ("X-Request-Nonce", "x" * 129),
        ("X-Request-Signature", "g" * 64),
    ],
)
def test_malformed_signing_headers_fail_safely(api: Api, field: str, value: str) -> None:
    quiet_risk()
    tokens = api.login("malformed@example.com")
    supplied = headers(api, tokens)
    supplied[field] = value
    assert_signature_error(api.client.get("/v1/me", headers=supplied), "signature_invalid")


@pytest.mark.parametrize("offset", [-11, 11])
def test_clock_error_uses_hot_config_and_supplies_server_time(api: Api, offset: int) -> None:
    quiet_risk()
    tokens = api.login("clock@example.com")
    configure("auth.signing_clock_tolerance_seconds", 10)
    signed = signed_headers(
        tokens, "GET", "/v1/me", timestamp=int(api.clock().timestamp()) + offset
    )
    response = api.client.get("/v1/me", headers=signed)
    assert_signature_error(response, "signature_clock_skew", tokens["request_signing_key"])
    assert datetime.fromisoformat(response.json()["error"]["server_time"]) == api.clock()
    configure("auth.signing_clock_tolerance_seconds", 11)
    assert api.client.get("/v1/me", headers=signed).status_code == 200
    assert api.client.get("/v1/me", headers=headers(api, tokens)).status_code == 200


def test_nonce_is_atomic_expiring_session_scoped_and_not_consumed_by_bad_mac(api: Api) -> None:
    quiet_risk()
    first = api.login("nonce@example.com", "first-device")
    second = api.login("nonce@example.com", "second-device")
    configure("auth.signing_clock_tolerance_seconds", 30)
    configure("auth.signing_nonce_ttl_seconds", 1)
    timestamp = int(api.clock().timestamp()) + 30
    supplied = signed_headers(
        first, "GET", "/v1/me", timestamp=timestamp, nonce="same-nonce", device="first-device"
    )
    invalid = {**supplied, "X-Request-Signature": "0" * 64}
    assert_signature_error(api.client.get("/v1/me", headers=invalid), "signature_invalid")
    with ThreadPoolExecutor(max_workers=8) as pool:
        responses = list(pool.map(lambda _: api.client.get("/v1/me", headers=supplied), range(8)))
    assert sum(r.status_code == 200 for r in responses) == 1
    for response in responses:
        if response.status_code != 200:
            assert_signature_error(response, "nonce_replayed")
    # Redis expiry uses wall time, not the injectable business clock. A bounded
    # wait proves that a configured 1s TTL cannot reopen this valid replay window.
    time.sleep(1.1)
    api.clock.advance(seconds=1)
    assert_signature_error(api.client.get("/v1/me", headers=supplied), "nonce_replayed")
    assert (
        api.client.get(
            "/v1/me", headers=headers(api, second, nonce="same-nonce", device="second-device")
        ).status_code
        == 200
    )


@pytest.mark.parametrize("component", ["nonce", "query"])
def test_literal_percent_cannot_collide_with_encoded_plus(api: Api, component: str) -> None:
    quiet_risk()
    tokens = api.login("encoding@example.com")
    original = "/v1/me?q=a+b" if component == "query" else "/v1/me"
    changed = "/v1/me?q=a%2Bb" if component == "query" else original
    supplied = headers(api, tokens, url=original, nonce="a+b")
    assert api.client.get(original, headers=supplied).status_code == 200
    if component == "nonce":
        supplied["X-Request-Nonce"] = "a%2Bb"
    assert_signature_error(api.client.get(changed, headers=supplied), "signature_invalid")
    fresh = headers(api, tokens, url=changed, nonce="a%2Bb")
    assert api.client.get(changed, headers=fresh).status_code == 200


def test_expired_nonce_can_be_reused_only_with_a_fresh_signed_timestamp(api: Api) -> None:
    quiet_risk()
    tokens = api.login("nonce-expiry@example.com")
    configure("auth.signing_clock_tolerance_seconds", 1)
    configure("auth.signing_nonce_ttl_seconds", 1)
    supplied = signed_headers(
        tokens, "GET", "/v1/me", timestamp=int(api.clock().timestamp()) - 1, nonce="expiring"
    )
    assert api.client.get("/v1/me", headers=supplied).status_code == 200
    time.sleep(1.1)
    api.clock.advance(seconds=2)
    assert_signature_error(api.client.get("/v1/me", headers=supplied), "signature_clock_skew")
    fresh = headers(api, tokens, nonce="expiring")
    assert api.client.get("/v1/me", headers=fresh).status_code == 200
    assert_signature_error(api.client.get("/v1/me", headers=fresh), "nonce_replayed")


@pytest.mark.parametrize("other_account", [False, True])
def test_signing_credentials_cannot_cross_sessions_or_devices(
    api: Api, other_account: bool
) -> None:
    quiet_risk()
    first = api.login("isolation@example.com", "device-a")
    second = api.login(
        "other@example.com" if other_account else "isolation@example.com", "device-b"
    )
    supplied = headers(api, second, device="device-b", key=first["request_signing_key"])
    assert_signature_error(api.client.get("/v1/me", headers=supplied), "signature_invalid")
    supplied = headers(api, first, device="device-b")
    assert_signature_error(api.client.get("/v1/me", headers=supplied), "device_mismatch")
    supplied = headers(api, first)  # Device-bound sessions require the installation header.
    assert_signature_error(api.client.get("/v1/me", headers=supplied), "device_mismatch")
    assert (
        api.client.get("/v1/me", headers=headers(api, first, device="device-a")).status_code == 200
    )


def test_refresh_rotates_key_only_current_device_and_expires_grace(api: Api) -> None:
    quiet_risk()
    first = api.login("rotation@example.com", "device-a")
    other = api.login("rotation@example.com", "device-b")
    configure("auth.signing_key_grace_seconds", 2)
    refreshed = api.client.post("/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert refreshed.status_code == 200, refreshed.text
    new = refreshed.json()
    assert new["request_signing_key"] != first["request_signing_key"]
    for tokens, device in ((first, "device-a"), (new, "device-a"), (other, "device-b")):
        assert (
            api.client.get("/v1/me", headers=headers(api, tokens, device=device)).status_code == 200
        )
    api.clock.advance(seconds=2)
    assert_signature_error(
        api.client.get("/v1/me", headers=headers(api, first, device="device-a")),
        "signature_invalid",
        first["request_signing_key"],
    )
    for tokens, device in ((new, "device-a"), (other, "device-b")):
        assert (
            api.client.get("/v1/me", headers=headers(api, tokens, device=device)).status_code == 200
        )
    assert first["request_signing_key"] not in json.dumps(new)
