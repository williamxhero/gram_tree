"""Publication eligibility and lifecycle through authenticated HTTP only."""

from copy import deepcopy

import pytest

from tests.accounts_support import Api, bearer, new_uuid
from tests.cooking_completion_support import complete_recipe, completed_record_body
from tests.test_ai_recipes import configure
from tests.test_recipe_improvements import event_count
from tests.test_recipes import _image_payload, recipe_input


def create(api: Api, tokens: dict, name: str = "公开测试") -> dict:
    body = recipe_input(name)
    body["snapshot"]["steps"][1]["heat"] = "大火，油面波纹"
    response = api.client.post("/v1/recipes", headers=bearer(tokens), json=body)
    assert response.status_code == 201, response.text
    return response.json()


def test_new_recipe_is_draft_and_has_actionable_publication_conditions(api: Api) -> None:
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    recipe = create(api, author)
    panel = api.client.get(f"/v1/recipes/{recipe['id']}/publication", headers=bearer(author))
    assert panel.status_code == 200, panel.text
    assert panel.json()["state"] == "draft"
    assert panel.json()["ever_public"] is False
    assert panel.json()["automatically_publishes"] is True
    assert {item["code"] for item in panel.json()["missing"]} == {"not_cooked"}
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 404
    assert (
        api.client.get(
            f"/v1/recipes/{recipe['id']}/publication", headers=bearer(reader)
        ).status_code
        == 404
    )


def panel(api: Api, author: dict, recipe: dict, version_id: str | None = None) -> dict:
    response = api.client.get(
        f"/v1/recipes/{recipe['id']}/publication",
        headers=bearer(author),
        params={"version_id": version_id} if version_id else {},
    )
    assert response.status_code == 200, response.text
    return response.json()


def save(api: Api, author: dict, recipe: dict, snapshot: dict) -> dict:
    response = api.client.post(
        f"/v1/recipes/{recipe['id']}/versions",
        headers=bearer(author),
        json={"snapshot": snapshot},
    )
    assert response.status_code == 201, response.text
    return response.json()


@pytest.mark.parametrize("view", ["original", "personalized"])
def test_author_completion_publishes_once_with_private_proof_and_one_license(api: Api, view: str):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    recipe = create(api, author)
    snapshot = deepcopy(recipe["version"]["snapshot"])
    body = completed_record_body(api, author, recipe, view=view)
    result = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert result.status_code == 201, result.text
    replay = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert replay.status_code == 201, replay.text
    assert replay.json()["id"] == result.json()["id"]
    for _ in range(2):
        assert panel(api, author, recipe)["state"] == "published"
    assert event_count(api, author, "recipe.version_published") == 1
    response = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader))
    assert response.status_code == 200, response.text
    public = response.json()
    assert public["version"]["publication_state"] == "published"
    assert public["version"]["snapshot"] == snapshot
    assert public["version"]["edit_operations"] == []
    assert "CC BY-NC-SA 4.0" in public["license"]
    assert result.json()["id"] not in response.text
    assert "verification_record_id" not in response.text
    assert (
        api.client.get(f"/v1/records/{result.json()['id']}", headers=bearer(reader)).status_code
        == 404
    )
    notices = api.client.get("/v1/recipes/publication/notifications", headers=bearer(author)).json()
    assert len(notices["items"]) == 1
    assert "CC BY-NC-SA 4.0" in notices["license_notice"]
    assert api.client.get(
        "/v1/recipes/publication/notifications", headers=bearer(reader)
    ).json() == {"items": [], "next_cursor": None, "license_notice": None}
    acknowledgement = {"notification_ids": [notices["items"][0]["id"]], "license_seen": True}
    for _ in range(2):
        assert (
            api.client.post(
                "/v1/recipes/publication/notifications/acknowledge",
                headers=bearer(author),
                json=acknowledgement,
            ).status_code
            == 204
        )
    second = create(api, author, "第二份公开测试")
    complete_recipe(api, author, second)
    notices = api.client.get("/v1/recipes/publication/notifications", headers=bearer(author)).json()
    assert len(notices["items"]) == 1
    assert notices["license_notice"] is None


def test_cumulative_twenty_percent_stays_general_then_significant_draft_is_hidden(api: Api):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    first = create(api, author)
    complete_recipe(api, author, first)
    latest = first
    for quantity, conclusion in [(330, "minor_only"), (345, "minor_only"), (360, "general")]:
        snapshot = deepcopy(latest["version"]["snapshot"])
        snapshot["ingredients"][0]["quantity"] = quantity
        latest = save(api, author, latest, snapshot)
        result = panel(api, author, latest)
        assert result["state"] == "pending_verification", result
        assert result["baseline_version_id"] == first["version"]["id"]
        assert result["cumulative_conclusion"] == conclusion
        assert result["rules_version"]
    old_record = completed_record_body(api, author, first)
    response = api.client.post("/v1/records", headers=bearer(author), json=old_record)
    assert response.status_code == 201, response.text
    assert panel(api, author, latest)["state"] == "pending_verification"
    snapshot = deepcopy(latest["version"]["snapshot"])
    snapshot["steps"][1]["cookware"] = "空气炸锅"
    hidden = save(api, author, latest, snapshot)
    result = panel(api, author, hidden)
    assert result["state"] == "draft"
    assert result["cumulative_conclusion"] == "significant"
    assert {item["code"] for item in result["missing"]} == {"cook_again"}
    response = api.client.get(f"/v1/recipes/{first['id']}", headers=bearer(reader))
    assert response.status_code == 200, response.text
    assert response.json()["version"]["id"] == latest["version"]["id"]
    exact = f"/v1/recipes/{first['id']}/versions/{hidden['version']['id']}"
    assert api.client.get(exact, headers=bearer(reader)).status_code == 404
    assert api.client.get(exact, headers=bearer(author)).status_code == 200
    history = api.client.get(f"/v1/recipes/{first['id']}/versions", headers=bearer(reader)).json()
    assert [item["version_number"] for item in history["items"]] == [4, 3, 2, 1]
    assert all(item["base_version_id"] is None for item in history["items"])
    comparison = api.client.get(
        f"/v1/recipes/{first['id']}/full-comparison",
        headers=bearer(reader),
        params={
            "from_version_id": first["version"]["id"],
            "to_version_id": hidden["version"]["id"],
        },
    )
    assert comparison.status_code == 404
    complete_recipe(api, author, hidden)
    assert panel(api, author, hidden)["state"] == "published"
    assert api.client.get(exact, headers=bearer(reader)).status_code == 200


@pytest.mark.parametrize("view", ["original", "personalized"])
def test_any_user_exact_pending_completion_clears_once_and_becomes_baseline(api: Api, view: str):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    first = create(api, author)
    complete_recipe(api, author, first)
    snapshot = deepcopy(first["version"]["snapshot"])
    snapshot["ingredients"][0]["quantity"] = 330
    pending = save(api, author, first, snapshot)
    assert pending["version"]["publication_state"] == "pending_verification"
    body = completed_record_body(api, reader, pending, view=view)
    for _ in range(2):
        response = api.client.post("/v1/records", headers=bearer(reader), json=body)
        assert response.status_code == 201, response.text
    assert panel(api, author, pending)["state"] == "published"
    assert event_count(api, reader, "recipe.pending_verification_cleared") == 1
    assert event_count(api, author, "recipe.version_published") == 2
    snapshot = deepcopy(pending["version"]["snapshot"])
    snapshot["ingredients"][0]["quantity"] = 360
    next_version = save(api, author, pending, snapshot)
    assert panel(api, author, next_version)["baseline_version_id"] == pending["version"]["id"]
    public = api.client.get(f"/v1/recipes/{first['id']}", headers=bearer(reader))
    assert "verification_record_id" not in public.text
    assert body["client_id"] not in public.text


@pytest.mark.parametrize("kind", ["external", "dining", "uncompleted", "skipped"])
def test_nonqualifying_records_do_not_publish(api: Api, kind: str):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    recipe = create(api, author)
    body = completed_record_body(api, author, recipe)
    if kind == "skipped":
        skipped = body["completion"]["completed_steps"].pop()
        body["completion"]["skipped_steps"] = [skipped]
    else:
        body.pop("completion")
        if kind in ("external", "dining"):
            body["source"] = "external_cooking" if kind == "external" else kind
    response = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    assert panel(api, author, recipe)["state"] == "draft"
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 404
    assert event_count(api, author, "recipe.version_published") == 0


def test_completion_of_old_version_does_not_verify_significant_new_draft(api: Api):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    first = create(api, author)
    snapshot = deepcopy(first["version"]["snapshot"])
    snapshot["steps"][1]["cookware"] = "空气炸锅"
    second = save(api, author, first, snapshot)
    complete_recipe(api, author, first)
    assert panel(api, author, second)["state"] == "draft"
    assert (
        api.client.get(f"/v1/recipes/{first['id']}", headers=bearer(reader)).json()["version"]["id"]
        == first["version"]["id"]
    )
    assert (
        api.client.post(
            f"/v1/recipes/{first['id']}/personalized",
            headers=bearer(reader),
            json={"version_id": second["version"]["id"]},
        ).status_code
        == 404
    )


def test_reproducibility_cannot_be_waived_by_completion_or_published_baseline(api: Api):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    body = recipe_input()
    response = api.client.post("/v1/recipes", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    incomplete = response.json()
    complete_recipe(api, author, incomplete)
    result = panel(api, author, incomplete)
    assert result["state"] == "draft"
    assert {item["code"] for item in result["missing"]} == {"incomplete"}
    assert result["missing"][0]["remaining_count"] == 1
    snapshot = deepcopy(incomplete["version"]["snapshot"])
    snapshot["steps"][1]["heat"] = "大火，油面波纹"
    reproducible = save(api, author, incomplete, snapshot)
    assert panel(api, author, reproducible)["state"] == "draft"
    complete_recipe(api, author, reproducible)
    snapshot = deepcopy(reproducible["version"]["snapshot"])
    snapshot["steps"][1]["heat"] = "大火"
    another = save(api, author, reproducible, snapshot)
    result = panel(api, author, another)
    assert result["state"] == "draft"
    assert {item["code"] for item in result["missing"]} == {"incomplete"}
    assert (
        api.client.get(
            f"/v1/recipes/{incomplete['id']}/versions/{another['version']['id']}",
            headers=bearer(reader),
        ).status_code
        == 404
    )


def test_risk_and_identity_gates_recheck_without_recooking_and_restore_cannot_bypass(api: Api):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    configure("publication.require_real_name", True)
    body = recipe_input("野生菌测试")
    body["dish_aliases"] = []
    body["snapshot"]["ingredients"][0]["display_name"] = "野生菌"
    body["snapshot"]["steps"][1]["heat"] = "大火，油面波纹"
    response = api.client.post("/v1/recipes", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    recipe = response.json()
    complete_recipe(api, author, recipe)
    result = panel(api, author, recipe)
    assert result["high_risk"] is True
    assert result["review_level"] == "high"
    assert {item["code"] for item in result["missing"]} == {"risk_confirmation", "real_name"}
    endpoint = f"/v1/recipes/{recipe['id']}/versions/{recipe['version']['id']}/risk-confirmation"
    assert api.client.post(endpoint, headers=bearer(reader)).status_code == 404
    response = api.client.post(endpoint, headers=bearer(author))
    assert response.status_code == 200, response.text
    assert panel(api, author, recipe)["state"] == "draft"
    configure("publication.require_real_name", False)
    assert panel(api, author, recipe)["state"] == "published"
    assert event_count(api, author, "recipe.version_published") == 1
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 200
    configure("publication.require_real_name", True)
    assert (
        api.client.post(f"/v1/recipes/{recipe['id']}/withdraw", headers=bearer(author)).status_code
        == 200
    )
    assert (
        api.client.post(f"/v1/recipes/{recipe['id']}/restore", headers=bearer(author)).status_code
        == 200
    )
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 404
    assert event_count(api, author, "recipe.version_published") == 1


@pytest.mark.parametrize("change", ["main_ingredient", "method", "cookware"])
def test_significant_change_requires_author_to_cook_again(api: Api, change: str):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    recipe = create(api, author)
    complete_recipe(api, author, recipe)
    snapshot = deepcopy(recipe["version"]["snapshot"])
    if change == "main_ingredient":
        snapshot["ingredients"][0]["id"] = "tofu"
        snapshot["ingredients"][0]["display_name"] = "豆腐"
        for step in snapshot["steps"]:
            step["ingredient_ids"] = [
                "tofu" if value == "chicken" else value for value in step["ingredient_ids"]
            ]
    elif change == "method":
        snapshot["steps"][1]["action"] = "炖"
        snapshot["steps"][1]["instruction"] = "炖至熟透"
    else:
        snapshot["steps"][1]["cookware"] = "空气炸锅"
    changed = save(api, author, recipe, snapshot)
    result = panel(api, author, changed)
    assert result["state"] == "draft", result
    assert result["cumulative_conclusion"] == "significant"
    assert {item["code"] for item in result["missing"]} == {"cook_again"}
    assert (
        api.client.get(
            f"/v1/recipes/{recipe['id']}/versions/{changed['version']['id']}",
            headers=bearer(reader),
        ).status_code
        == 404
    )
    complete_recipe(api, author, changed)
    assert panel(api, author, changed)["state"] == "published"


def test_withdrawn_recipe_stays_hidden_through_edits_completion_and_idempotent_restore(api: Api):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    recipe = create(api, author)
    image = api.client.post(
        f"/v1/recipes/{recipe['id']}/images", headers=bearer(author), json=_image_payload()
    )
    assert image.status_code == 201, image.text
    # An image upload is itself an immutable new version; cook that exact version.
    recipe = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(author)).json()
    complete_recipe(api, author, recipe)
    public = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).json()
    image_url = public["version"]["images"][0]["url"]
    assert "public=true" in image_url
    assert api.client.get(image_url).status_code == 200
    for action in ("withdraw", "restore"):
        assert (
            api.client.post(
                f"/v1/recipes/{recipe['id']}/{action}", headers=bearer(reader)
            ).status_code
            == 404
        )
    assert (
        api.client.delete(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 404
    )
    for _ in range(2):
        assert (
            api.client.post(
                f"/v1/recipes/{recipe['id']}/withdraw", headers=bearer(author)
            ).status_code
            == 200
        )
    assert event_count(api, author, "recipe.withdrawn") == 1
    for suffix in (
        "",
        "/versions",
        f"/versions/{recipe['version']['id']}",
        "/comparison-candidates",
        "/display?mode=base",
        "/servings?target_servings=3",
    ):
        assert (
            api.client.get(
                f"/v1/recipes/{recipe['id']}{suffix}", headers=bearer(reader)
            ).status_code
            == 404
        )
    assert api.client.get(image_url).status_code == 404
    snapshot = deepcopy(recipe["version"]["snapshot"])
    snapshot["ingredients"][0]["quantity"] = 330
    pending = save(api, author, recipe, snapshot)
    assert pending["withdrawn"] is True
    complete_recipe(api, author, pending)
    assert panel(api, author, pending)["state"] == "withdrawn"
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 404
    deletion = api.client.delete(f"/v1/recipes/{recipe['id']}", headers=bearer(author))
    assert deletion.status_code == 409, deletion.text
    assert deletion.json()["error"]["code"] == "published_recipe_immutable"
    for _ in range(2):
        assert (
            api.client.post(
                f"/v1/recipes/{recipe['id']}/restore", headers=bearer(author)
            ).status_code
            == 200
        )
    assert event_count(api, author, "recipe.restored") == 1
    assert event_count(api, author, "recipe.version_published") == 2
    response = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader))
    assert response.status_code == 200, response.text
    assert response.json()["version"]["id"] == pending["version"]["id"]
    assert response.json()["version"]["publication_state"] == "published"
    assert api.client.get(image_url).status_code == 200


def test_never_public_deletion_and_ever_public_latest_draft_deletion_are_distinct(api: Api):
    author = api.login("publication-author@example.com")
    draft = create(api, author)
    assert (
        api.client.post(f"/v1/recipes/{draft['id']}/withdraw", headers=bearer(author)).status_code
        == 409
    )
    assert (
        api.client.delete(f"/v1/recipes/{draft['id']}", headers=bearer(author)).status_code == 204
    )
    assert api.client.get(f"/v1/recipes/{draft['id']}", headers=bearer(author)).status_code == 404
    public = create(api, author)
    complete_recipe(api, author, public)
    snapshot = deepcopy(public["version"]["snapshot"])
    snapshot["steps"][1]["cookware"] = "空气炸锅"
    latest = save(api, author, public, snapshot)
    assert latest["version"]["publication_state"] == "draft"
    assert latest["ever_public"] is True
    assert (
        api.client.delete(f"/v1/recipes/{public['id']}", headers=bearer(author)).status_code == 409
    )


def test_public_feature_off_blocks_all_read_boundaries_and_signed_images(api: Api):
    author = api.login("publication-author@example.com")
    reader = api.login("publication-reader@example.com")
    recipe = create(api, author)
    image = api.client.post(
        f"/v1/recipes/{recipe['id']}/images", headers=bearer(author), json=_image_payload()
    )
    assert image.status_code == 201, image.text
    # An image upload is itself an immutable new version; cook that exact version.
    recipe = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(author)).json()
    complete_recipe(api, author, recipe)
    public = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).json()
    image_url = public["version"]["images"][0]["url"]
    configure("feature.public_recipes", False)
    for suffix in (
        "",
        "/versions",
        f"/versions/{recipe['version']['id']}",
        "/comparison-candidates",
        "/display?mode=base",
        "/servings?target_servings=3",
    ):
        assert (
            api.client.get(
                f"/v1/recipes/{recipe['id']}{suffix}", headers=bearer(reader)
            ).status_code
            == 404
        )
    assert api.client.get(image_url).status_code == 404
    assert (
        api.client.post(
            f"/v1/recipes/{recipe['id']}/personalized", headers=bearer(reader), json={}
        ).status_code
        == 404
    )
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(author)).status_code == 200
    assert panel(api, author, recipe)["state"] == "published"
    configure("feature.public_recipes", True)
    assert api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader)).status_code == 200
    assert api.client.get(image_url).status_code == 200


def test_client_cannot_supply_publication_ancestry_or_server_only_events(api: Api):
    author = api.login("publication-author@example.com")
    recipe = create(api, author)
    for field, value in [
        ("source_version_id", new_uuid()),
        ("publication_state", "published"),
        ("verification_record_id", new_uuid()),
    ]:
        response = api.client.post(
            f"/v1/recipes/{recipe['id']}/versions",
            headers=bearer(author),
            json={"snapshot": recipe["version"]["snapshot"], field: value},
        )
        assert response.status_code == 422, response.text
    for event_type in (
        "recipe.version_published",
        "recipe.pending_verification_cleared",
        "recipe.withdrawn",
        "recipe.restored",
    ):
        response = api.client.post(
            "/v1/events/upload",
            headers=bearer(author),
            json={
                "events": [
                    {
                        "id": new_uuid(),
                        "event_type": event_type,
                        "type_version": 1,
                        "device_id": "test",
                        "device_time": "2026-10-15T01:00:00Z",
                        "app_version": "test",
                        "content": {"recipe_id": recipe["id"]},
                    }
                ]
            },
        )
        assert response.status_code == 200, response.text
        assert response.json()["results"][0]["reason"]["code"] == "server_only_event"
    assert panel(api, author, recipe)["state"] == "draft"


def test_latest_actual_recook_not_publication_or_offline_upload_selects_baseline(api: Api):
    from datetime import datetime, timedelta

    author = api.login("recook-author@example.com")
    reader = api.login("recook-reader@example.com")
    first = create(api, author)
    complete_recipe(api, author, first)
    snapshot = deepcopy(first["version"]["snapshot"])
    snapshot["steps"][1]["cookware"] = "空气炸锅"
    second = save(api, author, first, snapshot)
    second_record = complete_recipe(api, author, second)
    delayed_old = completed_record_body(api, author, second)
    old_time = datetime.fromisoformat(
        second_record["occurred_at"].replace("Z", "+00:00")
    ) - timedelta(hours=1)
    delayed_old["occurred_at"] = delayed_old["completion"]["finished_at"] = old_time.isoformat()
    delayed_old["completion"]["started_at"] = (old_time - timedelta(minutes=10)).isoformat()
    recook = complete_recipe(api, reader, first)
    assert recook["id"] != second_record["id"]
    third = save(api, author, second, snapshot)
    result = panel(api, author, third)
    assert result["baseline_version_id"] == first["version"]["id"]
    assert result["cumulative_conclusion"] == "significant"
    assert result["state"] == "draft"
    assert {item["code"] for item in result["missing"]} == {"cook_again"}
    late = api.client.post("/v1/records", headers=bearer(author), json=delayed_old)
    assert late.status_code == 201, late.text
    assert panel(api, author, third) == result
    assert event_count(api, author, "recipe.version_published") == 2
    assert event_count(api, reader, "recipe.pending_verification_cleared") == 0
    exact = f"/v1/recipes/{first['id']}/versions/{third['version']['id']}"
    assert api.client.get(exact, headers=bearer(reader)).status_code == 404
    assert (
        api.client.get(
            f"/v1/recipes/{first['id']}/versions/{first['version']['id']}", headers=bearer(reader)
        ).json()["version"]["snapshot"]
        == first["version"]["snapshot"]
    )


def test_notifications_cursor_reaches_all_unseen_and_ack_batches_preserve_license(api: Api):
    author = api.login("notice-pages@example.com")
    other = api.login("notice-other@example.com")
    recipe = create(api, author)
    complete_recipe(api, author, recipe)
    for _ in range(101):
        recipe = save(api, author, recipe, recipe["version"]["snapshot"])
    endpoint = "/v1/recipes/publication/notifications"
    first = api.client.get(endpoint, headers=bearer(author), params={"limit": 100})
    assert first.status_code == 200, first.text
    page = first.json()
    assert len(page["items"]) == 100
    assert page["next_cursor"]
    ids = [item["id"] for item in page["items"]]
    second = api.client.get(
        endpoint, headers=bearer(author), params={"limit": 100, "cursor": page["next_cursor"]}
    ).json()
    assert len(second["items"]) == 2
    assert second["next_cursor"] is None
    assert not set(ids).intersection(item["id"] for item in second["items"])
    assert second["license_notice"] == page["license_notice"]
    assert (
        api.client.get(
            endpoint, headers=bearer(other), params={"cursor": page["next_cursor"]}
        ).json()["items"]
        == []
    )
    assert (
        api.client.post(
            endpoint + "/acknowledge",
            headers=bearer(author),
            json={"notification_ids": [*ids, second["items"][0]["id"]]},
        ).status_code
        == 422
    )
    assert (
        api.client.post(
            endpoint + "/acknowledge", headers=bearer(other), json={"notification_ids": ids}
        ).status_code
        == 204
    )
    assert api.client.get(endpoint, headers=bearer(author), params={"limit": 100}).json() == page
    assert (
        api.client.post(
            endpoint + "/acknowledge", headers=bearer(author), json={"notification_ids": ids}
        ).status_code
        == 204
    )
    remaining = api.client.get(endpoint, headers=bearer(author)).json()
    assert remaining["items"] == second["items"]
    assert remaining["license_notice"] == page["license_notice"]
    assert (
        api.client.post(
            endpoint + "/acknowledge",
            headers=bearer(author),
            json={
                "notification_ids": [item["id"] for item in remaining["items"]],
                "license_seen": True,
            },
        ).status_code
        == 204
    )
    assert api.client.get(endpoint, headers=bearer(author)).json() == {
        "items": [],
        "next_cursor": None,
        "license_notice": None,
    }
    for params in ({"limit": 0}, {"limit": 101}, {"cursor": "invalid"}):
        assert api.client.get(endpoint, headers=bearer(author), params=params).status_code == 422
