"""App 内注销账号（SPEC-013.2 票 8）。"""

import subprocess
from datetime import datetime

from tests.accounts_support import Api, apple_token, bearer

EMAIL = "cook@example.com"


def _reauth_email(api: Api, tokens: dict, email: str = EMAIL) -> int:
    resp = api.send_code(email, "reauth", headers=bearer(tokens))
    assert resp.status_code == 200, resp.text
    resp = api.client.post(
        "/v1/auth/reauth/email",
        json={"email": email, "code": api.latest_code(email)},
        headers=bearer(tokens),
    )
    return resp.status_code


def _purge(as_of: str) -> str:
    result = subprocess.run(
        ["gramtree", "accounts", "purge", "--as-of", as_of], capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    return result.stdout


def test_deletion_requires_recent_reauth(api: Api) -> None:
    tokens = api.login(EMAIL)
    resp = api.client.post("/v1/me/deletion", headers=bearer(tokens))
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "reauth_required"

    assert _reauth_email(api, tokens) == 204
    api.clock.advance(minutes=11)
    resp = api.client.post("/v1/me/deletion", headers=bearer(tokens))
    assert resp.json()["error"]["code"] == "reauth_required"


def test_reauth_must_use_own_email(api: Api) -> None:
    api.login("other@example.com")
    tokens = api.login(EMAIL)
    resp = api.send_code("other@example.com", "reauth", headers=bearer(tokens))
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "identity_mismatch"


def test_deleted_account_is_signed_out_everywhere_and_cannot_log_in(api: Api) -> None:
    other_device = api.login(EMAIL, device="tablet")
    tokens = api.login(EMAIL, device="phone")
    assert _reauth_email(api, tokens) == 204

    resp = api.client.post("/v1/me/deletion", headers=bearer(tokens))
    assert resp.status_code == 202
    body = resp.json()
    assert body["status"] == "deleting"
    due = datetime.fromisoformat(body["deletion_due_at"])
    assert (due - api.clock.now).days >= 15  # 15 个工作日，跨周末

    for t in (tokens, other_device):
        assert api.client.get("/v1/me", headers=bearer(t)).status_code == 401
        r = api.client.post("/v1/auth/refresh", json={"refresh_token": t["refresh_token"]})
        assert r.status_code == 401

    api.send_code(EMAIL)
    resp = api.client.post(
        "/v1/auth/email/login", json={"email": EMAIL, "code": api.latest_code(EMAIL)}
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "account_unavailable"


def test_apple_account_deletion_revokes_apple_grant(api: Api) -> None:
    resp = api.client.post(
        "/v1/auth/apple/login",
        json={"identity_token": apple_token("apple-del"), "authorization_code": "grant-1"},
    )
    tokens = resp.json()
    resp = api.client.post(
        "/v1/auth/reauth/apple",
        json={"identity_token": apple_token("apple-del")},
        headers=bearer(tokens),
    )
    assert resp.status_code == 204

    resp = api.client.post("/v1/me/deletion", headers=bearer(tokens))
    assert resp.status_code == 202
    assert api.apple.revoked == ["apple-refresh-grant-1"]

    resp = api.apple_login("apple-del")
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "account_unavailable"


def test_apple_reauth_with_someone_elses_apple_id_is_rejected(api: Api) -> None:
    api.apple_login("apple-a")
    tokens = api.apple_login("apple-b").json()
    resp = api.client.post(
        "/v1/auth/reauth/apple",
        json={"identity_token": apple_token("apple-a")},
        headers=bearer(tokens),
    )
    assert resp.status_code == 403


def test_purge_deletes_personal_data_only_when_due(api: Api) -> None:
    keep = api.login("keep@example.com")
    tokens = api.login(EMAIL)
    _reauth_email(api, tokens)
    due = api.client.post("/v1/me/deletion", headers=bearer(tokens)).json()["deletion_due_at"]

    # 没到期：不删，账号仍是注销中，再用这个邮箱登录也不行
    assert "已删除 0 个" in _purge(api.clock.now.isoformat())
    api.clock.advance(seconds=61)
    api.send_code(EMAIL)
    code = api.latest_code(EMAIL)
    resp = api.client.post("/v1/auth/email/login", json={"email": EMAIL, "code": code})
    assert resp.json()["error"]["code"] == "account_unavailable"

    assert "已删除 1 个" in _purge(due)

    # 删除后，同一邮箱再登录是一个全新的账号，和原来的没有关联
    api.clock.advance(seconds=61)
    fresh = api.login(EMAIL)
    assert fresh["user"]["id"] != tokens["user"]["id"]
    assert api.client.get("/v1/me/consents", headers=bearer(fresh)).json() == []
    assert api.client.get("/v1/me", headers=bearer(keep)).status_code == 200


def test_purge_command_requires_timezone(database_url: str) -> None:
    result = subprocess.run(
        ["gramtree", "accounts", "purge", "--as-of", "2026-10-20T00:00:00"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1
    assert "必须带时区" in result.stderr


def test_purge_runs_daily(database_url: str) -> None:
    from gramtree.tasks.celery_app import celery_app

    job = celery_app.conf.beat_schedule["purge-deleted-accounts"]
    assert job["task"] == "gramtree.tasks.jobs.purge_deleted_accounts"
