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


def test_calendar_context_uses_account_iana_boundaries_and_is_private(api: Api) -> None:
    alice = api.login("calendar-alice@example.com")
    update = api.client.patch(
        "/v1/me",
        headers=bearer(alice),
        json={"timezone": "America/Los_Angeles"},
    )
    assert update.status_code == 200, update.text
    result = api.client.get(
        "/v1/records/calendar-context",
        headers=bearer(alice),
        params={"year": 2026, "month": 3},
    )
    assert result.status_code == 200, result.text
    body = result.json()
    assert body["timezone"] == "America/Los_Angeles"
    assert body["days"][0]["date"] == "2026-03-01"
    assert body["days"][-1]["date"] == "2026-03-31"
    # DST starts on March 8 in this zone; the UTC interval is 23 hours.
    before = body["days"][7]
    assert before["start"] == "2026-03-08T08:00:00+00:00"
    assert before["end"] == "2026-03-09T07:00:00+00:00"
    bob = api.login("calendar-bob@example.com")
    hidden = api.client.get(
        "/v1/records/calendar-context",
        headers=bearer(bob),
        params={"year": 2026, "month": 3},
    )
    assert hidden.json()["timezone"] == "Asia/Shanghai"


def test_personal_record_photos_persist_privately_and_never_use_recipe_images(api: Api) -> None:
    import base64
    import io

    from PIL import Image

    image = io.BytesIO()
    Image.new("RGB", (2, 2), "green").save(image, format="JPEG")
    photo = "data:image/jpeg;base64," + base64.b64encode(image.getvalue()).decode()
    alice = api.login("record-photos@example.com")
    body = _record(alice["user"]["id"], photos=[photo])
    created = api.client.post("/v1/records", headers=bearer(alice), json=body)
    assert created.status_code == 201, created.text
    record = created.json()
    assert record["photos"] == [photo]
    assert (
        api.client.post("/v1/records", headers=bearer(alice), json=body).json()["id"]
        == record["id"]
    )
    changed = {**body, "photos": []}
    assert api.client.post("/v1/records", headers=bearer(alice), json=changed).status_code == 409
    assert api.client.get("/v1/records", headers=bearer(alice)).json()["items"][0]["photos"] == [
        photo
    ]
    bob = api.login("record-photos-other@example.com")
    assert api.client.get("/v1/records", headers=bearer(bob)).json()["items"] == []
    assert api.client.get(f"/v1/records/{record['id']}", headers=bearer(bob)).status_code == 404
    # Recipe snapshots are not personal record photos.
    plain = api.client.post(
        "/v1/records",
        headers=bearer(alice),
        json=_record(alice["user"]["id"], snapshot={"images": ["https://recipe.test/image.jpg"]}),
    )
    assert plain.json()["photos"] == []
    bad = api.client.post(
        "/v1/records",
        headers=bearer(alice),
        json=_record(alice["user"]["id"], photos=["https://recipe.test/image.jpg"]),
    )
    assert bad.status_code == 422
    write = envelope(
        alice["user"]["id"],
        write_type="cooking_record.create",
        payload={"record": _record(alice["user"]["id"], photos=[photo])},
    )
    synced = submit(api, alice, write)[0]
    assert synced["status"] == "confirmed"
    assert all(
        item["photos"] in ([], [photo])
        for item in api.client.get("/v1/records", headers=bearer(alice)).json()["items"]
    )


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
