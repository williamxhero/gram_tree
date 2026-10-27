"""Dietary history is observed only through authenticated public HTTP APIs."""

from pathlib import Path

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer, new_uuid
from tests.cooking_completion_support import complete_recipe
from tests.test_recipes import recipe_input
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


def test_version_distributions_merged_dishes_and_all_history_first_attempts(api: Api):
    assert cli(["ingredients", "import", str(Path(__file__).parents[1] / "data/ingredients")]) == 0
    tokens = api.login("dietary-versions@example.com")
    chicken = api.client.post("/v1/ingredients/search", json={"query": "鸡腿肉"}).json()["items"][0]
    body = recipe_input("统计鸡丁")
    body["dish_aliases"] = ["统计鸡丁别名"]
    body["snapshot"]["cuisine"] = "川菜"
    body["snapshot"]["ingredients"][0]["ingredient_id"] = chicken["id"]
    first = api.client.post("/v1/recipes", headers=bearer(tokens), json=body)
    assert first.status_code == 201, first.text
    first = first.json()
    # A second recipe and version for the same dish must not become new identities.
    body["snapshot"]["cuisine"] = None
    second = api.client.post("/v1/recipes", headers=bearer(tokens), json=body)
    assert second.status_code == 201, second.text
    second = second.json()
    updated = api.client.post(
        f"/v1/recipes/{first['id']}/versions", headers=bearer(tokens), json=body
    )
    assert updated.status_code == 201, updated.text
    updated = updated.json()
    for detail, at in [(first, "2026-01-01T04:00:00Z"), (first, "2026-03-01T04:00:00Z"),
                       (second, "2026-03-02T04:00:00Z"), (updated, "2026-03-03T04:00:00Z")]:
        record(api, tokens, at, source="calendar", recipe_id=detail["id"],
               recipe_version_id=detail["version"]["id"], dish_name="自由显示名")
    # Alias-only manual dishes must resolve even without an in-range recipe.
    alias_body = recipe_input("统计豆腐")
    alias_body["dish_aliases"] = ["统计豆腐别名"]
    alias = api.client.post("/v1/recipes", headers=bearer(tokens), json=alias_body)
    assert alias.status_code == 201, alias.text
    record(api, tokens, "2026-03-04T04:00:00Z", dish_name="统计豆腐别名")
    # A freeform/external snapshot is not a trusted version classification.
    record(api, tokens, "2026-03-05T04:00:00Z", snapshot=first["version"]["snapshot"])
    month = statistics(api, tokens)
    assert month["cooking_count"] == 5
    assert month["ingredient_record_count"] == 3
    assert month["ingredient_distribution"] == [{"key": chicken["category"], "count": 3}]
    assert month["cuisine_distribution"] == [
        {"key": "unclassified", "count": 4},
        {"key": "川菜", "count": 1},
    ]
    assert [(d["name"], d["count"]) for d in month["frequent_dishes"]] == [
        ("统计鸡丁", 3),
        ("统计豆腐", 1),
    ]
    assert month["frequent_dishes"][0]["first_cooked_at"] == "2026-03-01T04:00:00+00:00"
    assert [d["name"] for d in month["new_dishes"]] == ["统计豆腐"]
    # A backfill before the range changes first attempts, including cached results.
    record(api, tokens, "2025-12-01T04:00:00Z", dish_name="统计豆腐别名")
    assert statistics(api, tokens)["new_dishes"] == []
    completed = complete_recipe(api, tokens, first)
    current = statistics(api, tokens, anchor="2026-10-27")
    assert current["cooking_count"] == 1
    assert current["frequent_dishes"][0]["dish_id"] == first["dish"]["id"]
    assert completed["counts_as_cooked"] is True

