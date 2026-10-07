"""One-line creation acceptance tests use HTTP and operator CLI, never ORM assertions."""

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input


def test_disabled_gateway_does_not_disable_recipe_apis(api: Api) -> None:
    headers = bearer(api.login("ai-status@example.com"))
    response = api.client.get("/v1/ai/recipes/status", headers=headers)
    assert response.status_code == 200
    assert response.json() == {"available": False, "remaining": 50, "reason": "model_unavailable"}
    saved = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert saved.status_code == 201, saved.text
    recipe_id = saved.json()["id"]
    assert api.client.get(f"/v1/recipes/{recipe_id}", headers=headers).status_code == 200
    assert (
        api.client.get(
            f"/v1/recipes/{recipe_id}/servings?target_servings=4", headers=headers
        ).status_code
        == 200
    )


def test_ai_status_requires_auth(api: Api) -> None:
    assert api.client.get("/v1/ai/recipes/status").status_code == 401
