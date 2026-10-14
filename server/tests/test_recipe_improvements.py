"""Exact-source branches and record derivation through HTTP/CLI on PostgreSQL."""

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer, new_uuid
from tests.cooking_completion_support import complete_recipe
from tests.test_ai_recipes import recording
from tests.test_recipe_modifications import INTENT, TEXT, operation
from tests.test_recipes import recipe_input


def public_source(api: Api):
    author = api.login("improvement-author@example.com")
    reader = api.login("improvement-reader@example.com")
    body = recipe_input("改良来源")
    body["snapshot"]["ingredients"][1].update(
        {
            "display_name": "盐",
            "quantity": 10,
            "unit": "g",
            "scaling_mode": "proportional",
            "flavor_contribution": {"salty": 3},
            "replacement": None,
        }
    )
    body["snapshot"]["steps"][1]["heat"] = "大火，油面波纹"
    response = api.client.post("/v1/recipes", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    detail = response.json()
    complete_recipe(api, author, detail)
    response = api.client.get(f"/v1/recipes/{detail['id']}", headers=bearer(reader))
    assert response.status_code == 200, panel(api, author, detail)
    return author, reader, response.json()


def improvement_body(detail: dict, *, quantity=7, **values):
    snapshot = deepcopy(detail["version"]["snapshot"])
    snapshot["ingredients"][1]["quantity"] = quantity
    return {
        "request_id": new_uuid(),
        "source_version_id": detail["version"]["id"],
        "snapshot": snapshot,
        **values,
    }


def post_save(api: Api, tokens: dict, detail: dict, body: dict):
    return api.client.post(
        f"/v1/recipes/{detail['id']}/improvements", headers=bearer(tokens), json=body
    )


def panel(api, tokens, detail):
    response = api.client.get(f"/v1/recipes/{detail['id']}/publication", headers=bearer(tokens))
    assert response.status_code == 200, response.text
    return response.json()


def event_count(api, tokens, event_type):
    response = api.client.get(
        "/v1/dev/events/count", headers=bearer(tokens), params={"event_type": event_type}
    )
    assert response.status_code == 200, response.text
    return response.json()["count"]


def test_historical_source_draft_is_exact_and_no_creation_until_save(api: Api):
    author, reader, source = public_source(api)
    newer = deepcopy(source["version"]["snapshot"])
    newer["ingredients"][1]["quantity"] = 9
    result = api.client.post(
        f"/v1/recipes/{source['id']}/versions", headers=bearer(author), json={"snapshot": newer}
    )
    assert result.status_code == 201, result.text
    draft = api.client.post(
        f"/v1/recipes/{source['id']}/improvement-drafts",
        headers=bearer(reader),
        json={"source_version_id": source["version"]["id"]},
    )
    assert draft.status_code == 201, draft.text
    assert draft.json()["snapshot"] == source["version"]["snapshot"]
    assert api.client.get("/v1/recipes", headers=bearer(reader)).json()["items"] == []
    assert event_count(api, reader, "recipe.improvement_created") == 0
    fetched = api.client.get(f"/v1/improvement-drafts/{draft.json()['id']}", headers=bearer(reader))
    assert fetched.json() == draft.json()
    assert (
        api.client.get(
            f"/v1/improvement-drafts/{draft.json()['id']}", headers=bearer(author)
        ).status_code
        == 404
    )
    saved = post_save(api, reader, source, improvement_body(source))
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    assert branch["source_version_id"] == source["version"]["id"]
    assert branch["version"]["snapshot"]["ingredients"][1]["quantity"] == 7
    assert branch["version"]["snapshot"]["ingredients"][1]["id"] == "pepper"
    assert branch["source_attribution"]["branch_type"] == "normal"
    assert branch["source_attribution"]["conclusion"] == "general"
    assert panel(api, reader, branch)["state"] == "draft"
    assert api.client.get(f"/v1/recipes/{branch['id']}", headers=bearer(author)).status_code == 404


@pytest.mark.parametrize("legacy", [False, True])
@pytest.mark.parametrize("protocol", ["1.0", "99.0"])
def test_attribution_uses_only_supported_cards_in_normal_and_fallback_composition(
    api: Api, legacy, protocol
):
    _, reader, source = public_source(api)
    saved = post_save(api, reader, source, improvement_body(source))
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    supported = ["food_safety", "allergen_notice", "scenario_summary"]
    if not legacy:
        supported.append("source_attribution")
    body = {
        "page_type": "recipe_detail",
        "protocol_version": protocol,
        "supported_components": supported,
        "recipe_id": branch["id"],
        "detail_override": "brief",
    }
    response = api.client.post("/v1/ui/compositions", headers=bearer(reader), json=body)
    assert response.status_code == 200, response.text
    components = response.json()["components"]
    assert all(item["type"] in supported for item in components)
    assert any(
        branch["source_attribution"]["label"] in item["data"].get("conclusion", "")
        and item["required"]
        and item["type"] in {"source_attribution", "scenario_summary", "hint_bar", "empty_state"}
        for item in components
    )
    assert all(item["type"] != "source_attribution" for item in components) == legacy
    other = api.login("composition-private@example.com")
    assert (
        api.client.post("/v1/ui/compositions", headers=bearer(other), json=body).status_code == 404
    )


@pytest.mark.parametrize("carrier_type", ["hint_bar", "empty_state"])
@pytest.mark.parametrize("protocol", ["1.0", "99.0"])
@pytest.mark.parametrize("modern_source", [False, True])
def test_legacy_text_attribution_carrier_data_has_no_source_specific_fields(
    api: Api, carrier_type, protocol, modern_source
):
    _, reader, source = public_source(api)
    saved = post_save(api, reader, source, improvement_body(source))
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    response = api.client.post(
        "/v1/ui/compositions",
        headers=bearer(reader),
        json={
            "page_type": "recipe_detail",
            "protocol_version": protocol,
            "supported_components": [carrier_type, "source_attribution"]
            if modern_source
            else [carrier_type],
            "recipe_id": branch["id"],
        },
    )
    assert response.status_code == 200, response.text
    assert response.json()["fallback"] == {"reason_code": "missing_required"}
    components = response.json()["components"]
    assert len(components) == (2 if modern_source else 1)
    assert {item["type"] for item in components} == (
        {carrier_type, "source_attribution"} if modern_source else {carrier_type}
    )
    carrier = next(item for item in components if item["type"] == carrier_type)
    prefix = "" if modern_source else f"{branch['source_attribution']['label']} · "
    assert carrier["data"] == {
        "conclusion": f"{prefix}暂时无法确认食品安全信息。 · 暂时无法确认过敏原信息。"
    }
    if modern_source:
        source_card = next(item for item in components if item["type"] == "source_attribution")
        assert source_card["data"]["attribution"]["label"] == branch["source_attribution"]["label"]
    assert carrier["required"] is True
    assert carrier["actions"] == []
    unsupported = api.client.post(
        "/v1/ui/compositions",
        headers=bearer(reader),
        json={
            "page_type": "recipe_detail",
            "protocol_version": protocol,
            "supported_components": [],
            "recipe_id": branch["id"],
        },
    )
    assert unsupported.status_code == 422, unsupported.text
    assert unsupported.json()["error"]["code"] == "unsupported_source_attribution"
    safety_only = api.client.post(
        "/v1/ui/compositions",
        headers=bearer(reader),
        json={
            "page_type": "recipe_detail",
            "protocol_version": protocol,
            "supported_components": ["food_safety", "allergen_notice"],
            "recipe_id": branch["id"],
        },
    )
    assert safety_only.status_code == 422, safety_only.text
    assert safety_only.json()["error"]["code"] == "unsupported_source_attribution"
    if modern_source:
        source_only = api.client.post(
            "/v1/ui/compositions",
            headers=bearer(reader),
            json={
                "page_type": "recipe_detail",
                "protocol_version": protocol,
                "supported_components": ["source_attribution"],
                "recipe_id": branch["id"],
            },
        )
        assert source_only.status_code == 422, source_only.text
        assert source_only.json()["error"]["code"] == "unsupported_required_facts"


def test_retry_conflict_and_one_creation_event(api: Api):
    _, reader, source = public_source(api)
    body = improvement_body(source)
    first = post_save(api, reader, source, body)
    assert first.status_code == 201, first.text
    repeat = post_save(api, reader, source, body)
    assert repeat.status_code == 201, repeat.text
    assert repeat.json() == first.json()
    assert len(api.client.get("/v1/recipes", headers=bearer(reader)).json()["items"]) == 1
    assert event_count(api, reader, "recipe.improvement_created") == 1
    body["change_note"] = "不同请求"
    assert post_save(api, reader, source, body).status_code == 409


def test_concurrent_improvement_retry_creates_one_branch(api: Api):
    _, reader, source = public_source(api)
    body = improvement_body(source)
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda _: post_save(api, reader, source, body), range(2)))
    assert all(response.status_code == 201 for response in responses), [
        response.text for response in responses
    ]
    assert responses[0].json() == responses[1].json()
    assert len(api.client.get("/v1/recipes", headers=bearer(reader)).json()["items"]) == 1
    assert event_count(api, reader, "recipe.improvement_created") == 1


def test_self_hidden_feature_disabled_and_forged_chain_rejected(api: Api):
    author, reader, source = public_source(api)
    assert post_save(api, author, source, improvement_body(source)).status_code == 422
    no_change = post_save(api, reader, source, improvement_body(source, quantity=10))
    assert no_change.status_code == 422, no_change.text
    assert no_change.json()["error"]["code"] == "no_improvement_changes"
    forged = improvement_body(source, root_recipe_id=new_uuid(), source_path=[])
    assert post_save(api, reader, source, forged).status_code == 422
    # A private latest version is not a copyable source, even when the recipe has public history.
    snapshot = deepcopy(source["version"]["snapshot"])
    snapshot["steps"][1]["cookware"] = "烤箱"
    latest = api.client.post(
        f"/v1/recipes/{source['id']}/versions", headers=bearer(author), json={"snapshot": snapshot}
    )
    assert latest.status_code == 201, latest.text
    assert post_save(api, reader, latest.json(), improvement_body(latest.json())).status_code == 404
    from tests.test_ai_recipes import configure

    configure("feature.public_recipes", False)
    assert post_save(api, reader, source, improvement_body(source)).status_code == 404


def test_microadjust_prompt_cancel_taste_confirmation_and_retry(api: Api):
    _, reader, source = public_source(api)
    profile = api.client.get("/v1/me/taste-profile", headers=bearer(reader))
    assert profile.status_code == 200, profile.text
    before = profile.json()
    body = improvement_body(source, quantity=9)
    preview = api.client.post(
        f"/v1/recipes/{source['id']}/improvements/preview",
        headers=bearer(reader),
        json={key: value for key, value in body.items() if key != "request_id"},
    )
    assert preview.status_code == 200, preview.text
    result = preview.json()
    assert result["microadjust_prompt"] == "这个改动更像个人口味"
    assert result["comparison"]["conclusion"] == "minor_only"
    assert result["taste_proposal"]["convertible"] is True
    assert result["taste_proposal"]["coefficients"]["salty"] == pytest.approx(0.9)
    assert api.client.get("/v1/me/taste-profile", headers=bearer(reader)).json() == before
    assert post_save(api, reader, source, body).status_code == 409
    body.update(
        microadjust_choice="taste",
        expected_profile_version=result["taste_proposal"]["profile_version"],
    )
    saved = post_save(api, reader, source, body)
    assert saved.status_code == 201, saved.text
    repeat = post_save(api, reader, source, body)
    assert repeat.json() == saved.json()
    assert saved.json()["outcome"] == "taste"
    profile = api.client.get("/v1/me/taste-profile", headers=bearer(reader)).json()
    assert profile["flavors"]["salty"]["coefficient"] == pytest.approx(0.9)
    assert profile["version"] == before["version"] + 1
    assert api.client.get("/v1/recipes", headers=bearer(reader)).json()["items"] == []
    assert event_count(api, reader, "recipe.improvement_created") == 0
    assert event_count(api, reader, "recipe.improvement_saved_to_taste") == 1
    storage = api.client.get("/v1/dev/events/taste-profile-storage", headers=bearer(reader))
    assert storage.status_code == 200, storage.text
    assert storage.json() == {
        "profiles": 1,
        "changes": 1,
        "events": 2,
        "taste_events": 1,
        "metadata_only": True,
    }


def test_microadjust_branch_nonconvertible_and_general_boundary(api: Api):
    _, reader, source = public_source(api)
    body = improvement_body(source, quantity=9, microadjust_choice="branch")
    saved = post_save(api, reader, source, body)
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    assert branch["source_attribution"]["branch_type"] == "microadjust"
    assert panel(api, reader, branch)["state"] == "draft"
    # Pure wording is minor in the shared engine, but cannot become a taste coefficient.
    body = improvement_body(
        source, quantity=10, microadjust_choice="taste", expected_profile_version=1
    )
    body["snapshot"]["description"] = "更清楚的说明"
    response = post_save(api, reader, source, body)
    assert response.status_code == 422, response.text
    assert response.json()["error"]["code"] == "taste_conversion_unavailable"
    boundary = post_save(
        api,
        reader,
        source,
        improvement_body(
            source, quantity=8, microadjust_choice="taste", expected_profile_version=1
        ),
    )
    assert boundary.status_code == 422, boundary.text
    assert boundary.json()["error"]["code"] == "not_microadjustment"


def test_source_chain_survives_edits_and_source_withdrawal(api: Api):
    author, reader, source = public_source(api)
    draft = api.client.post(
        f"/v1/recipes/{source['id']}/improvement-drafts",
        headers=bearer(reader),
        json={"source_version_id": source["version"]["id"]},
    )
    assert draft.status_code == 201, draft.text
    saved = post_save(api, reader, source, improvement_body(source))
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    complete_recipe(api, reader, branch)
    third = api.login("third-improver@example.com")
    nested = post_save(api, third, branch, improvement_body(branch, quantity=5))
    assert nested.status_code == 201, nested.text
    leaf = nested.json()["recipe"]
    chain = leaf["source_attribution"]["chain"]
    assert [node["recipe_id"] for node in chain] == [source["id"], branch["id"]]
    assert leaf["root_recipe_id"] == source["id"]
    snapshot = deepcopy(leaf["version"]["snapshot"])
    snapshot["description"] = "自己的后续版本"
    result = api.client.post(
        f"/v1/recipes/{leaf['id']}/versions", headers=bearer(third), json={"snapshot": snapshot}
    )
    assert result.status_code == 201, result.text
    assert result.json()["source_attribution"]["chain"] == chain
    forged = api.client.post(
        f"/v1/recipes/{leaf['id']}/versions",
        headers=bearer(third),
        json={"snapshot": snapshot, "source_version_id": new_uuid()},
    )
    assert forged.status_code == 422
    withdrawn = api.client.post(
        f"/v1/recipes/{source['id']}/withdraw", headers=bearer(author), json={}
    )
    assert withdrawn.status_code == 200, withdrawn.text
    fetched = api.client.get(f"/v1/recipes/{leaf['id']}", headers=bearer(third))
    assert fetched.status_code == 200, fetched.text
    assert fetched.json()["source_attribution"]["chain"][0]["withdrawn"] is True
    assert "snapshot" not in fetched.json()["source_attribution"]["chain"][0]
    # A new source read/copy stays forbidden; the previously owned copy survives.
    assert api.client.get(f"/v1/recipes/{source['id']}", headers=bearer(reader)).status_code == 404
    assert (
        api.client.post(
            f"/v1/recipes/{source['id']}/improvement-drafts",
            headers=bearer(reader),
            json={"source_version_id": source["version"]["id"]},
        ).status_code
        == 404
    )
    owned = api.client.get(f"/v1/improvement-drafts/{draft.json()['id']}", headers=bearer(reader))
    assert owned.status_code == 200, owned.text
    assert owned.json() == draft.json()
    assert (
        api.client.get(
            f"/v1/improvement-drafts/{draft.json()['id']}", headers=bearer(third)
        ).status_code
        == 404
    )
    assert post_save(api, third, source, improvement_body(source)).status_code == 404
    preview = api.client.post(
        f"/v1/recipes/{source['id']}/improvements/preview",
        headers=bearer(reader),
        json={key: value for key, value in improvement_body(source).items() if key != "request_id"},
    )
    assert preview.status_code == 200, preview.text
    assert preview.json()["snapshot"]["ingredients"][1]["quantity"] == 7
    resumed = post_save(api, reader, source, improvement_body(source))
    assert resumed.status_code == 201, resumed.text
    assert resumed.json()["recipe"]["source_version_id"] == source["version"]["id"]
    assert resumed.json()["recipe"]["source_attribution"]["chain"][-1]["withdrawn"] is True


@pytest.mark.parametrize("withdraw", [False, True])
def test_record_derived_significant_branch_is_exact_published_and_idempotent(api: Api, withdraw):
    author, reader, source = public_source(api)
    record = complete_recipe(
        api, reader, source, adjustments=[{"step_id": "cook", "fields": {"cookware": "烤箱"}}]
    )
    if withdraw:
        assert (
            api.client.post(
                f"/v1/recipes/{source['id']}/withdraw", headers=bearer(author)
            ).status_code
            == 200
        )
        assert (
            api.client.get(f"/v1/recipes/{source['id']}", headers=bearer(reader)).status_code == 404
        )
        assert post_save(api, reader, source, improvement_body(source)).status_code == 404
        record_body = {
            "source_version_id": source["version"]["id"],
            "from_cooking_record_id": record["id"],
        }
        stranger = api.login("withdraw-record-stranger@example.com")
        assert (
            post_save(api, stranger, source, {**record_body, "request_id": new_uuid()}).status_code
            == 404
        )
        preview = api.client.post(
            f"/v1/recipes/{source['id']}/improvements/preview",
            headers=bearer(reader),
            json=record_body,
        )
        assert preview.status_code == 200, preview.text
        assert preview.json()["snapshot"] == record["source_context"]["executed_snapshot"]
    body = {
        "source_version_id": source["version"]["id"],
        "from_cooking_record_id": record["id"],
        "request_id": new_uuid(),
    }
    saved = post_save(api, reader, source, body)
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    assert branch["source_attribution"]["conclusion"] == "significant"
    assert branch["version"]["snapshot"]["steps"][1]["cookware"] == "烤箱"
    assert panel(api, reader, branch)["state"] == "published"
    assert post_save(api, reader, source, body).json() == saved.json()
    assert api.client.get(f"/v1/recipes/{branch['id']}", headers=bearer(author)).status_code == 200
    assert event_count(api, reader, "recipe.improvement_created") == 1
    assert event_count(api, reader, "recipe.version_published") == 1
    # The source record keeps its own recipe/version rather than being rewritten.
    original_record = api.client.get(f"/v1/records/{record['id']}", headers=bearer(reader)).json()
    assert original_record["recipe_version_id"] == source["version"]["id"]
    snapshot = deepcopy(branch["version"]["snapshot"])
    snapshot["description"] = "保留从精确实做记录继承的基准"
    edited = api.client.post(
        f"/v1/recipes/{branch['id']}/versions", headers=bearer(reader), json={"snapshot": snapshot}
    )
    assert edited.status_code == 201, edited.text
    latest = panel(api, reader, edited.json())
    assert latest["baseline_version_id"] == branch["version"]["id"]
    assert latest["cumulative_conclusion"] != "significant"
    assert latest["state"] == "pending_verification"
    assert (
        api.client.get(f"/v1/records/{record['id']}", headers=bearer(reader)).json()
        == original_record
    )


def test_derivation_rejects_other_user_wrong_version_wrong_recipe_and_changed_result(api: Api):
    author, reader, source = public_source(api)
    record = complete_recipe(
        api, reader, source, adjustments=[{"ingredient_id": "pepper", "quantity": 7, "unit": "g"}]
    )
    stranger = api.login("wrong-proof@example.com")
    body = {
        "source_version_id": source["version"]["id"],
        "from_cooking_record_id": record["id"],
        "request_id": new_uuid(),
    }
    assert post_save(api, stranger, source, body).status_code == 404
    fake = improvement_body(source, from_cooking_record_id=record["id"], quantity=6)
    assert post_save(api, reader, source, fake).status_code == 422
    different = api.client.post(
        "/v1/recipes",
        headers=bearer(author),
        json={"dish_name": "另一个来源", "snapshot": source["version"]["snapshot"]},
    )
    assert different.status_code == 201, different.text
    other_source = different.json()
    complete_recipe(api, author, other_source)
    wrong_recipe = {**body, "source_version_id": other_source["version"]["id"]}
    assert post_save(api, reader, other_source, wrong_recipe).status_code == 422
    latest_snapshot = deepcopy(source["version"]["snapshot"])
    latest_snapshot["ingredients"][1]["quantity"] = 9
    newer = api.client.post(
        f"/v1/recipes/{source['id']}/versions",
        headers=bearer(author),
        json={"snapshot": latest_snapshot},
    )
    assert newer.status_code == 201, newer.text
    body.update(request_id=new_uuid(), source_version_id=newer.json()["version"]["id"])
    assert post_save(api, reader, source, body).status_code == 422


def test_unstructured_adjustment_cannot_certify_arbitrary_recipe_and_record_microadjust_choices(
    api: Api,
):
    _, reader, source = public_source(api)
    unstructured = complete_recipe(api, reader, source, adjustments=[{"text": "少放盐"}])
    body = {
        "source_version_id": source["version"]["id"],
        "from_cooking_record_id": unstructured["id"],
        "request_id": new_uuid(),
    }
    assert post_save(api, reader, source, body).status_code == 422
    arbitrary = improvement_body(source, from_cooking_record_id=unstructured["id"])
    assert post_save(api, reader, source, arbitrary).status_code == 422
    record = complete_recipe(
        api, reader, source, adjustments=[{"ingredient_id": "pepper", "quantity": 9, "unit": "g"}]
    )
    body.update(from_cooking_record_id=record["id"], request_id=new_uuid())
    assert post_save(api, reader, source, body).status_code == 409
    body["microadjust_choice"] = "branch"
    saved = post_save(api, reader, source, body)
    assert saved.status_code == 201, saved.text
    assert panel(api, reader, saved.json()["recipe"])["state"] == "published"
    body.update(request_id=new_uuid(), microadjust_choice="taste", expected_profile_version=1)
    saved_taste = post_save(api, reader, source, body)
    assert saved_taste.status_code == 201, saved_taste.text
    assert saved_taste.json()["outcome"] == "taste"


def test_own_record_linear_version_reuses_actual_proof_only_once(api: Api):
    author, reader, source = public_source(api)
    record = complete_recipe(
        api, author, source, adjustments=[{"step_id": "cook", "fields": {"cookware": "烤箱"}}]
    )
    url = f"/v1/records/{record['id']}/save-version"
    body = {"request_id": new_uuid()}
    assert api.client.post(url, headers=bearer(reader), json=body).status_code == 404
    result = api.client.post(url, headers=bearer(author), json=body)
    assert result.status_code == 201, result.text
    recipe = result.json()["recipe"]
    assert recipe["id"] == source["id"]
    assert recipe["version"]["version_number"] == 2
    assert recipe["source_version_id"] is None
    assert panel(api, author, recipe)["state"] == "published"
    assert api.client.post(url, headers=bearer(author), json=body).json() == result.json()
    assert event_count(api, author, "recipe.record_version_saved") == 1


def test_concurrent_own_record_retry_creates_one_linear_version(api: Api):
    author, _, source = public_source(api)
    record = complete_recipe(
        api, author, source, adjustments=[{"step_id": "cook", "fields": {"cookware": "烤箱"}}]
    )
    url = f"/v1/records/{record['id']}/save-version"
    body = {"request_id": new_uuid()}
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(
            pool.map(lambda _: api.client.post(url, headers=bearer(author), json=body), range(2))
        )
    assert all(response.status_code == 201 for response in responses), [
        response.text for response in responses
    ]
    assert responses[0].json() == responses[1].json()
    detail = api.client.get(f"/v1/recipes/{source['id']}", headers=bearer(author)).json()
    assert detail["version"]["version_number"] == 2
    assert event_count(api, author, "recipe.record_version_saved") == 1
    assert event_count(api, author, "recipe.version_published") == 2


def test_curated_cli_is_audited_and_user_cannot_write_it(api: Api):
    _, reader, source = public_source(api)
    response = post_save(api, reader, source, improvement_body(source))
    assert response.status_code == 201, response.text
    branch = response.json()["recipe"]
    server = Path(__file__).resolve().parents[1]

    def run(action):
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "gramtree.recipes.improvement_cli",
                action,
                branch["id"],
                *([] if action == "show" else ["--by", "acceptance", "--reason", "精选测试"]),
            ],
            cwd=server,
            env={**os.environ, "PYTHONPATH": str(server)},
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        assert result.returncode == 0, result.stdout + result.stderr
        return json.loads(result.stdout)

    initial = run("show")
    assert initial["curated"] is False
    comparison = initial["creation_comparison"]
    assert comparison["from_version"]["version_id"] == source["version"]["id"]
    assert comparison["to_version"]["version_id"] == branch["version"]["id"]
    assert comparison["to_version"]["recipe_id"] == branch["id"]
    assert run("set")["curated"] is True
    assert run("show")["cooked_user_threshold"] == 5
    assert run("show")["publication_state"] == "draft"
    assert run("unset")["curated"] is False
    assert event_count(api, reader, "recipe.improvement_curated") == 2
    assert (
        api.client.post(
            f"/v1/recipes/{branch['id']}/curated", headers=bearer(reader), json={"curated": True}
        ).status_code
        == 404
    )
    removed = api.client.delete(f"/v1/recipes/{branch['id']}", headers=bearer(reader))
    assert removed.status_code == 204, removed.text
    assert event_count(api, reader, "recipe.improvement_created") == 1
    assert event_count(api, reader, "recipe.improvement_curated") == 2


@pytest.fixture
def improvement_ai_api(monkeypatch, tmp_path, request):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    # Settings are constructed when the HTTP fixture starts, after replay is selected.
    return request.getfixturevalue("api"), tmp_path


@pytest.mark.parametrize("withdraw", [False, True])
def test_ai_working_copy_reuses_preview_and_requires_confirmed_decisions(
    improvement_ai_api, withdraw
):
    api, directory = improvement_ai_api
    author, reader, source = public_source(api)
    snapshot = source["version"]["snapshot"]
    recording(directory, "modify_intent", {"text": TEXT}, INTENT)
    recording(
        directory,
        "modify",
        {"text": TEXT, "snapshot": snapshot, "intent": INTENT},
        {"operations": [operation(snapshot)]},
    )
    draft = api.client.post(
        f"/v1/recipes/{source['id']}/improvement-drafts",
        headers=bearer(reader),
        json={"source_version_id": source["version"]["id"]},
    )
    assert draft.status_code == 201, draft.text
    if withdraw:
        assert (
            api.client.post(
                f"/v1/recipes/{source['id']}/withdraw", headers=bearer(author)
            ).status_code
            == 200
        )
        assert (
            api.client.get(f"/v1/recipes/{source['id']}", headers=bearer(reader)).status_code == 404
        )
        assert (
            api.client.post(
                "/v1/ai/recipes/modifications",
                headers=bearer(author),
                json={"text": TEXT, "improvement_draft_id": draft.json()["id"]},
            ).status_code
            == 404
        )
    proposal = api.client.post(
        "/v1/ai/recipes/modifications",
        headers=bearer(reader),
        json={"text": TEXT, "improvement_draft_id": draft.json()["id"]},
    )
    assert proposal.status_code == 200, proposal.text
    preview = proposal.json()
    assert preview["error"] is None, preview
    body = {
        "request_id": new_uuid(),
        "source_version_id": source["version"]["id"],
        "modification_request_id": preview["id"],
        "modification_revision": preview["revision"],
        "microadjust_choice": "branch",
    }
    assert post_save(api, reader, source, body).status_code == 409
    decide = api.client.post(
        f"/v1/ai/recipes/modifications/{preview['id']}/decisions",
        headers=bearer(reader),
        json={"decisions": [{"operation_id": "wording-1", "decision": "accept"}]},
    )
    assert decide.status_code == 200, decide.text
    body["modification_revision"] = decide.json()["revision"]
    result = post_save(api, reader, source, body)
    assert result.status_code == 201, result.text
    assert result.json()["recipe"]["version"]["ai_assisted"] is True
    assert (
        result.json()["recipe"]["version"]["snapshot"]["steps"][0]["instruction"]
        == operation(snapshot)["after"]
    )
    assert post_save(api, reader, source, body).json() == result.json()
    body["request_id"] = new_uuid()
    assert post_save(api, reader, source, body).status_code == 409


@pytest.mark.parametrize(
    "event_type",
    [
        "recipe.improvement_created",
        "recipe.improvement_saved_to_taste",
        "recipe.record_version_saved",
        "recipe.improvement_curated",
    ],
)
def test_improvement_facts_cannot_be_forged_by_event_upload(api: Api, event_type):
    from tests.test_events import _event

    tokens = api.login("forged-improvement@example.com")
    response = api.client.post(
        "/v1/events/upload",
        headers=bearer(tokens),
        json={"events": [_event(event_type=event_type, content={})]},
    )
    assert response.status_code == 200, response.text
    result = response.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "server_only_event"
    assert event_count(api, tokens, event_type) == 0


def test_personalized_execution_is_the_exact_derived_branch(api: Api):
    _, reader, source = public_source(api)
    profile = api.client.patch(
        "/v1/me/taste-profile", headers=bearer(reader), json={"flavors": {"salty": 0.8}}
    )
    assert profile.status_code == 200, profile.text
    record = complete_recipe(api, reader, source, view="personalized")
    body = {
        "source_version_id": source["version"]["id"],
        "from_cooking_record_id": record["id"],
        "request_id": new_uuid(),
    }
    saved = post_save(api, reader, source, body)
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    assert branch["version"]["snapshot"]["ingredients"][1]["quantity"] == pytest.approx(8)
    assert panel(api, reader, branch)["state"] == "published"


def test_record_proof_does_not_bypass_other_publication_gates(api: Api):
    author, reader, source = public_source(api)
    record = complete_recipe(
        api, reader, source, adjustments=[{"step_id": "cook", "fields": {"heat": "大火"}}]
    )
    saved = post_save(
        api,
        reader,
        source,
        {
            "source_version_id": source["version"]["id"],
            "from_cooking_record_id": record["id"],
            "request_id": new_uuid(),
        },
    )
    assert saved.status_code == 201, saved.text
    branch = saved.json()["recipe"]
    gate = panel(api, reader, branch)
    assert gate["state"] == "draft"
    assert any(condition["code"] == "incomplete" for condition in gate["missing"])
    assert all(condition["code"] != "not_cooked" for condition in gate["missing"])
    assert api.client.get(f"/v1/recipes/{branch['id']}", headers=bearer(author)).status_code == 404
