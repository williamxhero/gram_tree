"""SPEC47 baseline erasure at the agreed HTTP/CLI seams, real PostgreSQL."""

from datetime import datetime

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_account_deletion import _purge, _reauth_email
from tests.test_offline_recipe_sync import save_write
from tests.test_recipes import recipe_input
from tests.test_sync_writes import submit


def _recipe(api: Api, tokens: dict, name: str = "删除测试菜") -> dict:
    body = recipe_input(name)
    body["dish_aliases"] = []
    response = api.client.post("/v1/recipes", headers=bearer(tokens), json=body)
    assert response.status_code == 201, response.text
    return response.json()


def _record(api: Api, tokens: dict, recipe: dict | None = None, **overrides) -> dict:
    body = {
        "client_id": new_uuid(),
        "source": "external_cooking",
        "snapshot": {"personal_text": "私人快照"},
        "adjustments": [{"text": "私人临场原话"}],
        "source_context": {"device_id": "私人设备", "ip": "192.0.2.1"},
    }
    if recipe:
        body.update(recipe_id=recipe["id"], recipe_version_id=recipe["version"]["id"])
    body.update(overrides)
    response = api.client.post("/v1/records", headers=bearer(tokens), json=body)
    assert response.status_code == 201, response.text
    return response.json()


def _storage(api: Api, tokens: dict, owner: str | None = None) -> dict:
    response = api.client.get(
        "/v1/dev/deletion-storage",
        headers=bearer(tokens),
        params={"owner_id": owner} if owner else {},
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_preview_requires_auth_and_unexpired_reauth_and_has_no_default_action(api: Api) -> None:
    assert api.client.get("/v1/me/deletion").status_code == 401
    tokens = api.login("preview@example.com")
    assert api.client.get("/v1/me/deletion", headers=bearer(tokens)).status_code == 403
    assert _reauth_email(api, tokens, "preview@example.com") == 204
    response = api.client.get("/v1/me/deletion", headers=bearer(tokens))
    assert response.status_code == 200, response.text
    preview = response.json()
    assert preview["public_recipes"] == []
    assert preview["public_recipe_action_required"] is False
    assert preview["can_export"] is True
    assert preview["deletes"] and preview["retains"]
    api.clock.advance(minutes=11)
    assert api.client.get("/v1/me/deletion", headers=bearer(tokens)).status_code == 403


def test_single_record_delete_is_private_erases_revisions_events_and_deduplicates_statistics(
    api: Api,
) -> None:
    alice = api.login("record-delete@example.com")
    bob = api.login("record-isolation@example.com")
    recipe = _recipe(api, alice)
    record = _record(api, alice, recipe)
    second = _record(api, alice, recipe)
    other = _record(api, bob)
    revision = api.client.post(
        f"/v1/records/{record['id']}/revisions",
        headers=bearer(alice),
        json={
            "revision_id": new_uuid(),
            "field": "rating",
            "value": {"score": 4, "text": "不能留下的原话", "user_id": alice["user"]["id"]},
            "note": "不能留下的说明",
        },
    )
    assert revision.status_code == 201, revision.text
    path = f"/v1/records/{record['id']}"
    assert api.client.delete(path).status_code == 401
    assert api.client.delete(path, headers=bearer(bob)).status_code == 404
    assert api.client.get(path, headers=bearer(alice)).status_code == 200
    assert api.client.delete(path, headers=bearer(alice)).status_code == 204
    assert api.client.get(path, headers=bearer(alice)).status_code == 404
    assert api.client.get(path + "/history", headers=bearer(alice)).status_code == 404
    assert api.client.delete(path, headers=bearer(alice)).status_code == 404
    assert api.client.get(f"/v1/records/{other['id']}", headers=bearer(bob)).json() == other
    stats = _storage(api, alice)["anonymous_statistics"]
    assert len(stats) == 1 and stats[0]["contributions"] == 1
    assert stats[0]["dimensions"]["rating"] == 4
    assert set(stats[0]) == {"recipe_version_id", "week", "dimensions", "contributions"}
    assert set(stats[0]["dimensions"]) == {
        "rating",
        "standard_tags",
        "verification",
        "taste_levels",
    }
    assert datetime.fromisoformat(stats[0]["week"]).weekday() == 0
    assert "私人" not in str(stats) and alice["user"]["id"] not in str(stats)
    assert (
        api.client.delete(f"/v1/records/{second['id']}", headers=bearer(alice)).status_code == 204
    )
    assert _storage(api, alice)["anonymous_statistics"] == stats
    count = api.client.get(
        "/v1/dev/events/count",
        headers=bearer(alice),
        params={"event_type": "cooking.record_created"},
    )
    assert count.json() == {"count": 0}
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(alice)).status_code == 200


def test_private_recipe_delete_removes_all_versions_and_indexes_but_keeps_frozen_record(
    api: Api,
) -> None:
    alice = api.login("recipe-delete@example.com")
    bob = api.login("recipe-keep@example.com")
    recipe = _recipe(api, alice, "仅我菜谱")
    other = _recipe(api, bob, "他人菜谱")
    record = _record(api, alice, recipe)
    edited = recipe_input("仅我菜谱")
    edited["dish_aliases"] = []
    version = api.client.post(
        f"/v1/recipes/{recipe['id']}/versions", headers=bearer(alice), json=edited
    )
    assert version.status_code == 201, version.text
    path = f"/v1/recipes/{recipe['id']}"
    assert api.client.delete(path, headers=bearer(bob)).status_code == 404
    assert api.client.delete(path, headers=bearer(alice)).status_code == 204
    assert api.client.get(path, headers=bearer(alice)).status_code == 404
    assert (
        api.client.get(
            path + f"/versions/{recipe['version']['id']}", headers=bearer(alice)
        ).status_code
        == 404
    )
    assert api.client.get("/v1/recipes", headers=bearer(alice)).json()["items"] == []
    assert api.client.get(f"/v1/recipes/{other['id']}", headers=bearer(bob)).json() == other
    assert api.client.get(f"/v1/records/{record['id']}", headers=bearer(alice)).json() == record
    count = api.client.get(
        "/v1/dev/events/count", headers=bearer(alice), params={"event_type": "recipe.version_saved"}
    )
    assert count.json() == {"count": 0}
    storage = _storage(api, alice)
    assert storage["owned_counts"]["recipe_save_outbox"] == 0
    assert storage["pending_objects"] == 0


def test_deleted_private_recipe_cannot_be_replayed_from_confirmed_or_conflicting_sync(
    api: Api,
) -> None:
    alice = api.login("erased-sync@example.com")
    original = _recipe(api, alice)
    accepted = save_write(alice, original, 320)
    conflicting = save_write(alice, original, 400)
    assert submit(api, alice, accepted)[0]["status"] == "confirmed"
    assert submit(api, alice, conflicting)[0]["status"] == "conflict"
    path = f"/v1/recipes/{original['id']}"
    assert api.client.delete(path, headers=bearer(alice)).status_code == 204
    for write in (accepted, conflicting):
        replay = submit(api, alice, write)[0]
        assert replay["status"] == "failed"
        assert replay["reason_code"] == "resource_deleted"
        assert replay["result"] is None and replay["conflict"] is None
        assert "私人" not in str(replay)
    assert api.client.get(path, headers=bearer(alice)).status_code == 404
    assert _storage(api, alice)["owned_counts"]["write_fact_outbox"] == 0


def test_due_account_erasure_removes_implemented_domains_has_content_free_steps_and_is_idempotent(
    api: Api,
) -> None:
    alice = api.login("full-delete@example.com")
    bob = api.login("full-keep@example.com")
    recipe = _recipe(api, alice)
    _record(api, alice, recipe)
    _record(api, alice, recipe)
    other = _record(api, bob)
    assert (
        api.client.patch(
            "/v1/me/taste-profile", headers=bearer(alice), json={"flavors": {"salty": 0.75}}
        ).status_code
        == 200
    )
    assert (
        api.client.post(
            "/v1/me/measures",
            headers=bearer(alice),
            json={"name": "私人勺", "kind": "spoon", "capacity_ml": 12},
        ).status_code
        == 201
    )
    assert (
        api.client.get(
            "/v1/dev/deletion-storage",
            headers=bearer(bob),
            params={"owner_id": alice["user"]["id"]},
        ).status_code
        == 404
    )
    assert _reauth_email(api, alice, "full-delete@example.com") == 204
    requested = api.client.post(
        "/v1/me/deletion", headers=bearer(alice), json={"public_recipe_action": None}
    )
    assert requested.status_code == 202, requested.text
    due = requested.json()["deletion_due_at"]
    assert "已删除 0 个" in _purge(api.clock.now.isoformat())
    assert "已删除 1 个" in _purge(due)
    storage = _storage(api, bob, alice["user"]["id"])
    assert all(count == 0 for count in storage["owned_counts"].values()), storage
    assert storage["completed_at"] == due
    assert set(storage["steps"]) == {
        "requested",
        "personal_data_erased",
        "objects_erased",
        "caches_erased",
    }
    assert all(datetime.fromisoformat(value) for value in storage["steps"].values())
    assert storage["anonymous_statistics"][0]["contributions"] == 1
    assert alice["user"]["id"] not in str(storage)
    assert "私人" not in str(storage)
    assert "已删除 0 个" in _purge(due)
    assert (
        _storage(api, bob, alice["user"]["id"])["anonymous_statistics"]
        == storage["anonymous_statistics"]
    )
    assert api.client.get(f"/v1/records/{other['id']}", headers=bearer(bob)).json() == other
    assert api.client.get("/v1/me", headers=bearer(alice)).status_code == 401
