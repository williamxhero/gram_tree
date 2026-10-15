"""Export/account erasure integration through HTTP and the operator commands."""

import pytest

from tests.accounts_support import Api, bearer
from tests.test_account_deletion import _purge
from tests.test_data_deletion import _recipe, _record
from tests.test_data_exports import archive, reauth, run_exports


def test_account_purge_erases_its_archives_and_jobs_without_touching_another_owner(
    api: Api,
) -> None:
    # Remove prior tests' orphan files before asserting this test's exact cleanup.
    run_exports(api, "cleanup")
    alice = api.login("export-purge@example.com")
    bob = api.login("export-purge-isolation@example.com")
    reauth(api, alice, "export-purge@example.com")
    reauth(api, bob, "export-purge-isolation@example.com")
    jobs = []
    for owner in (alice, bob):
        response = api.client.post("/v1/me/exports", headers=bearer(owner))
        assert response.status_code == 202, response.text
        jobs.append(response.json()["id"])
    assert run_exports(api) == {"completed": 2, "failed": 0}
    assert archive(api, alice, jobs[0])["account.json"]["format_version"] == 1
    foreign_archive = archive(api, bob, jobs[1])
    response = api.client.post("/v1/me/deletion", headers=bearer(alice), json={})
    assert response.status_code == 202, response.text
    assert api.client.get(f"/v1/me/exports/{jobs[0]}", headers=bearer(alice)).status_code == 401
    assert "已删除 1 个" in _purge(response.json()["deletion_due_at"])
    observed = api.client.get(
        "/v1/dev/deletion-storage",
        headers=bearer(bob),
        params={"owner_id": alice["user"]["id"]},
    )
    assert observed.status_code == 200, observed.text
    assert observed.json()["owned_counts"]["data_exports"] == 0
    # The observer's simulated clock remains at creation: the foreign ZIP is valid.
    assert archive(api, bob, jobs[1]) == foreign_archive
    # An unremoved deleted owner's ZIP would now be an orphan and counted here.
    assert run_exports(api, "cleanup") == {"removed": 0}
    assert "已删除 0 个" in _purge(response.json()["deletion_due_at"])


@pytest.mark.parametrize("kind", ["records", "recipes"])
def test_item_deletion_invalidates_owner_archives_and_pending_jobs_without_resetting_quota(
    api: Api, kind: str
) -> None:
    run_exports(api, "cleanup")
    email = f"export-item-{kind}@example.com"
    owner = api.login(email)
    foreign_email = f"export-item-foreign-{kind}@example.com"
    foreign = api.login(foreign_email)
    reauth(api, owner, email)
    reauth(api, foreign, foreign_email)
    recipe = _recipe(api, owner)
    record = _record(api, owner, recipe)
    jobs = []
    for tokens in (owner, owner, foreign):
        response = api.client.post("/v1/me/exports", headers=bearer(tokens))
        assert response.status_code == 202, response.text
        jobs.append(response.json()["id"])
    assert run_exports(api) == {"completed": 3, "failed": 0}
    urls = []
    for job_id in jobs[:2]:
        response = api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(owner))
        assert response.status_code == 200, response.text
        urls.append(response.json()["download_url"])
        exported = archive(api, owner, job_id)
        assert exported["recipes.json"]["items"][0]["id"] == recipe["id"]
        assert exported["cooking_records.json"]["items"][0]["id"] == record["id"]
    foreign_archive = archive(api, foreign, jobs[2])
    pending = api.client.post("/v1/me/exports", headers=bearer(owner))
    assert pending.status_code == 202, pending.text
    owner_jobs = [*jobs[:2], pending.json()["id"]]
    item = record if kind == "records" else recipe
    path = f"/v1/{kind}/{item['id']}"
    assert api.client.delete(path, headers=bearer(foreign)).status_code == 404
    # A forbidden deletion must not invalidate either account's valid exports.
    assert archive(api, owner, jobs[0])["recipes.json"]["items"][0]["id"] == recipe["id"]
    assert api.client.delete(path, headers=bearer(owner)).status_code == 204
    assert api.client.get(path, headers=bearer(owner)).status_code == 404
    for job_id in owner_jobs:
        response = api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(owner))
        assert response.status_code == 200, response.text
        assert response.json()["status"] == "expired"
        assert response.json()["download_url"] is None
        retry = api.client.post(f"/v1/me/exports/{job_id}/retry", headers=bearer(owner))
        assert retry.status_code == 409, retry.text
    for url in urls:
        assert api.client.get(url, headers=bearer(owner)).status_code == 410
    fourth = api.client.post("/v1/me/exports", headers=bearer(owner))
    assert fourth.status_code == 429, fourth.text
    assert fourth.json()["error"]["code"] == "export_daily_limit"
    assert run_exports(api) == {"completed": 0, "failed": 0}
    assert run_exports(api, "cleanup") == {"removed": 0}
    assert archive(api, foreign, jobs[2]) == foreign_archive
    if kind == "recipes":
        assert api.client.get(f"/v1/records/{record['id']}", headers=bearer(owner)).json() == record
