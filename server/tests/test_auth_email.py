"""邮箱验证码登录、令牌、退出和统一的登录校验（SPEC-013.2 票 2、票 3）。"""

import subprocess

from fastapi.testclient import TestClient

from tests.accounts_support import Api, bearer

EMAIL = "cook@example.com"


def test_first_login_creates_account_and_next_login_reuses_it(api: Api) -> None:
    first = api.login(EMAIL)
    assert first["user"]["nickname"].startswith("味友")
    assert first["user"]["timezone"] == "Asia/Shanghai"
    assert first["access_expires_in"] == 30 * 60

    second = api.login("  Cook@Example.com ")
    assert second["user"]["id"] == first["user"]["id"]

    me = api.client.get("/v1/me", headers=bearer(second))
    assert me.status_code == 200
    assert me.json()["id"] == first["user"]["id"]


def test_reserved_phone_and_real_name_fields(api: Api) -> None:
    tokens = api.login(EMAIL)
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    assert me["phone"] is None
    assert me["real_name_status"] == "none"
    assert me["status"] == "active"


def test_code_email_is_sent_through_mail_layer(api: Api) -> None:
    api.send_code(EMAIL)
    mail = api.mailer.latest_to(EMAIL)
    assert mail is not None
    assert api.latest_code(EMAIL) in mail.subject
    assert "10 分钟内有效" in mail.body


def test_wrong_code_counts_attempts_then_locks(api: Api) -> None:
    api.send_code(EMAIL)
    good = api.latest_code(EMAIL)
    bad = "000000" if good != "000000" else "111111"
    for left in (4, 3, 2, 1):
        resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": bad})
        assert resp.status_code == 400
        assert resp.json()["error"]["code"] == "code_invalid"
        assert f"再试 {left} 次" in resp.json()["error"]["message"]
    resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": bad})
    assert resp.json()["error"]["code"] == "code_attempts_exceeded"
    # 次数用完后，正确的验证码也不行了
    resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": good})
    assert resp.json()["error"]["code"] == "code_attempts_exceeded"


def test_expired_code_is_rejected(api: Api) -> None:
    api.send_code(EMAIL)
    code = api.latest_code(EMAIL)
    api.clock.advance(minutes=10, seconds=1)
    resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": code})
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "code_expired"


def test_used_code_cannot_be_reused(api: Api) -> None:
    api.send_code(EMAIL)
    code = api.latest_code(EMAIL)
    assert api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": code}).is_success
    resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": code})
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "code_invalid"


def test_only_latest_code_is_valid(api: Api) -> None:
    api.send_code(EMAIL)
    old = api.latest_code(EMAIL)
    api.clock.advance(seconds=61)
    api.send_code(EMAIL)
    new = api.latest_code(EMAIL)
    if old != new:
        resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": old})
        assert resp.status_code == 400
    assert api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": new}).is_success


def test_resend_interval(api: Api) -> None:
    first = api.send_code(EMAIL)
    assert first.status_code == 200
    assert first.json() == {"resend_after_seconds": 60, "expires_in_seconds": 600}
    api.clock.advance(seconds=20)
    resp = api.send_code(EMAIL)
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "resend_too_soon"
    assert "40 秒后" in resp.json()["error"]["message"]
    api.clock.advance(seconds=40)
    assert api.send_code(EMAIL).status_code == 200


def test_daily_limit_per_email(api: Api) -> None:
    for _ in range(10):
        assert api.send_code(EMAIL).status_code == 200
        api.clock.advance(seconds=61)
    resp = api.send_code(EMAIL)
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "daily_limit_reached"


def _from_ip(api: Api, ip: str) -> TestClient:
    return TestClient(api.client.app, client=(ip, 50000), raise_server_exceptions=False)


def test_daily_limit_per_device(api: Api) -> None:
    headers = {"X-Device-ID": "device-1"}
    for i in range(10):
        # 每封从不同的 IP、发给不同的邮箱，只有设备相同
        c = _from_ip(api, f"10.0.0.{i}")
        resp = c.post("/v1/auth/email/code", json={"email": f"u{i}@example.com"}, headers=headers)
        assert resp.status_code == 200
    c = _from_ip(api, "10.0.1.1")
    resp = c.post("/v1/auth/email/code", json={"email": "u10@example.com"}, headers=headers)
    assert resp.json()["error"]["code"] == "daily_limit_reached"
    other = c.post(
        "/v1/auth/email/code", json={"email": "u10@example.com"}, headers={"X-Device-ID": "d2"}
    )
    assert other.status_code == 200


def test_daily_limit_per_ip(api: Api) -> None:
    c = _from_ip(api, "10.9.9.9")
    for i in range(10):
        resp = c.post(
            "/v1/auth/email/code",
            json={"email": f"ip{i}@example.com"},
            headers={"X-Device-ID": f"d{i}"},
        )
        assert resp.status_code == 200
    resp = c.post(
        "/v1/auth/email/code", json={"email": "ip10@example.com"}, headers={"X-Device-ID": "d10"}
    )
    assert resp.json()["error"]["code"] == "daily_limit_reached"
    other = _from_ip(api, "10.9.9.10").post(
        "/v1/auth/email/code", json={"email": "ip10@example.com"}, headers={"X-Device-ID": "d10"}
    )
    assert other.status_code == 200


def test_daily_limit_resets_next_day(api: Api) -> None:
    for _ in range(10):
        api.send_code(EMAIL)
        api.clock.advance(seconds=61)
    assert api.send_code(EMAIL).status_code == 429
    api.clock.advance(days=1)
    assert api.send_code(EMAIL).status_code == 200


def test_limits_are_config_items(api: Api) -> None:
    result = subprocess.run(
        [
            "gramtree",
            "config",
            "set",
            "auth.email_code_resend_seconds",
            "0",
            "--by",
            "test",
            "--reason",
            "test",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    assert api.send_code(EMAIL).status_code == 200
    assert api.send_code(EMAIL).status_code == 200


def test_invalid_email_is_rejected(api: Api) -> None:
    resp = api.send_code("not-an-email")
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "invalid_email"


def test_protected_endpoints_require_login(api: Api) -> None:
    resp = api.client.get("/v1/me")
    assert resp.status_code == 401
    body = resp.json()["error"]
    assert body["code"] == "unauthorized"
    assert body["message"] == "请先登录"
    assert body["request_id"]

    resp = api.client.get("/v1/me", headers={"Authorization": "Bearer nonsense"})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "unauthorized"


def test_expired_access_token_then_refresh(api: Api) -> None:
    tokens = api.login(EMAIL)
    api.clock.advance(minutes=31)
    resp = api.client.get("/v1/me", headers=bearer(tokens))
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "token_expired"

    resp = api.client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 200
    renewed = resp.json()
    assert renewed["refresh_token"] != tokens["refresh_token"]
    assert api.client.get("/v1/me", headers=bearer(renewed)).status_code == 200


def test_reused_refresh_token_revokes_the_whole_chain(api: Api) -> None:
    tokens = api.login(EMAIL)
    first = api.client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    renewed = first.json()

    # 旧令牌再次出现：这一串全部失效
    replay = api.client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert replay.status_code == 401
    assert replay.json()["error"]["code"] == "refresh_invalid"

    resp = api.client.post("/v1/auth/refresh", json={"refresh_token": renewed["refresh_token"]})
    assert resp.status_code == 401
    assert api.client.get("/v1/me", headers=bearer(renewed)).status_code == 401


def test_refresh_token_expires(api: Api) -> None:
    tokens = api.login(EMAIL)
    api.clock.advance(days=30, seconds=1)
    resp = api.client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 401


def test_logout_only_affects_current_device(api: Api) -> None:
    phone = api.login(EMAIL, device="phone")
    tablet = api.login(EMAIL, device="tablet")
    assert phone["user"]["id"] == tablet["user"]["id"]

    assert api.client.post("/v1/auth/logout", headers=bearer(phone)).status_code == 204
    assert api.client.get("/v1/me", headers=bearer(phone)).status_code == 401
    resp = api.client.post("/v1/auth/refresh", json={"refresh_token": phone["refresh_token"]})
    assert resp.status_code == 401

    assert api.client.get("/v1/me", headers=bearer(tablet)).status_code == 200
    resp = api.client.post("/v1/auth/refresh", json={"refresh_token": tablet["refresh_token"]})
    assert resp.status_code == 200


def test_bind_and_reauth_codes_need_login(api: Api) -> None:
    for purpose in ("bind", "reauth"):
        resp = api.send_code(EMAIL, purpose)
        assert resp.status_code == 401


def test_dev_code_endpoint_is_not_in_openapi(api: Api) -> None:
    from gramtree.openapi_export import export

    assert "latest-email-code" not in export()
