"""Export/account erasure integration through HTTP and the operator commands."""

from tests.accounts_support import Api, bearer
from tests.test_account_deletion import _purge
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
