"""Account-scoped durable writes, observed only through HTTP on PostgreSQL."""

from tests.accounts_support import Api, bearer, new_uuid


def envelope(owner_id: str, **overrides: object) -> dict:
    item = {
        "format_version": 1,
        "write_type": "experience.event",
        "write_id": new_uuid(),
        "owner_id": owner_id,
        "device_time": "2026-10-08T10:00:00Z",
        "dependencies": [],
        "payload": {
            "event_type": "pipeline.self_check",
            "type_version": 1,
            "device_id": "offline-device",
            "app_version": "test",
            "correlation": {},
            "content": {"ping": "offline"},
        },
    }
    item.update(overrides)
    return item


def submit(api: Api, tokens: dict, *writes: dict):
    response = api.client.post(
        "/v1/sync/writes", headers=bearer(tokens), json={"writes": list(writes)}
    )
    assert response.status_code == 200, response.text
    return response.json()["results"]


def count(api: Api, tokens: dict) -> int:
    response = api.client.get(
        "/v1/dev/events/count",
        headers=bearer(tokens),
        params={"event_type": "pipeline.self_check"},
    )
    assert response.status_code == 200
    return response.json()["count"]


def test_committed_write_replays_same_confirmation_without_another_fact(api: Api) -> None:
    tokens = api.login("queue@example.com")
    write = envelope(tokens["user"]["id"])
    first = submit(api, tokens, write)[0]
    assert first["status"] == "confirmed"
    assert first["result"] == {
        "resource_type": "experience.event",
        "resource_id": write["write_id"],
    }
    # Ignore the first response, as if it was lost after the server committed.
    replay = submit(api, tokens, write)[0]
    assert replay["status"] == "already_processed"
    assert replay["result"] == first["result"]
    assert count(api, tokens) == 1
