"""SPEC-009.2 scenarios, observed only through authenticated HTTP interfaces."""

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_recipes import recipe_input

COMPONENTS = ["food_safety", "allergen_notice", "scenario_summary"]


def compose(api: Api, headers: dict, recipe: dict, **options: object) -> dict:
    response = api.client.post(
        "/v1/ui/compositions",
        headers=headers,
        json={
            "page_type": "recipe_detail",
            "protocol_version": "1.0",
            "supported_components": COMPONENTS,
            "recipe_id": recipe["id"],
            **options,
        },
    )
    assert response.status_code == 200, response.text
    assert response.json().get("fallback") is None, response.text
    return response.json()


def test_first_cook_is_detailed_and_page_override_does_not_change_default(api: Api) -> None:
    headers = bearer(api.login("scene-first@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    recipe = response.json()
    first = compose(api, headers, recipe)
    summary = next(c for c in first["components"] if c["type"] == "scenario_summary")
    assert summary["detail"] == "detailed"
    assert summary["reason"]["code"] == "novice"
    assert summary["data"]["steps_collapsed"] is False
    assert first["scenario_signals"]["experience"]["value"] == "novice"
    assert first["scenario_signals"]["dish_history"]["value"] == "first_time"
    switched = compose(api, headers, recipe, detail_override="brief")
    summary = next(c for c in switched["components"] if c["type"] == "scenario_summary")
    assert summary["detail"] == "brief"
    assert summary["reason"]["code"] == "page_switch"
    assert compose(api, headers, recipe)["components"][2]["detail"] == "detailed"
    settings = api.client.put("/v1/ui/preferences", headers=headers, json={"detail": "brief"})
    assert settings.status_code == 200, settings.text
    fixed = compose(api, headers, recipe)
    summary = next(c for c in fixed["components"] if c["type"] == "scenario_summary")
    assert summary["detail"] == "brief"
    assert summary["reason"]["code"] == "user_setting"
    assert {c["type"] for c in fixed["components"] if c["required"]} == {
        "food_safety",
        "allergen_notice",
    }
    other = bearer(api.login("scene-other@example.com"))
    assert api.client.get("/v1/ui/preferences", headers=other).json()["detail"] == "auto"
    assert (
        api.client.post(
            "/v1/ui/compositions",
            headers=other,
            json={
                "page_type": "recipe_detail",
                "protocol_version": "1.0",
                "recipe_id": recipe["id"],
            },
        ).status_code
        == 404
    )


def record(api: Api, headers: dict, recipe: dict, **options: object) -> dict:
    response = api.client.post(
        "/v1/records",
        headers=headers,
        json={
            "client_id": new_uuid(),
            "dish_name": recipe["dish"]["name"],
            "source": "cooking_session",
            "verification": "unverified",
            "recipe_id": recipe["id"],
            "recipe_version_id": recipe["version"]["id"],
            "snapshot": {"format_version": 1, "detail": recipe},
            "source_context": {"completed_steps": ["marinate", "cook"], "skipped_steps": []},
            **options,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_completion_threshold_and_dish_frequency_update_without_cached_stale_result(
    api: Api,
) -> None:
    headers = bearer(api.login("scene-completion@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    recipe = response.json()
    for _ in range(9):
        record(api, headers, recipe)
    before = compose(api, headers, recipe)
    assert before["scenario_signals"]["experience"]["count"] == 9
    assert before["components"][2]["detail"] == "detailed"
    assert before["scenario_signals"]["dish_history"]["value"] == "frequent"
    record(api, headers, recipe, source_context={"completed_steps": ["marinate"]})
    record(api, headers, recipe, source="dining")
    record(api, headers, recipe, snapshot={"format_version": 1})
    record(
        api,
        headers,
        recipe,
        snapshot={"detail": {"version": {"snapshot": {"steps": [{"id": []}]}}}},
    )
    assert compose(api, headers, recipe)["scenario_signals"]["experience"]["count"] == 9
    final = record(api, headers, recipe)
    after = compose(api, headers, recipe)
    assert after["scenario_signals"]["experience"]["count"] == 10
    assert after["components"][2]["detail"] == "brief"
    assert after["components"][2]["reason"]["code"] == "experienced"
    assert final["id"] in after["scenario_signals"]["experience"]["source"]
    assert after["composition_id"] != before["composition_id"]
    assert after["cache"]["ttl_s"] == 0
    assert (
        api.client.put(
            "/v1/ui/preferences", headers=headers, json={"detail": "detailed"}
        ).status_code
        == 200
    )
    assert compose(api, headers, recipe)["components"][2]["reason"]["code"] == "user_setting"
    assert (
        compose(api, headers, recipe, detail_override="auto")["components"][2]["detail"]
        == "detailed"
    )


def test_viewport_boundary_and_legacy_capabilities_preserve_required_safety(api: Api) -> None:
    headers = bearer(api.login("scene-viewport@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    recipe = response.json()
    phone = compose(api, headers, recipe, screen_width=599)
    tablet = compose(api, headers, recipe, screen_width=600)
    assert phone["scenario_signals"]["device"]["value"] == "phone"
    assert tablet["scenario_signals"]["device"]["value"] == "tablet"
    assert tablet["components"][2]["data"]["layout"] == "tablet"
    calendar = tablet["scenario_signals"]["calendar"]
    assert calendar["source"]["timezone"] == "Asia/Shanghai"
    assert calendar["rule_entry"] in {"weekday_quick", "weekend_leisure"}
    assert calendar["period"] in {"morning", "afternoon", "evening"}
    legacy = compose(api, headers, recipe, supported_components=["food_safety", "allergen_notice"])
    assert {item["type"] for item in legacy["components"]} == {"food_safety", "allergen_notice"}
    assert all(item["required"] for item in legacy["components"])
    assert legacy["composition_id"] != tablet["composition_id"]
    invalid = api.client.post(
        "/v1/ui/compositions",
        headers=headers,
        json={
            "page_type": "recipe_detail",
            "protocol_version": "1.0",
            "recipe_id": recipe["id"],
            "screen_width": 0,
        },
    )
    assert invalid.status_code == 422
    assert (
        api.client.put("/v1/ui/preferences", headers=headers, json={"detail": "hidden"}).status_code
        == 422
    )
    assert api.client.put("/v1/ui/preferences", json={"detail": "brief"}).status_code == 401


def test_today_cache_isolated_by_client_component_capability(api: Api) -> None:
    headers = bearer(api.login("scene-capability@example.com"))
    body = {
        "page_type": "today",
        "protocol_version": "1.0",
        "supported_components": ["hint_bar", "empty_state", "source_demo"],
    }
    first = api.client.post("/v1/ui/compositions", headers=headers, json=body)
    assert first.status_code == 200, first.text
    cached = api.client.post("/v1/ui/compositions", headers=headers, json=body)
    assert cached.json()["composition_id"] == first.json()["composition_id"]
    limited = api.client.post(
        "/v1/ui/compositions", headers=headers, json={**body, "supported_components": ["hint_bar"]}
    )
    assert limited.status_code == 200, limited.text
    assert limited.json()["composition_id"] != first.json()["composition_id"]
    assert {item["type"] for item in limited.json()["components"]} <= {"hint_bar"}
