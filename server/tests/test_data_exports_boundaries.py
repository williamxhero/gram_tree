"""Export quota and expiry are observed through HTTP and operator boundaries."""

from tests.accounts_support import Api, bearer
from tests.test_data_exports import reauth, run_exports


def test_export_daily_quota_is_independent_and_resets_at_utc_boundary(api: Api) -> None:
    email = "export-quota@example.com"
    tokens = api.login(email)
    reauth(api, tokens, email)
    for _ in range(3):
        response = api.client.post("/v1/me/exports", headers=bearer(tokens))
        assert response.status_code == 202, response.text
    limited = api.client.post("/v1/me/exports", headers=bearer(tokens))
    assert limited.status_code == 429
    assert limited.json()["error"]["code"] == "export_daily_limit"

    api.clock.advance(days=1)
    tokens = api.login(email)
    reauth(api, tokens, email)
    reset = api.client.post("/v1/me/exports", headers=bearer(tokens))
    assert reset.status_code == 202, reset.text


def test_export_download_expires_at_boundary_and_cleanup_removes_archive(api: Api) -> None:
    email = "export-expiry@example.com"
    tokens = api.login(email)
    reauth(api, tokens, email)
    response = api.client.post("/v1/me/exports", headers=bearer(tokens))
    assert response.status_code == 202, response.text
    job_id = response.json()["id"]
    run_exports(api)
    completed = api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(tokens)).json()
    assert completed["status"] == "completed"
    download_url = completed["download_url"]
    assert api.client.get(download_url, headers=bearer(tokens)).status_code == 200

    api.clock.advance(days=1, seconds=1)
    expired = api.client.get(download_url, headers=bearer(tokens))
    assert expired.status_code == 410
    assert expired.json()["error"]["code"] == "export_expired"
    status = api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(tokens)).json()["status"]
    assert status == "expired"
    result = run_exports(api, action="cleanup")
    assert result["removed"] >= 1
    assert api.client.get(download_url, headers=bearer(tokens)).status_code == 410
