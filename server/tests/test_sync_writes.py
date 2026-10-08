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


def test_same_id_cannot_change_content_or_transfer_to_another_account(api: Api) -> None:
    alice = api.login("alice@example.com")
    bob = api.login("bob@example.com")
    original = envelope(alice["user"]["id"])
    confirmation = submit(api, alice, original)[0]
    changed = {**original, "payload": {**original["payload"], "content": {"ping": "changed"}}}
    assert submit(api, alice, changed)[0]["reason_code"] == "write_id_reused"
    wrong_owner = submit(api, bob, original)[0]
    assert wrong_owner["reason_code"] == "owner_mismatch"
    assert wrong_owner["result"] is None
    disguised = {**original, "owner_id": bob["user"]["id"]}
    result = submit(api, bob, disguised)[0]
    assert result["status"] == "failed"
    assert result["result"] is None
    assert count(api, alice) == 1
    assert count(api, bob) == 0
    assert submit(api, alice, original)[0]["result"] == confirmation["result"]


def test_child_first_defers_then_parent_arrives_and_child_resumes(api: Api) -> None:
    tokens = api.login("dependencies@example.com")
    parent = envelope(tokens["user"]["id"])
    child = envelope(tokens["user"]["id"], dependencies=[parent["write_id"]])
    first = submit(api, tokens, child, parent)
    assert first[0]["status"] == "deferred"
    assert first[0]["reason_code"] == "dependency_not_arrived"
    assert first[1]["status"] == "confirmed"
    assert count(api, tokens) == 1
    assert submit(api, tokens, child)[0]["status"] == "confirmed"
    assert count(api, tokens) == 2


def test_dependency_cycle_and_unknown_dependency_never_pretend_success(api: Api) -> None:
    tokens = api.login("cycle@example.com")
    a, b = new_uuid(), new_uuid()
    first = envelope(tokens["user"]["id"], write_id=a, dependencies=[b])
    second = envelope(tokens["user"]["id"], write_id=b, dependencies=[a])
    assert submit(api, tokens, first)[0]["status"] == "deferred"
    assert submit(api, tokens, second)[0]["reason_code"] == "dependency_cycle"
    assert submit(api, tokens, first)[0]["status"] == "failed"
    assert count(api, tokens) == 0


def test_unregistered_or_invalid_business_content_and_analytics_are_rejected(api: Api) -> None:
    tokens = api.login("validation@example.com")
    unknown = envelope(tokens["user"]["id"], write_type="arbitrary.upload")
    analytics = envelope(tokens["user"]["id"])
    analytics["payload"]["event_type"] = "analytics.click"
    bad = envelope(tokens["user"]["id"])
    bad["payload"]["content"] = {"no_ping": "invalid"}
    results = submit(api, tokens, unknown, analytics, bad)
    assert [r["reason_code"] for r in results] == [
        "unknown_write_type",
        "unknown_event_type",
        "invalid_content",
    ]
    assert count(api, tokens) == 0


def test_client_composition_observation_replays_but_cannot_forge_recipe_fact(api: Api) -> None:
    tokens = api.login("composition-observation@example.com")
    observation = envelope(tokens["user"]["id"])
    observation["payload"].update(
        event_type="ui.composition_shown",
        content={"page_type": "today", "components": [], "is_fallback": True},
    )
    first = submit(api, tokens, observation)[0]
    assert first["status"] == "confirmed"
    replay = submit(api, tokens, observation)[0]
    assert replay["status"] == "already_processed"
    assert replay["result"] == first["result"]
    facts = api.client.get(
        "/v1/dev/events/count",
        headers=bearer(tokens),
        params={"event_type": "ui.composition_shown"},
    )
    assert facts.status_code == 200
    assert facts.json()["count"] == 1
    forged = envelope(tokens["user"]["id"])
    forged["payload"].update(
        event_type="recipe.version_saved",
        correlation={"recipe_version_id": new_uuid()},
        content={"recipe_version_id": new_uuid()},
    )
    assert submit(api, tokens, forged)[0]["reason_code"] == "server_fact_only"


def test_different_devices_append_distinct_facts_even_with_same_time(api: Api) -> None:
    tokens = api.login("append@example.com")
    first = envelope(tokens["user"]["id"])
    second = envelope(tokens["user"]["id"])
    second["payload"]["device_id"] = "other-device"
    assert [r["status"] for r in submit(api, tokens, first, second)] == ["confirmed", "confirmed"]
    assert count(api, tokens) == 2


def test_legacy_http_delivery_is_migrated_without_double_fact(api: Api) -> None:
    tokens = api.login("legacy@example.com")
    write = envelope(tokens["user"]["id"])
    old = {**write["payload"], "id": write["write_id"], "device_time": "2026-10-08T18:00:00+08:00"}
    response = api.client.post("/v1/events/upload", headers=bearer(tokens), json={"events": [old]})
    assert response.status_code == 200
    assert submit(api, tokens, write)[0]["status"] == "confirmed"
    assert count(api, tokens) == 1


def test_invalid_parent_is_terminal_and_child_reports_failed_dependency(api: Api) -> None:
    tokens = api.login("invalid-parent@example.com")
    parent = envelope(tokens["user"]["id"])
    parent["payload"]["content"] = {"no_ping": "invalid"}
    child = envelope(tokens["user"]["id"], dependencies=[parent["write_id"]])
    assert submit(api, tokens, child)[0]["status"] == "deferred"
    assert submit(api, tokens, parent)[0]["reason_code"] == "invalid_content"
    assert submit(api, tokens, child)[0]["reason_code"] == "dependency_failed"
    repaired = {**parent, "payload": {**parent["payload"], "content": {"ping": "fixed"}}}
    assert submit(api, tokens, repaired)[0]["reason_code"] == "write_id_reused"
    assert count(api, tokens) == 0


def test_due_deletion_purges_only_owners_delivery_receipts_and_outbox(api: Api) -> None:
    from tests.test_account_deletion import _purge, _reauth_email

    alice = api.login("purge-queue@example.com")
    bob = api.login("keep-queue@example.com")
    rejected = envelope(alice["user"]["id"], write_type="unregistered.old_type")
    assert submit(api, alice, rejected)[0]["status"] == "failed"
    committed = envelope(alice["user"]["id"])
    assert submit(api, alice, committed)[0]["status"] == "confirmed"
    kept = envelope(bob["user"]["id"])
    stable = submit(api, bob, kept)[0]["result"]
    claimed = envelope(bob["user"]["id"], write_id=rejected["write_id"])
    assert submit(api, bob, claimed)[0]["reason_code"] == "write_id_unavailable"
    assert _reauth_email(api, alice, "purge-queue@example.com") == 204
    deletion = api.client.post("/v1/me/deletion", headers=bearer(alice))
    assert deletion.status_code == 202
    assert "已删除 0 个" in _purge(api.clock.now.isoformat())
    assert submit(api, bob, claimed)[0]["reason_code"] == "write_id_unavailable"
    # A committed receipt has an outbox FK: administrative purge must remove
    # the fact bundle first, then delivery receipts, while retaining the User ID.
    assert "已删除 1 个" in _purge(deletion.json()["deletion_due_at"])
    assert submit(api, bob, claimed)[0]["status"] == "confirmed"
    assert submit(api, bob, kept)[0]["result"] == stable
    assert count(api, bob) == 2
    assert (
        api.client.post(
            "/v1/sync/writes", headers=bearer(alice), json={"writes": [committed]}
        ).status_code
        == 401
    )


def test_concurrent_replays_produce_one_confirmation_and_one_fact(api: Api) -> None:
    from concurrent.futures import ThreadPoolExecutor

    tokens = api.login("concurrent@example.com")
    write = envelope(tokens["user"]["id"])
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda _: submit(api, tokens, write)[0], range(4)))
    assert sum(r["status"] == "confirmed" for r in results) == 1
    assert sum(r["status"] == "already_processed" for r in results) == 3
    assert all(r["result"] == results[0]["result"] for r in results)
    assert count(api, tokens) == 1
