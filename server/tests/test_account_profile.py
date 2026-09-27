"""昵称、时区和同意记录（SPEC-013.2 票 4、票 5）。"""

from tests.accounts_support import Api, bearer, new_uuid


def test_change_nickname(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = api.client.patch("/v1/me", json={"nickname": "  小厨  "}, headers=bearer(tokens))
    assert resp.status_code == 200
    assert resp.json()["nickname"] == "小厨"
    assert api.client.get("/v1/me", headers=bearer(tokens)).json()["nickname"] == "小厨"


def test_nickname_empty_or_too_long_is_rejected(api: Api) -> None:
    tokens = api.login("cook@example.com")
    for bad in ("   ", "长" * 21):
        resp = api.client.patch("/v1/me", json={"nickname": bad}, headers=bearer(tokens))
        assert resp.status_code == 422
        assert resp.json()["error"]["code"] == "invalid_nickname"
    ok = api.client.patch("/v1/me", json={"nickname": "长" * 20}, headers=bearer(tokens))
    assert ok.status_code == 200


def test_timezone(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = api.client.patch("/v1/me", json={"timezone": "Europe/Berlin"}, headers=bearer(tokens))
    assert resp.status_code == 200
    assert resp.json()["timezone"] == "Europe/Berlin"

    resp = api.client.patch("/v1/me", json={"timezone": "Mars/Base"}, headers=bearer(tokens))
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "invalid_timezone"
    assert api.client.get("/v1/me", headers=bearer(tokens)).json()["timezone"] == "Europe/Berlin"


def _record(kind: str, action: str = "agree", version: str = "v1", **kw: str) -> dict[str, str]:
    return {
        "id": kw.get("id", new_uuid()),
        "kind": kind,
        "version": version,
        "action": action,
        "occurred_at": kw.get("occurred_at", "2026-09-27T12:00:00+08:00"),
        "device_id": "device-1",
    }


def test_consents_given_before_login_are_uploaded(api: Api) -> None:
    tokens = api.login("cook@example.com")
    local = [_record("terms"), _record("privacy")]
    resp = api.client.post("/v1/me/consents", json={"records": local}, headers=bearer(tokens))
    assert resp.status_code == 204

    # 重复上传同一批不会重复记录
    api.client.post("/v1/me/consents", json={"records": local}, headers=bearer(tokens))
    got = api.client.get("/v1/me/consents", headers=bearer(tokens)).json()
    assert [(c["kind"], c["version"], c["action"]) for c in got] == [
        ("terms", "v1", "agree"),
        ("privacy", "v1", "agree"),
    ]
    assert got[0]["occurred_at"] == "2026-09-27T04:00:00+00:00"
    assert got[0]["device_id"] == "device-1"


def test_withdraw_is_recorded(api: Api) -> None:
    tokens = api.login("cook@example.com")
    api.client.post(
        "/v1/me/consents",
        json={"records": [_record("privacy", occurred_at="2026-09-27T12:00:00Z")]},
        headers=bearer(tokens),
    )
    api.client.post(
        "/v1/me/consents",
        json={"records": [_record("privacy", "withdraw", occurred_at="2026-09-28T12:00:00Z")]},
        headers=bearer(tokens),
    )
    got = api.client.get("/v1/me/consents", headers=bearer(tokens)).json()
    assert [c["action"] for c in got] == ["agree", "withdraw"]


def test_consent_kinds_are_checked(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = api.client.post(
        "/v1/me/consents", json={"records": [_record("marketing")]}, headers=bearer(tokens)
    )
    assert resp.status_code == 422
    # 以后的敏感个人信息单独同意直接复用
    resp = api.client.post(
        "/v1/me/consents",
        json={"records": [_record("sensitive_personal_info")]},
        headers=bearer(tokens),
    )
    assert resp.status_code == 204


def test_consents_are_per_account(api: Api) -> None:
    a = api.login("a@example.com")
    b = api.login("b@example.com")
    api.client.post("/v1/me/consents", json={"records": [_record("terms")]}, headers=bearer(a))
    assert api.client.get("/v1/me/consents", headers=bearer(b)).json() == []


def test_legal_pages_are_served(database_url: str) -> None:
    from fastapi.testclient import TestClient

    from gramtree.main import create_app
    from tests.conftest import make_settings

    with TestClient(create_app(make_settings())) as c:
        for doc, title in (("terms", "用户协议"), ("privacy", "隐私政策")):
            resp = c.get(f"/legal/{doc}.html")
            assert resp.status_code == 200
            assert resp.headers["content-type"].startswith("text/html")
            assert title in resp.text
        assert c.get("/legal/other.html").status_code == 404
