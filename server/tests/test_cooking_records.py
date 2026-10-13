"""Cooking records through the public HTTP and offline-sync boundaries."""

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_sync_writes import envelope, submit


def _record(_owner: str, **overrides: object) -> dict:
    value = {
        "client_id": new_uuid(),
        "dish_name": "测试宫保鸡丁",
        "source": "external_cooking",
        "verification": "unverified",
        "snapshot": {"format_version": 1, "dish_name": "测试宫保鸡丁"},
        "adjustments": [{"text": "少盐"}],
        "source_context": {"entry": "manual"},
    }
    value.update(overrides)
    return value


def test_record_is_account_scoped_idempotent_and_revision_history_is_append_only(api: Api) -> None:
    alice = api.login("records-alice@example.com")
    body = _record(alice["user"]["id"])
    first = api.client.post("/v1/records", headers=bearer(alice), json=body)
    assert first.status_code == 201, first.text
    record = first.json()
    replay = api.client.post("/v1/records", headers=bearer(alice), json=body)
    assert replay.status_code == 201
    assert replay.json()["id"] == record["id"]

    revision = api.client.post(
        f"/v1/records/{record['id']}/revisions",
        headers=bearer(alice),
        json={"revision_id": new_uuid(), "field": "feedback", "value": {"text": "好吃"}},
    )
    assert revision.status_code == 201, revision.text
    assert revision.json()["revision"] == 1
    history = api.client.get(f"/v1/records/{record['id']}/history", headers=bearer(alice))
    assert history.status_code == 200
    assert len(history.json()["items"]) == 1

    listed = api.client.get("/v1/records", headers=bearer(alice))
    assert listed.status_code == 200
    assert [item["id"] for item in listed.json()["items"]] == [record["id"]]

    bob = api.login("records-bob@example.com")
    assert api.client.get(f"/v1/records/{record['id']}", headers=bearer(bob)).status_code == 404


def test_cooking_mode_client_cannot_self_attest_and_reference_is_required(api: Api) -> None:
    tokens = api.login("records-validation@example.com")
    missing = api.client.post(
        "/v1/records",
        headers=bearer(tokens),
        json=_record(
            tokens["user"]["id"],
            source="cooking_session",
            verification="unverified",
        ),
    )
    assert missing.status_code == 422
    forged = api.client.post(
        "/v1/records",
        headers=bearer(tokens),
        json=_record(
            tokens["user"]["id"],
            source="external_cooking",
            verification="cooking_mode",
        ),
    )
    assert forged.status_code == 422


def test_offline_record_write_is_confirmed_once_and_emits_creation_fact(api: Api) -> None:
    tokens = api.login("records-sync@example.com")
    write = envelope(
        tokens["user"]["id"],
        write_type="cooking_record.create",
        payload={
            "record": {
                "client_id": new_uuid(),
                "dish_name": "离线测试",
                "source": "dining",
                "verification": "unverified",
            }
        },
    )
    first = submit(api, tokens, write)[0]
    assert first["status"] == "confirmed"
    replay = submit(api, tokens, write)[0]
    assert replay["status"] == "already_processed"
    records = api.client.get("/v1/records", headers=bearer(tokens)).json()["items"]
    assert len(records) == 1
    events = api.client.get(
        "/v1/dev/events/count",
        headers=bearer(tokens),
        params={"event_type": "cooking.record_created"},
    )
    assert events.status_code == 200
    assert events.json()["count"] == 1
