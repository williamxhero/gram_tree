"""Recipe safety UI protocol behavior through the public composition API."""

from typing import Any

import pytest
from httpx import Response

from gramtree.recipes import service as recipe_service
from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape

SAFETY_COMPONENTS = ["food_safety", "allergen_notice"]


def _recipe_body(
    name: str, ingredient: str = "鸡肉", instruction: str = "炒至熟透"
) -> dict[str, Any]:
    return {
        "dish_name": name,
        "snapshot": {
            "servings": 1,
            "ingredients": [
                {"id": "main", "display_name": ingredient, "quantity": 100, "unit": "g"}
            ],
            "steps": [
                {
                    "id": "cook",
                    "instruction": instruction,
                    "ingredient_ids": ["main"],
                    "duration_seconds": 120,
                }
            ],
        },
    }


def _create_recipe(
    api: Api,
    tokens: dict[str, Any],
    name: str,
    ingredient: str = "鸡肉",
    instruction: str = "炒至熟透",
) -> dict[str, Any]:
    response = api.client.post(
        "/v1/recipes",
        json=_recipe_body(name, ingredient, instruction),
        headers=bearer(tokens),
    )
    assert response.status_code == 201, response.text
    return response.json()


def _compose(
    api: Api,
    tokens: dict[str, Any],
    recipe_id: str,
    **overrides: Any,
) -> Response:
    body = {
        "page_type": "recipe_detail",
        "protocol_version": "1.0",
        "supported_components": SAFETY_COMPONENTS,
        "recipe_id": recipe_id,
    }
    body.update(overrides)
    return api.client.post("/v1/ui/compositions", json=body, headers=bearer(tokens))


def test_recipe_composition_uses_saved_safety_and_allergen_context(api: Api) -> None:
    tokens = api.login("safety-protocol@example.com")
    saved = _create_recipe(api, tokens, "安全协议测试菜", instruction="炒 2 分钟")

    response = _compose(api, tokens, saved["id"])

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["fallback"] is None
    assert body["cache"]["ttl_s"] == 0
    assert {item["type"] for item in body["components"]} == set(SAFETY_COMPONENTS)
    safety = next(item for item in body["components"] if item["type"] == "food_safety")
    allergens = next(item for item in body["components"] if item["type"] == "allergen_notice")
    assert safety["required"] is True
    assert safety["data"]["status"] == "available"
    assert safety["data"]["result"]["rules_version"]
    poultry_finding = next(
        item
        for item in safety["data"]["result"]["findings"]
        if item["rule_id"] == "poultry-cook-through"
    )
    assert poultry_finding["threshold_celsius"] == 74
    assert poultry_finding["ingredient_ids"] == ["main"]
    assert allergens["required"] is True
    assert allergens["data"]["status"] == "available"
    assert allergens["data"]["result"]["rules_version"]


def test_recipe_composition_preserves_pork_rest_guidance(api: Api) -> None:
    tokens = api.login("pork-guidance@example.com")
    saved = _create_recipe(api, tokens, "猪肉安全提示菜", ingredient="猪肉", instruction="快炒")

    response = _compose(api, tokens, saved["id"])

    assert response.status_code == 200, response.text
    safety = next(item for item in response.json()["components"] if item["type"] == "food_safety")
    finding = next(
        item
        for item in safety["data"]["result"]["findings"]
        if item["rule_id"] == "pork-cook-through"
    )
    assert finding["threshold_celsius"] == 63
    assert finding["rest_minutes"] == 3


def test_recipe_composition_missing_supported_safety_component_falls_back_with_cards(
    api: Api,
) -> None:
    tokens = api.login("missing-safety-component@example.com")
    saved = _create_recipe(api, tokens, "必显安全组件测试菜")

    response = _compose(api, tokens, saved["id"], supported_components=["food_safety"])

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["fallback"] == {"reason_code": "missing_required"}
    assert {item["type"] for item in body["components"]} == set(SAFETY_COMPONENTS)
    assert all(item["required"] is True for item in body["components"])
    assert all(item["data"]["status"] == "unknown" for item in body["components"])


def test_recipe_composition_rejects_another_owners_private_recipe(api: Api) -> None:
    owner_tokens = api.login("recipe-owner@example.com")
    saved = _create_recipe(api, owner_tokens, "私有菜谱")
    other_tokens = api.login("other-recipe-owner@example.com")

    response = _compose(api, other_tokens, saved["id"])

    error = assert_error_shape(response, 404, "not_found")
    assert error["message"]


def test_recipe_composition_context_failure_keeps_unknown_safety_cards(
    api: Api, monkeypatch: pytest.MonkeyPatch
) -> None:
    tokens = api.login("safety-context-error@example.com")
    saved = _create_recipe(api, tokens, "上下文错误测试菜")

    def fail_context(*args: object, **kwargs: object) -> None:
        raise RuntimeError("context unavailable")

    monkeypatch.setattr(recipe_service, "recipe_safety_context", fail_context)
    response = _compose(api, tokens, saved["id"])

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["fallback"] == {"reason_code": "server_error"}
    assert {item["type"] for item in body["components"]} == set(SAFETY_COMPONENTS)
    assert all(item["required"] is True for item in body["components"])
    assert all(item["data"]["status"] == "unknown" for item in body["components"])
    assert all(item["data"]["result"] is None for item in body["components"])
