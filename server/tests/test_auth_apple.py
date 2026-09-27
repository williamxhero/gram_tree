"""通过 Apple 登录和绑定登录方式（SPEC-013.2 票 6）。"""

from tests.accounts_support import Api, apple_token, bearer


def test_apple_login_creates_account_with_apple_name(api: Api) -> None:
    body = {
        "identity_token": apple_token("apple-001", email="real@example.com"),
        "authorization_code": "code-1",
        "given_name": "小明",
        "family_name": "王",
    }
    resp = api.client.post("/v1/auth/apple/login", json=body)
    assert resp.status_code == 200, resp.text
    tokens = resp.json()
    assert tokens["user"]["nickname"] == "王小明"
    assert api.apple.exchanged == ["code-1"]

    again = api.apple_login("apple-001")
    assert again.json()["user"]["id"] == tokens["user"]["id"]


def test_apple_hidden_email_account(api: Api) -> None:
    relay = "abc123@privaterelay.appleid.com"
    resp = api.apple_login("apple-002", email=relay, private_email=True)
    assert resp.status_code == 200
    tokens = resp.json()
    assert tokens["user"]["nickname"].startswith("味友")
    ids = api.client.get("/v1/me/identities", headers=bearer(tokens)).json()
    assert [(i["kind"], i["email"]) for i in ids] == [("apple", relay)]


def test_bad_apple_tokens_are_rejected(api: Api) -> None:
    cases = {
        "wrong signature": {"signed_by_apple": False},
        "expired": {"exp_in": -10},
        "wrong audience": {"aud": "someone.else.app"},
    }
    for name, kw in cases.items():
        resp = api.apple_login("apple-003", **kw)
        assert resp.status_code == 401, name
        assert resp.json()["error"]["code"] == "apple_token_invalid", name


def test_apple_login_unavailable_when_not_configured(client) -> None:  # type: ignore[no-untyped-def]
    resp = client.post("/v1/auth/apple/login", json={"identity_token": apple_token("x")})
    assert resp.status_code == 503
    assert resp.json()["error"]["code"] == "apple_unavailable"


def test_bind_apple_then_both_ways_reach_same_account(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = api.client.post(
        "/v1/me/identities/apple",
        json={"identity_token": apple_token("apple-010"), "authorization_code": "c"},
        headers=bearer(tokens),
    )
    assert resp.status_code == 200
    assert [i["kind"] for i in resp.json()] == ["email", "apple"]

    via_apple = api.apple_login("apple-010").json()
    assert via_apple["user"]["id"] == tokens["user"]["id"]


def test_bind_email_then_both_ways_reach_same_account(api: Api) -> None:
    tokens = api.apple_login("apple-011").json()
    resp = api.send_code("second@example.com", "bind", headers=bearer(tokens))
    assert resp.status_code == 200
    code = api.latest_code("second@example.com")
    resp = api.client.post(
        "/v1/me/identities/email",
        json={"email": "second@example.com", "code": code},
        headers=bearer(tokens),
    )
    assert resp.status_code == 200
    assert [i["kind"] for i in resp.json()] == ["apple", "email"]

    via_email = api.login("second@example.com")
    assert via_email["user"]["id"] == tokens["user"]["id"]


def test_binding_identity_of_another_account_is_rejected(api: Api) -> None:
    other = api.login("other@example.com")
    api.apple_login("apple-020")
    mine = api.login("mine@example.com")

    # 邮箱属于别人：发码时就拒绝
    resp = api.send_code("other@example.com", "bind", headers=bearer(mine))
    assert resp.status_code == 409
    assert resp.json()["error"]["code"] == "identity_taken"

    resp = api.client.post(
        "/v1/me/identities/apple",
        json={"identity_token": apple_token("apple-020")},
        headers=bearer(mine),
    )
    assert resp.status_code == 409
    assert resp.json()["error"]["code"] == "identity_taken"

    ids = api.client.get("/v1/me/identities", headers=bearer(mine)).json()
    assert [i["kind"] for i in ids] == ["email"]
    assert api.client.get("/v1/me", headers=bearer(other)).status_code == 200
