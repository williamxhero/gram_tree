"""Sensitive sync journeys observed through HTTP and test-only aggregate reports."""

import uuid
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest

from tests import test_family_members as family_support
from tests.accounts_support import Api, bearer
from tests.test_allergies import consent
from tests.test_family_members import PATH, member_body
from tests.test_sync_writes import envelope, submit

family_api = family_support.family_api


def create_member(api: Api, tokens: dict) -> tuple[dict, str]:
    owner = bearer(tokens)
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    response = api.client.post(PATH, headers=owner, json=member_body(state))
    assert response.status_code == 201
    change = api.client.get(PATH + "/changes", headers=owner).json()["items"][0]
    return response.json(), change["id"]


def linked_write(tokens: dict, change_id: str, **overrides) -> dict:
    write = envelope(tokens["user"]["id"], **overrides)
    write["payload"]["correlation"] = {"taste_profile_change_id": change_id}
    return write


def test_sync_rejects_other_owner_or_missing_taste_link(family_api: Api):
    api = family_api
    alice = api.login("sync-family-alice@example.com")
    _, change_id = create_member(api, alice)
    bob = api.login("sync-family-bob@example.com", device="other")
    denied = submit(api, bob, linked_write(bob, change_id))[0]
    assert denied["status"] == "failed"
    assert denied["reason_code"] == "invalid_correlation_id"
    assert denied["result"] is None
    forged = linked_write(alice, change_id)
    forged["payload"].update(event_type="taste_profile.changed", content={})
    result = submit(api, alice, forged)[0]
    assert result["status"] == "failed"
    assert result["reason_code"] == "invalid_correlation_id"
    allowed = linked_write(alice, change_id.upper())
    assert submit(api, alice, allowed)[0]["status"] == "confirmed"
    assert submit(api, alice, allowed)[0]["status"] == "already_processed"


def audit(api: Api, tokens: dict) -> dict:
    response = api.client.get(
        "/v1/dev/events/taste-profile-storage",
        headers=bearer(tokens),
        params={"include_sensitive": "true"},
    )
    assert response.status_code == 200
    return response.json()


@pytest.mark.parametrize("action", ["delete", "withdraw"])
def test_erasure_removes_sync_facts_and_dependency_ids_preserving_unrelated_writes(
    family_api: Api, action: str
):
    api = family_api
    tokens = api.login("sync-family-erase@example.com")
    owner = bearer(tokens)
    member, change_id = create_member(api, tokens)
    state = api.client.get(PATH, headers=owner).json()
    kept_response = api.client.post(PATH, headers=owner, json=member_body(state, nickname="长辈"))
    assert kept_response.status_code == 201
    kept = kept_response.json()
    kept_id = api.client.get(PATH + "/changes", headers=owner).json()["items"][0]["id"]
    sensitive = linked_write(tokens, change_id.upper())
    retained = linked_write(tokens, kept_id)
    ordinary = envelope(tokens["user"]["id"])
    child = envelope(
        tokens["user"]["id"], dependencies=[sensitive["write_id"], ordinary["write_id"]]
    )
    deferred = envelope(
        tokens["user"]["id"], dependencies=[sensitive["write_id"], str(uuid.uuid4())]
    )
    results = submit(api, tokens, sensitive, retained, ordinary, child, deferred)
    assert [row["status"] for row in results] == [
        "confirmed",
        "confirmed",
        "confirmed",
        "confirmed",
        "deferred",
    ]
    other = api.login("sync-family-erase-other@example.com", device="other")
    _, other_change_id = create_member(api, other)
    other_write = linked_write(other, other_change_id)
    other_result = submit(api, other, other_write)[0]
    other_before = audit(api, other)
    before = audit(api, tokens)
    assert before["sync_receipts"] == 5
    assert before["sync_outbox"] == 4
    assert before["sync_dependency_ids"] == 4
    settings = api.client.app.state.settings
    api.client.app.state.settings = settings.model_copy(update={"sensitive_data_key": None})
    if action == "delete":
        assert api.client.delete(PATH + "/" + member["id"], headers=owner).status_code == 204
    else:
        consent(api, owner, "withdraw")
    after = audit(api, tokens)
    assert after["sync_receipts"] == (4 if action == "delete" else 3)
    assert after["sync_outbox"] == (3 if action == "delete" else 2)
    assert after["sync_dependency_ids"] == 2  # retained ordinary + still-unknown prerequisite
    assert after["sync_orphan_event_results"] == after["sync_orphan_event_facts"] == 0
    assert after["family_members"] == (1 if action == "delete" else 0)
    assert after["sensitive_changes"] == (1 if action == "delete" else 0)
    assert after["family_changes"] == (2 if action == "delete" else 0)
    assert after["events"] == (5 if action == "delete" else 2)
    assert api.client.get(PATH + "/" + member["id"], headers=owner).status_code == 404
    assert api.client.get(PATH + "/changes/" + change_id, headers=owner).status_code in (403, 404)
    replay = submit(api, tokens, sensitive)[0]
    assert replay["status"] == "failed"
    assert replay["reason_code"] == "invalid_correlation_id"
    assert replay["result"] is None
    assert submit(api, tokens, ordinary)[0]["result"] == results[2]["result"]
    assert submit(api, tokens, child)[0]["result"] == results[3]["result"]
    failed_child = submit(api, tokens, deferred)[0]
    assert failed_child["status"] == "failed"
    assert failed_child["reason_code"] == "dependency_failed"
    assert audit(api, tokens) == after  # replay cannot recreate identifying metadata
    assert audit(api, other) == {
        **other_before,
        "family_current_encrypted": False,
        "sensitive_changes_encrypted": False,
    }
    assert submit(api, other, other_write)[0]["result"] == other_result["result"]
    if action == "delete":
        assert api.client.get(PATH + "/" + kept["id"], headers=owner).status_code == 503
        assert submit(api, tokens, retained)[0]["result"] == results[1]["result"]
    api.client.app.state.settings = settings
    assert audit(api, other) == other_before
    if action == "delete":
        assert api.client.get(PATH + "/" + kept["id"], headers=owner).json() == kept


@pytest.mark.parametrize("action", ["delete", "withdraw"])
def test_concurrent_sync_uploads_cannot_commit_after_sensitive_erasure(
    family_api: Api, action: str
):
    api = family_api
    tokens = api.login("sync-family-race@example.com")
    owner = bearer(tokens)
    member, change_id = create_member(api, tokens)
    writes = [linked_write(tokens, change_id) for _ in range(4)]
    gate = Barrier(5)

    def upload(write: dict):
        gate.wait(timeout=30)
        return submit(api, tokens, write)[0]

    def erase():
        gate.wait(timeout=30)
        if action == "delete":
            response = api.client.delete(PATH + "/" + member["id"], headers=owner)
            assert response.status_code == 204
        else:
            consent(api, owner, "withdraw")

    with ThreadPoolExecutor(max_workers=5) as pool:
        uploads = [pool.submit(upload, write) for write in writes]
        erasure = pool.submit(erase)
        for future in uploads:
            result = future.result(timeout=60)
            assert result["status"] in ("confirmed", "failed")
            if result["status"] == "failed":
                assert result["reason_code"] == "invalid_correlation_id"
                assert result["result"] is None
        erasure.result(timeout=60)
    report = audit(api, tokens)
    assert report["family_members"] == report["sensitive_changes"] == 0
    assert report["sync_receipts"] == report["sync_outbox"] == report["sync_dependency_ids"] == 0
    assert report["sync_orphan_event_results"] == report["sync_orphan_event_facts"] == 0
    assert report["events"] == (1 if action == "delete" else 0)
    for write in writes:
        replay = submit(api, tokens, write)[0]
        assert replay["status"] == "failed"
        assert replay["result"] is None
    assert audit(api, tokens) == report
