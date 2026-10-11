"""Offline manual saves observed via real PostgreSQL HTTP interfaces."""

from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_recipes import recipe_input
from tests.test_sync_writes import envelope, submit


def create(api: Api, tokens: dict) -> dict:
    response = api.client.post("/v1/recipes", headers=bearer(tokens), json=recipe_input())
    assert response.status_code == 201, response.text
    return response.json()


def save_write(tokens: dict, detail: dict, quantity: int = 320, **overrides: object) -> dict:
    snapshot = deepcopy(detail["version"]["snapshot"])
    snapshot["ingredients"][0]["quantity"] = quantity
    payload = {
        "recipe_id": detail["id"],
        "candidate_version_id": new_uuid(),
        "baseline_version_id": detail["version"]["id"],
        "candidate": {"snapshot": snapshot, "change_note": "离线手工修改", "ai_assisted": False},
    }
    payload.update(overrides)
    return envelope(tokens["user"]["id"], write_type="recipe_version.save", payload=payload)


def test_offline_recipe_retry_returns_same_version_and_single_save_fact(api: Api) -> None:
    tokens = api.login("offline-recipe@example.com")
    original = create(api, tokens)
    write = save_write(tokens, original)
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: submit(api, tokens, write)[0], range(2)))
    assert sorted(result["status"] for result in results) == ["already_processed", "confirmed"]
    first = next(result for result in results if result["status"] == "confirmed")
    assert results[0]["result"] == results[1]["result"]
    assert first["result"]["resource_type"] == "recipe.version"
    assert first["result"]["resource_id"] == write["payload"]["candidate_version_id"]
    assert first["result"]["values"]["detail"]["version"]["version_number"] == 2
    replay = submit(api, tokens, write)[0]
    assert replay["status"] == "already_processed"
    assert replay["result"] == first["result"]
    history = api.client.get(f"/v1/recipes/{original['id']}/versions", headers=bearer(tokens))
    assert len(history.json()["items"]) == 2
    old = api.client.get(
        f"/v1/recipes/{original['id']}/versions/{original['version']['id']}",
        headers=bearer(tokens),
    ).json()
    assert old["version"]["snapshot"]["ingredients"][0]["quantity"] == 300
    current = api.client.get(f"/v1/recipes/{original['id']}", headers=bearer(tokens)).json()
    assert current["version"]["snapshot"]["ingredients"][0]["quantity"] == 320
    assert current["visibility"] == "private"
    facts = api.client.get(
        "/v1/dev/events/count",
        headers=bearer(tokens),
        params={"event_type": "recipe.version_saved"},
    )
    assert facts.json()["count"] == 2  # initial creation and exactly one offline save


def test_offline_recipe_chain_resolves_typed_baseline_and_registered_event(api: Api) -> None:
    tokens = api.login("offline-recipe-chain@example.com")
    original = create(api, tokens)
    a = save_write(tokens, original, 320)
    b = save_write(tokens, original, 350, baseline_version_id=None, baseline_write_id=a["write_id"])
    b["dependencies"] = [a["write_id"]]
    event = envelope(tokens["user"]["id"], dependencies=[b["write_id"]])
    event["payload"]["recipe_version_write_id"] = b["write_id"]
    results = submit(api, tokens, event, b, a)
    assert [result["status"] for result in results] == ["deferred", "deferred", "confirmed"]
    assert submit(api, tokens, b)[0]["status"] == "confirmed"
    assert submit(api, tokens, event)[0]["status"] == "confirmed"
    assert submit(api, tokens, event)[0]["status"] == "already_processed"
    detail = api.client.get(f"/v1/recipes/{original['id']}", headers=bearer(tokens)).json()
    assert detail["version"]["id"] == b["payload"]["candidate_version_id"]
    assert detail["version"]["previous_version_id"] == a["payload"]["candidate_version_id"]
    assert detail["version"]["snapshot"]["ingredients"][0]["quantity"] == 350
    for event_type, expected in [("pipeline.self_check", 1), ("recipe.version_saved", 3)]:
        count = api.client.get(
            "/v1/dev/events/count", headers=bearer(tokens), params={"event_type": event_type}
        )
        assert count.json()["count"] == expected


def test_offline_recipe_conflict_preserves_copies_children_and_online_compatibility(
    api: Api,
) -> None:
    tokens = api.login("offline-recipe-conflict@example.com")
    original = create(api, tokens)
    a = save_write(tokens, original, 320)
    loser = save_write(tokens, original, 400)
    assert submit(api, tokens, a)[0]["status"] == "confirmed"
    conflict = submit(api, tokens, loser)[0]
    assert conflict["status"] == "conflict"
    assert conflict["conflict"]["local"]["snapshot"]["ingredients"][0]["quantity"] == 400
    assert (
        conflict["conflict"]["remote"]["version"]["snapshot"]["ingredients"][0]["quantity"] == 320
    )
    assert submit(api, tokens, loser)[0] == conflict
    child = save_write(
        tokens, original, 450, baseline_version_id=None, baseline_write_id=loser["write_id"]
    )
    child["dependencies"] = [loser["write_id"]]
    blocked = submit(api, tokens, child)[0]
    assert blocked["status"] == "deferred"
    assert blocked["reason_code"] == "dependency_conflict"
    history = api.client.get(
        f"/v1/recipes/{original['id']}/versions", headers=bearer(tokens)
    ).json()
    assert len(history["items"]) == 2
    # The existing online API deliberately still accepts an older baseline.
    online = api.client.post(
        f"/v1/recipes/{original['id']}/versions",
        headers=bearer(tokens),
        json={
            "snapshot": original["version"]["snapshot"],
            "base_version_id": original["version"]["id"],
        },
    )
    assert online.status_code == 201, online.text
    assert online.json()["version"]["version_number"] == 3


def test_offline_recipe_permissions_and_invalid_candidates_do_not_mutate(api: Api) -> None:
    alice = api.login("offline-recipe-owner@example.com")
    original = create(api, alice)
    bob = api.login("offline-recipe-intruder@example.com")
    forbidden = save_write(bob, original)
    rejected = submit(api, bob, forbidden)[0]
    assert rejected["status"] == "failed"
    assert rejected["reason_code"] == "recipe_not_writable"
    assert rejected["result"] is None and rejected["conflict"] is None
    invalid = save_write(alice, original)
    invalid["payload"]["candidate"]["snapshot"]["steps"][0]["depends_on"] = ["does-not-exist"]
    assert submit(api, alice, invalid)[0]["reason_code"] == "invalid_recipe"
    unhealthy = save_write(alice, original)
    unhealthy["payload"]["candidate"]["snapshot"]["description"] = "治疗糖尿病"
    assert submit(api, alice, unhealthy)[0]["reason_code"] == "prohibited_health_claim"
    history = api.client.get(f"/v1/recipes/{original['id']}/versions", headers=bearer(alice)).json()
    assert len(history["items"]) == 1
