"""Dietary history is observed only through authenticated public HTTP APIs."""

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_sync_writes import envelope, submit

PATH = "/v1/dietary-history/statistics"


def record(api: Api, tokens: dict, at: str, **values: object) -> dict:
    response = api.client.post(
        "/v1/records",
        headers=bearer(tokens),
        json={
            "client_id": new_uuid(),
            "source": "external_cooking",
            "dish_name": "未匹配的家常菜",
            "occurred_at": at,
            **values,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def statistics(api: Api, tokens: dict, **params: str) -> dict:
    response = api.client.get(
        PATH, headers=bearer(tokens), params={"period": "month", "anchor": "2026-03-15", **params}
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_counts_backfill_external_and_manual_but_not_dining_and_keeps_owner_private(api: Api):
    alice = api.login("dietary-alice@example.com")
    first = statistics(api, alice)
    assert first["cooking_count"] == 0
    assert first["frequent_dishes"] == []
    record(api, alice, "2026-03-31T15:30:00Z", source="calendar")
    record(api, alice, "2026-03-31T16:00:00Z")  # April in account timezone.
    record(api, alice, "2026-03-01T04:00:00Z")
    record(api, alice, "2026-03-01T04:00:00Z", source="dining")
    month = statistics(api, alice)
    assert month["cooking_count"] == 2
    assert month["unclassified_dish_count"] == 2
    assert month["new_dishes"] == []  # Unknown text is not a canonical dish identity.
    assert month["ingredient_distribution"] == []
    assert month["cuisine_distribution"] == [{"key": "unclassified", "count": 2}]
    assert month["start_at"] == "2026-02-28T16:00:00+00:00"
    assert month["end_at"] == "2026-03-31T16:00:00+00:00"
    bob = api.login("dietary-bob@example.com")
    assert statistics(api, bob)["cooking_count"] == 0
    assert api.client.get(PATH).status_code == 401
    assert api.client.get(PATH, headers=bearer(alice), params={"period": "day"}).status_code == 422


def test_real_sync_create_revision_and_delete_invalidate_cached_results(api: Api):
    tokens = api.login("dietary-sync@example.com")
    before = statistics(api, tokens)
    write = envelope(
        tokens["user"]["id"],
        write_type="cooking_record.create",
        payload={"record": {
            "client_id": new_uuid(), "source": "calendar", "dish_name": "补记",
            "occurred_at": "2026-03-02T08:00:00Z",
        }},
    )
    assert submit(api, tokens, write)[0]["status"] == "confirmed"
    after = statistics(api, tokens)
    assert after["cooking_count"] == 1
    assert after["generated_at"] != before["generated_at"]
    assert statistics(api, tokens)["generated_at"] == after["generated_at"]
    row = api.client.get("/v1/records", headers=bearer(tokens)).json()["items"][0]
    revised = api.client.post(
        f"/v1/records/{row['id']}/revisions", headers=bearer(tokens),
        json={"revision_id": new_uuid(), "field": "rating", "value": {"score": 4}},
    )
    assert revised.status_code == 201, revised.text
    updated = statistics(api, tokens)
    assert updated["generated_at"] != after["generated_at"]
    assert updated["cooking_count"] == 1
    deleted = api.client.delete(f"/v1/records/{row['id']}", headers=bearer(tokens))
    assert deleted.status_code == 204, deleted.text
    assert statistics(api, tokens)["cooking_count"] == 0


def test_account_timezone_half_open_dst_week_and_leap_year(api: Api):
    tokens = api.login("dietary-timezone@example.com")
    # 00:00 local Monday before DST and next Monday after it: 167 hours.
    changed = api.client.patch(
        "/v1/me", headers=bearer(tokens), json={"timezone": "America/New_York"}
    )
    assert changed.status_code == 200, changed.text
    record(api, tokens, "2026-03-02T04:59:59Z")
    record(api, tokens, "2026-03-02T05:00:00Z")
    record(api, tokens, "2026-03-09T03:59:59Z")
    record(api, tokens, "2026-03-09T04:00:00Z")
    week = statistics(api, tokens, period="week", anchor="2026-03-08")
    assert week["start_at"] == "2026-03-02T05:00:00+00:00"
    assert week["end_at"] == "2026-03-09T04:00:00+00:00"
    assert week["cooking_count"] == 2
    assert week["timezone"] == "America/New_York"
    api.client.patch("/v1/me", headers=bearer(tokens), json={"timezone": "UTC"})
    utc_week = statistics(api, tokens, period="week", anchor="2026-03-08")
    assert utc_week["cooking_count"] == 2
    assert utc_week["start_at"] == "2026-03-02T00:00:00+00:00"
    assert utc_week["generated_at"] != week["generated_at"]
    leap = statistics(api, tokens, anchor="2024-02-29")
    assert leap["local_start"] == "2024-02-01"
    assert leap["local_end"] == "2024-03-01"
    year = statistics(api, tokens, period="year", anchor="2024-02-29")
    assert year["local_end"] == "2025-01-01"
