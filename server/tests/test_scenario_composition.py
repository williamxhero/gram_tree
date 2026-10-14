"""SPEC-009.2 scenarios, observed only through authenticated HTTP interfaces."""

from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_allergies import sensitive_api as sensitive_api
from tests.test_personalization_adaptations import personalization_api as personalization_api
from tests.test_personalization_adaptations import (
    personalization_recordings as personalization_recordings,
)
from tests.test_recipes import recipe_input

COMPONENTS = [
    "food_safety",
    "allergen_notice",
    "scenario_summary",
    "scenario_difference",
    "failure_reminder",
    "taste_change_notice",
]


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


def test_frequent_difference_uses_frozen_execution_and_feedback_is_dish_scoped(api: Api) -> None:
    headers = bearer(api.login("scene-difference@example.com"))
    recipe = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    record(api, headers, recipe)
    record(api, headers, recipe)
    last = record(api, headers, recipe)
    first = compose(api, headers, recipe)
    card = next(c for c in first["components"] if c["type"] == "scenario_difference")
    assert card["data"]["record_id"] == last["id"]
    assert card["data"]["differences"] == []
    assert first["components"][2]["data"]["steps_collapsed"] is True
    changed = recipe_input()
    changed["snapshot"]["ingredients"][0]["quantity"] = 250
    version = api.client.post(f"/v1/recipes/{recipe['id']}/versions", headers=headers, json=changed)
    assert version.status_code == 201, version.text
    result = compose(api, headers, recipe)
    card = next(c for c in result["components"] if c["type"] == "scenario_difference")
    assert card["data"]["differences"] == [
        {
            "kind": "quantity",
            "ingredient_id": "chicken",
            "label": "鸡腿肉",
            "before": "300 g",
            "after": "250 g",
        }
    ]
    assert (
        api.client.get(f"/v1/records/{last['id']}", headers=headers).json()["snapshot"]
        == last["snapshot"]
    )
    skipped = compose(api, headers, recipe, skipped_components=[card["id"]])
    assert not any(c["type"] == "scenario_difference" for c in skipped["components"])
    assert skipped["components"][2]["data"]["steps_collapsed"] is False
    feedback = api.client.post(
        "/v1/ui/scenario-feedback",
        headers=headers,
        json={"component_id": card["id"], "source_type": "scenario_adjusted"},
    )
    assert feedback.status_code == 200, feedback.text
    assert not any(
        c["type"] == "scenario_difference" for c in compose(api, headers, recipe)["components"]
    )
    assert compose(api, headers, recipe)["components"][2]["data"]["steps_collapsed"] is False
    same_dish = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    same = compose(api, headers, same_dish)
    assert same["scenario_signals"]["dish_history"]["count"] == 3
    assert not any(c["type"] == "scenario_difference" for c in same["components"])
    other_input = recipe_input("另一道菜")
    other_input["dish_aliases"] = []
    other_dish = api.client.post("/v1/recipes", headers=headers, json=other_input).json()
    assert compose(api, headers, other_dish)["scenario_signals"]["dish_history"]["count"] == 0


def test_failure_mapping_uses_latest_feedback_and_refuses_ambiguous_steps(api: Api) -> None:
    headers = bearer(api.login("scene-failure@example.com"))
    recipe = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    last = record(api, headers, recipe)
    path = f"/v1/records/{last['id']}/revisions"
    feedback = api.client.post(
        path,
        headers=headers,
        json={
            "revision_id": new_uuid(),
            "field": "feedback",
            "value": {"taste_tags": ["肉太干"]},
        },
    )
    assert feedback.status_code == 201, feedback.text
    result = compose(api, headers, recipe)
    cards = [c for c in result["components"] if c["type"] == "failure_reminder"]
    assert {(c["data"]["step_id"], c["data"]["placement"]) for c in cards} == {
        ("cook", "before"),
        ("cook", "at"),
    }
    assert all(c["data"]["rule_id"] == "dry_meat" for c in cards)
    assert result["scenario_signals"]["failure"]["source"] == [last["id"]]
    other = bearer(api.login("scene-failure-other@example.com"))
    assert (
        api.client.post(
            "/v1/ui/scenario-feedback",
            headers=other,
            json={
                "component_id": cards[0]["id"],
                "source_type": "scenario_adjusted",
            },
        ).status_code
        == 404
    )
    assert (
        api.client.post(
            "/v1/ui/scenario-feedback",
            headers=headers,
            json={
                "component_id": "recipe:food-safety",
                "source_type": "scenario_adjusted",
            },
        ).status_code
        == 404
    )
    assert (
        api.client.post(
            path,
            headers=headers,
            json={
                "revision_id": new_uuid(),
                "field": "feedback",
                "value": {"deleted": True},
            },
        ).status_code
        == 201
    )
    assert not any(
        c["type"] == "failure_reminder" for c in compose(api, headers, recipe)["components"]
    )
    assert (
        api.client.post(
            path,
            headers=headers,
            json={
                "revision_id": new_uuid(),
                "field": "feedback",
                "value": {"taste_tags": ["肉太干"]},
            },
        ).status_code
        == 201
    )
    ambiguous = recipe_input()
    ambiguous["snapshot"]["steps"][0]["action"] = "煮"
    assert (
        api.client.post(
            f"/v1/recipes/{recipe['id']}/versions", headers=headers, json=ambiguous
        ).status_code
        == 201
    )
    assert not any(
        c["type"] == "failure_reminder" for c in compose(api, headers, recipe)["components"]
    )


def test_before_taste_change_recalculates_actual_prior_profile_and_preserves_current(
    api: Api,
) -> None:
    from copy import deepcopy

    headers = bearer(api.login("scene-taste@example.com"))
    body = recipe_input()
    body["snapshot"]["ingredients"].append(
        {
            "id": "salt",
            "display_name": "盐",
            "quantity": 10,
            "unit": "g",
            "group": "调味",
            "flavor_contribution": {"salty": 3},
        }
    )
    body["snapshot"]["steps"][1]["ingredient_ids"].append("salt")
    recipe = api.client.post("/v1/recipes", headers=headers, json=body).json()
    profile_path = "/v1/me/taste-profile"
    assert (
        api.client.patch(
            profile_path, headers=headers, json={"flavors": {"salty": 0.75}}
        ).status_code
        == 200
    )
    endpoint = f"/v1/recipes/{recipe['id']}/personalized"
    old = api.client.post(endpoint, headers=headers, json={}).json()
    assert old["snapshot"]["ingredients"][-1]["quantity"] == 7.5
    frozen = deepcopy(recipe)
    frozen["version"]["snapshot"] = old["snapshot"]
    for _ in range(3):
        record(
            api,
            headers,
            recipe,
            snapshot={
                "format_version": 1,
                "detail": frozen,
                "inputs": {"personalized_view": "personalized"},
            },
        )
    saved = api.client.patch(profile_path, headers=headers, json={"flavors": {"salty": 1.25}})
    assert saved.status_code == 200, saved.text
    changes = api.client.get(profile_path + "/changes", headers=headers).json()["items"]
    change = next(c for c in changes if c["version"] == saved.json()["version"])
    current = compose(api, headers, recipe)
    card = next(c for c in current["components"] if c["type"] == "taste_change_notice")
    assert card["data"]["change_id"] == change["id"]
    difference = next(c for c in current["components"] if c["type"] == "scenario_difference")
    assert difference["data"]["differences"] == [
        {
            "kind": "quantity",
            "ingredient_id": "salt",
            "label": "盐",
            "before": "7.5 g",
            "after": "12.5 g",
        }
    ]
    before = api.client.post(endpoint + f"/before-change/{change['id']}", headers=headers, json={})
    assert before.status_code == 200, before.text
    assert before.json()["snapshot"]["ingredients"][-1]["quantity"] == 7.5
    assert before.json()["profile_version"] == old["profile_version"]
    assert before.json()["cache_key"] != old["cache_key"]
    assert api.client.get(profile_path, headers=headers).json() == saved.json()
    prior_page = compose(api, headers, recipe, before_change_id=change["id"])
    assert not any(c["type"] == "taste_change_notice" for c in prior_page["components"])
    assert (
        next(c for c in prior_page["components"] if c["type"] == "scenario_difference")["data"][
            "differences"
        ]
        == []
    )
    original = compose(api, headers, recipe, personalization_view="original")
    assert not any(c["type"] == "taste_change_notice" for c in original["components"])
    assert (
        next(c for c in original["components"] if c["type"] == "scenario_difference")["data"][
            "differences"
        ][0]["after"]
        == "10 g"
    )
    other = bearer(api.login("scene-taste-other@example.com"))
    assert (
        api.client.post(
            endpoint + f"/before-change/{change['id']}", headers=other, json={}
        ).status_code
        == 404
    )
    assert (
        api.client.post(
            "/v1/ui/compositions",
            headers=other,
            json={
                "page_type": "recipe_detail",
                "protocol_version": "1.0",
                "recipe_id": recipe["id"],
                "before_change_id": change["id"],
            },
        ).status_code
        == 404
    )
    # A later unrelated change must also be rewound, not left on the current profile.
    assert (
        api.client.patch(
            profile_path, headers=headers, json={"flavors": {"sweet": 1.25}}
        ).status_code
        == 200
    )
    earlier = api.client.post(endpoint + f"/before-change/{change['id']}", headers=headers, json={})
    assert earlier.status_code == 200, earlier.text
    assert earlier.json()["effective_flavors"]["sweet"] == 1.0
    assert earlier.json()["effective_flavors"]["salty"] == 0.75
    no_effect = api.client.get(profile_path + "/changes", headers=headers).json()["items"][0]
    assert no_effect["id"] not in [
        c["data"]["change_id"]
        for c in compose(api, headers, recipe)["components"]
        if c["type"] == "taste_change_notice"
    ]
    assert (
        api.client.post(
            "/v1/ui/scenario-feedback",
            headers=headers,
            json={
                "component_id": card["id"],
                "source_type": "scenario_adjusted",
            },
        ).status_code
        == 200
    )
    assert not any(
        c["type"] == "taste_change_notice" for c in compose(api, headers, recipe)["components"]
    )
    assert (
        api.client.post(
            profile_path + f"/changes/{change['id']}/revert", headers=headers
        ).status_code
        == 200
    )
    assert (
        api.client.post(
            endpoint + f"/before-change/{change['id']}", headers=headers, json={}
        ).status_code
        == 409
    )


def test_prior_view_restores_earlier_change_that_was_reverted_after_target(api: Api) -> None:
    headers = bearer(api.login("scene-history-revert@example.com"))
    recipe = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    profile_path = "/v1/me/taste-profile"
    assert (
        api.client.patch(
            profile_path, headers=headers, json={"flavors": {"sweet": 0.75}}
        ).status_code
        == 200
    )
    sweet_change = api.client.get(profile_path + "/changes", headers=headers).json()["items"][0]
    assert (
        api.client.patch(
            profile_path, headers=headers, json={"flavors": {"salty": 1.25}}
        ).status_code
        == 200
    )
    target = api.client.get(profile_path + "/changes", headers=headers).json()["items"][0]
    assert (
        api.client.post(
            profile_path + f"/changes/{sweet_change['id']}/revert", headers=headers
        ).status_code
        == 200
    )
    current = api.client.get(profile_path, headers=headers).json()
    assert current["flavors"]["sweet"]["coefficient"] == 1.0
    before = api.client.post(
        f"/v1/recipes/{recipe['id']}/personalized/before-change/{target['id']}",
        headers=headers,
        json={},
    )
    assert before.status_code == 200, before.text
    assert before.json()["effective_flavors"]["sweet"] == 0.75
    assert before.json()["effective_flavors"]["salty"] == 1.0
    assert api.client.get(profile_path, headers=headers).json() == current


def test_prior_view_keeps_current_allergy_authorization_and_projected_safety(
    personalization_api: Api,
    personalization_recordings: Path,
) -> None:
    from tests.test_allergies import PATH, consent, save
    from tests.test_personalization_adaptations import CORPUS, ingredient, record_replacement

    api = personalization_api
    headers = bearer(api.login("scene-allergy-history@example.com"))
    body = recipe_input()
    body["snapshot"]["ingredients"].append(
        ingredient("花生", "peanut", flavor_contribution={"salty": 3})
    )
    recipe = api.client.post("/v1/recipes", headers=headers, json=body).json()
    record_replacement(personalization_recordings, recipe, "花生", CORPUS["no_replacement"])
    assert (
        api.client.patch(
            "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 1.25}}
        ).status_code
        == 200
    )
    target = api.client.get("/v1/me/taste-profile/changes", headers=headers).json()["items"][0]
    consent(api, headers)
    state = api.client.get(PATH, headers=headers).json()
    updated = save(api, headers, state, ["花生"])
    assert updated.status_code == 200, updated.text
    endpoint = f"/v1/recipes/{recipe['id']}/personalized/before-change/{target['id']}"
    before = api.client.post(endpoint, headers=headers, json={})
    assert before.status_code == 200, before.text
    assert before.json()["effective_flavors"]["salty"] == 1.0
    assert before.json()["safety"]["status"] == "available"
    assert any(alert["target"] == "花生" for alert in before.json()["safety"]["alerts"])
    prior = compose(api, headers, recipe, before_change_id=target["id"])
    allergen = next(c for c in prior["components"] if c["type"] == "allergen_notice")
    assert allergen["required"] is True
    assert allergen["data"]["personal_safety"] == before.json()["safety"]
    assert api.client.get(PATH, headers=headers).json() == updated.json()


@pytest.mark.parametrize(
    ("step_id", "text", "expected"),
    [
        ("cook", "肉柴", True),
        ("cook", "  肉柴  ", True),
        ("marinate", "肉柴", False),
        ("missing", "肉柴", False),
        ("cook", "少放一点盐", False),
        ("cook", "肉没有炒柴", False),
    ],
)
def test_app_adjustment_labels_require_exact_negative_text_and_matching_step(
    api: Api,
    step_id: str,
    text: str,
    expected: bool,
) -> None:
    headers = bearer(api.login("scene-adjustment-text@example.com"))
    recipe = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    last = record(
        api,
        headers,
        recipe,
        adjustments=[{"step_id": step_id, "text": text, "created_at": "2026-10-14T00:00:00Z"}],
    )
    cards = [
        c for c in compose(api, headers, recipe)["components"] if c["type"] == "failure_reminder"
    ]
    if expected:
        assert {c["data"]["placement"] for c in cards} == {"before", "at"}
        assert all(c["data"]["step_id"] == "cook" for c in cards)
        assert all(c["data"]["record_id"] == last["id"] for c in cards)
    else:
        assert cards == []


@pytest.mark.parametrize(
    "adjustment",
    [
        {"flavor": "salty", "delta": -1},
        {
            "step_id": "cook:main",
            "text": "偏咸",
            "created_at": "2026-10-14T00:00:00Z",
        },
    ],
    ids=["structured-reduction", "app-recorded-text"],
)
def test_failure_first_step_live_adjustments_and_latest_success(
    api: Api,
    adjustment: dict,
) -> None:
    headers = bearer(api.login("scene-first-step@example.com"))
    body = recipe_input()
    body["snapshot"]["steps"] = [body["snapshot"]["steps"][1]]
    body["snapshot"]["steps"][0]["depends_on"] = []
    body["snapshot"]["steps"][0]["id"] = "cook:main"
    body["snapshot"]["ingredients"].append(
        {
            "id": "salt",
            "display_name": "盐",
            "quantity": 10,
            "unit": "g",
            "group": "调味",
            "flavor_contribution": {"salty": 3},
        }
    )
    body["snapshot"]["steps"][0]["ingredient_ids"].append("salt")
    recipe = api.client.post("/v1/recipes", headers=headers, json=body).json()
    last = record(
        api,
        headers,
        recipe,
        adjustments=[adjustment],
        source_context={"completed_steps": ["cook:main"]},
    )
    path = f"/v1/records/{last['id']}/revisions"
    assert (
        api.client.post(
            path,
            headers=headers,
            json={
                "revision_id": new_uuid(),
                "field": "feedback",
                "value": {"taste_tags": ["肉柴"]},
            },
        ).status_code
        == 201
    )
    result = compose(api, headers, recipe)
    cards = [c for c in result["components"] if c["type"] == "failure_reminder"]
    assert {(c["data"]["rule_id"], c["data"]["placement"]) for c in cards} == {
        ("dry_meat", "before"),
        ("dry_meat", "at"),
        ("too_salty", "before"),
        ("too_salty", "at"),
    }
    assert all(c["data"]["step_id"] == "cook:main" for c in cards)
    assert (
        api.client.post(
            path,
            headers=headers,
            json={
                "revision_id": new_uuid(),
                "field": "adjustments",
                "value": {"adjustments": []},
            },
        ).status_code
        == 201
    )
    assert not any(
        c["type"] == "failure_reminder" and c["data"]["rule_id"] == "too_salty"
        for c in compose(api, headers, recipe)["components"]
    )
    dry = next(c for c in cards if c["data"]["rule_id"] == "dry_meat")
    assert (
        api.client.post(
            "/v1/ui/scenario-feedback",
            headers=headers,
            json={
                "component_id": dry["id"],
                "source_type": "scenario_adjusted",
            },
        ).status_code
        == 200
    )
    assert not any(
        c["type"] == "failure_reminder" for c in compose(api, headers, recipe)["components"]
    )
    # A different owner of the same dish has independent feedback and history.
    other = bearer(api.login("scene-first-step-other@example.com"))
    other_recipe = api.client.post("/v1/recipes", headers=other, json=body).json()
    other_record = record(
        api, other, other_recipe, source_context={"completed_steps": ["cook:main"]}
    )
    assert (
        api.client.post(
            f"/v1/records/{other_record['id']}/revisions",
            headers=other,
            json={
                "revision_id": new_uuid(),
                "field": "feedback",
                "value": {"taste_tags": ["肉柴"]},
            },
        ).status_code
        == 201
    )
    assert any(
        c["type"] == "failure_reminder" for c in compose(api, other, other_recipe)["components"]
    )
    record(api, other, other_recipe, source_context={"completed_steps": ["cook:main"]})
    assert not any(
        c["type"] == "failure_reminder" for c in compose(api, other, other_recipe)["components"]
    )


def test_recipe_experiment_is_stable_and_explicit_preferences_win(api: Api) -> None:
    import json

    from gramtree.cli import main as cli

    assert (
        cli(
            [
                "config",
                "set",
                "ui.experiment.recipe_composition",
                json.dumps(
                    {
                        "enabled": True,
                        "groups": [{"name": "all", "ratio": 1.0, "variant": "more_detail"}],
                    }
                ),
                "--by",
                "test",
                "--reason",
                "scenario HTTP regression",
            ]
        )
        == 0
    )
    assert (
        cli(
            [
                "config",
                "set",
                "ui.scenario.experienced_count",
                "1",
                "--by",
                "test",
                "--reason",
                "scenario HTTP regression",
            ]
        )
        == 0
    )
    headers = bearer(api.login("scene-experiment@example.com"))
    recipe = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    record(api, headers, recipe)
    first = compose(api, headers, recipe)
    second = compose(api, headers, recipe)
    assert (
        first["experiment"]
        == second["experiment"]
        == {
            "experiment": "recipe_composition_detail",
            "variant": "more_detail",
        }
    )
    assert first["components"][2]["detail"] == "detailed"
    assert first["scenario_signals"]["detail"]["source"] == "experiment"
    assert (
        compose(api, headers, recipe, detail_override="brief")["components"][2]["reason"]["code"]
        == "page_switch"
    )
    assert (
        api.client.put("/v1/ui/preferences", headers=headers, json={"detail": "brief"}).status_code
        == 200
    )
    fixed = compose(api, headers, recipe)
    assert fixed["components"][2]["detail"] == "brief"
    assert fixed["components"][2]["reason"]["code"] == "user_setting"
    assert {c["type"] for c in fixed["components"] if c["required"]} == {
        "food_safety",
        "allergen_notice",
    }


def test_missing_execution_does_not_claim_no_difference_or_collapse(api: Api) -> None:
    headers = bearer(api.login("scene-missing@example.com"))
    recipe = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    for _ in range(3):
        record(api, headers, recipe, snapshot={"format_version": 1})
    result = compose(api, headers, recipe)
    assert result["scenario_signals"]["dish_history"]["value"] == "frequent"
    assert result["components"][2]["data"]["steps_collapsed"] is False
    assert not any(c["type"] == "scenario_difference" for c in result["components"])


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
