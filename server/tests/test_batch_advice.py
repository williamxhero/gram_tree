"""Large-batch advice through HTTP and synthetic gateway replay, without ORM assertions."""

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import cli
from tests.test_recipes import recipe_input


def create(api: Api) -> tuple[dict, dict]:
    headers = bearer(api.login("batch-author@example.com"))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    return response.json(), headers


def path(saved: dict) -> str:
    return f"/v1/recipes/{saved['id']}/versions/{saved['version']['id']}/batch-advice"


def request(api: Api, saved: dict, headers: dict, target: int = 4) -> dict:
    response = api.client.post(path(saved), headers=headers, json={"target_servings": target})
    assert response.status_code == 200, response.text
    return response.json()


def test_disabled_advice_preserves_conversion_and_version(api: Api) -> None:
    saved, headers = create(api)
    before = api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json()
    low = request(api, saved, headers, 3)
    assert low["eligible"] is False
    assert low["error"] == "below_batch_threshold"
    result = request(api, saved, headers)
    assert result["eligible"] is True
    assert result["original_servings"] == 2
    assert result["target_servings"] == 4
    assert result["recipe_id"] == saved["id"]
    assert result["version_id"] == saved["version"]["id"]
    assert result["advice"] is None
    assert result["error"] == "model_unavailable"
    assert result["status"] == {
        "available": False, "remaining": 50, "reason": "model_unavailable"
    }
    conversion = api.client.get(
        f"/v1/recipes/{saved['id']}/servings?target_servings=4", headers=headers
    ).json()["conversion"]
    assert [s["duration_seconds"] for s in conversion["steps"]] == [900, 120]
    assert conversion["steps"][1]["batch_warning"] is True
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved
    assert api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=headers).json() == before
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    assert cli("ai", "audit", "--user", user_id)["calls"] == []
