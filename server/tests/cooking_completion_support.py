"""Build execution evidence solely from the authenticated public view API."""

from copy import deepcopy
from datetime import UTC, datetime, timedelta

from tests.accounts_support import Api, bearer, new_uuid


def completed_record_body(
    api: Api,
    tokens: dict,
    detail: dict,
    *,
    adjustments: list[dict] | None = None,
    view: str = "original",
) -> dict:
    response = api.client.post(
        f"/v1/recipes/{detail['id']}/personalized",
        headers=bearer(tokens),
        params={"view": view},
        json={"version_id": detail["version"]["id"]},
    )
    assert response.status_code == 200, response.text
    projection = response.json()
    assert projection["execution_token"]
    executed = deepcopy(detail)
    executed["version"]["snapshot"] = projection["snapshot"]
    now = datetime.now(UTC) - timedelta(seconds=1)
    client_id = new_uuid()
    steps = [step["id"] for step in projection["snapshot"]["steps"]]
    return {
        "client_id": client_id,
        "recipe_id": detail["id"],
        "recipe_version_id": detail["version"]["id"],
        "dish_name": detail["dish"]["name"],
        "source": "cooking_session",
        "verification": "unverified",
        "occurred_at": now.isoformat(),
        "snapshot": {
            "format_version": 1,
            "recipe_id": detail["id"],
            "version_id": detail["version"]["id"],
            "detail": executed,
        },
        "adjustments": adjustments or [],
        "completion": {
            "session_id": client_id,
            "execution_token": projection["execution_token"],
            "status": "completed",
            "started_at": (now - timedelta(minutes=10)).isoformat(),
            "finished_at": now.isoformat(),
            "reached_steps": steps,
            "completed_steps": steps,
            "skipped_steps": [],
        },
    }


def complete_recipe(api: Api, tokens: dict, detail: dict, **kwargs) -> dict:
    body = completed_record_body(api, tokens, detail, **kwargs)
    response = api.client.post("/v1/records", headers=bearer(tokens), json=body)
    assert response.status_code == 201, response.text
    assert response.json()["verification"] == "cooking_mode"
    return response.json()
