"""Bounded signed cursor behavior across existing HTTP lists and public search."""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_cooking_records import _record
from tests.test_recipes import recipe_input
from tests.test_request_signing import configure, quiet_risk
from tests.test_taste_learning import create, run_learning

PRIVATE_LISTS = [
    "/v1/recipes",
    "/v1/recipes/00000000-0000-4000-8000-000000000001/versions",
    "/v1/recipes/00000000-0000-4000-8000-000000000001/comparison-candidates",
    "/v1/me/measures",
    "/v1/me/measures/00000000-0000-4000-8000-000000000001/history",
    "/v1/records",
    "/v1/me/taste-profile/changes",
    "/v1/me/taste-profile/changes/pending",
    "/v1/me/taste-profile/allergies/changes",
    "/v1/me/taste-profile/family-members",
    "/v1/me/taste-profile/family-members/changes",
    "/v1/ingredients/unrecorded",
]


def assert_refresh(response) -> None:
    assert response.status_code == 422, response.text
    error = response.json()["error"]
    assert error["code"] == "invalid_cursor"
    assert error["message"] == "请刷新列表"
    assert error["detail"] is None
    assert error["request_id"]


@pytest.mark.parametrize("url", PRIVATE_LISTS)
def test_all_existing_private_lists_reject_unsigned_or_malformed_cursor(api: Api, url: str) -> None:
    quiet_risk()
    tokens = api.login("lists@example.com")
    for cursor in (
        "garbage",
        "",
        "WyIyMDI2LTEwLTEzVDAwOjAwOjAwKzAwOjAwIiwiMDAwMDAwMDAtMDAwMC00MDAwLTgwMDAtMDAwMDAwMDAwMDAxIl0",
    ):
        assert_refresh(
            api.client.get(url, params={"limit": 1, "cursor": cursor}, headers=bearer(tokens))
        )


def create_recipes(api: Api, tokens: dict, count: int = 3) -> list[dict]:
    results = []
    for _ in range(count):
        response = api.client.post(
            "/v1/recipes", json=recipe_input("游标菜"), headers=bearer(tokens)
        )
        assert response.status_code == 201, response.text
        results.append(response.json())
    return results


def test_valid_cursor_account_query_route_binding_and_refresh_rotation(api: Api) -> None:
    quiet_risk()
    owner = api.login("cursor-owner@example.com", "device-a")
    same_owner = api.login("cursor-owner@example.com", "device-b")
    other = api.login("cursor-other@example.com", "device-c")
    recipes = create_recipes(api, owner)
    first = api.client.get("/v1/recipes", params={"limit": 1}, headers=bearer(owner))
    assert first.status_code == 200, first.text
    assert set(first.json()) == {"items", "next_cursor"}
    cursor = first.json()["next_cursor"]
    assert cursor
    params = {"limit": 1, "cursor": cursor}
    second = api.client.get("/v1/recipes", params=params, headers=bearer(same_owner))
    assert second.status_code == 200, second.text
    assert second.json()["items"][0]["id"] != first.json()["items"][0]["id"]
    assert_refresh(api.client.get("/v1/recipes", params=params, headers=bearer(other)))
    assert_refresh(
        api.client.get("/v1/recipes", params={**params, "limit": 2}, headers=bearer(owner))
    )
    assert_refresh(
        api.client.get("/v1/recipes", params={**params, "filter": "changed"}, headers=bearer(owner))
    )
    assert_refresh(
        api.client.get(
            f"/v1/recipes/{recipes[0]['id']}/versions", params=params, headers=bearer(owner)
        )
    )
    assert_refresh(
        api.client.get(
            "/v1/recipes", params={**params, "cursor": "A" + cursor[1:]}, headers=bearer(owner)
        )
    )
    rotated = api.client.post(
        "/v1/auth/refresh", json={"refresh_token": owner["refresh_token"]}
    ).json()
    assert api.client.get("/v1/recipes", params=params, headers=bearer(rotated)).status_code == 200


def test_cursor_chain_expires_without_renewal_and_hot_ttl_shortening(api: Api) -> None:
    quiet_risk()
    owner = api.login("cursor-time@example.com")
    create_recipes(api, owner, 4)
    configure("api.cursor_ttl_seconds", 10)
    first = api.client.get("/v1/recipes", params={"limit": 1}, headers=bearer(owner)).json()
    api.clock.advance(seconds=7)
    second = api.client.get(
        "/v1/recipes", params={"limit": 1, "cursor": first["next_cursor"]}, headers=bearer(owner)
    )
    assert second.status_code == 200, second.text
    api.clock.advance(seconds=3)
    assert_refresh(
        api.client.get(
            "/v1/recipes",
            params={"limit": 1, "cursor": second.json()["next_cursor"]},
            headers=bearer(owner),
        )
    )
    configure("api.cursor_ttl_seconds", 600)
    fresh = api.client.get("/v1/recipes", params={"limit": 1}, headers=bearer(owner)).json()
    api.clock.advance(seconds=2)
    configure("api.cursor_ttl_seconds", 1)
    assert_refresh(
        api.client.get(
            "/v1/recipes",
            params={"limit": 1, "cursor": fresh["next_cursor"]},
            headers=bearer(owner),
        )
    )


def test_max_pages_hot_update_stops_next_cursor_with_explicit_signal(api: Api) -> None:
    quiet_risk()
    owner = api.login("cursor-max@example.com")
    create_recipes(api, owner, 4)
    first = api.client.get("/v1/recipes", params={"limit": 1}, headers=bearer(owner)).json()
    second = api.client.get(
        "/v1/recipes", params={"limit": 1, "cursor": first["next_cursor"]}, headers=bearer(owner)
    ).json()
    configure("api.cursor_max_pages", 2)
    capped = api.client.get(
        "/v1/recipes", params={"limit": 1, "cursor": first["next_cursor"]}, headers=bearer(owner)
    )
    assert capped.status_code == 200, capped.text
    assert capped.json()["next_cursor"] is None
    assert capped.headers["X-Pagination-Limit-Reached"] == "true"
    rejected = api.client.get(
        "/v1/recipes", params={"limit": 1, "cursor": second["next_cursor"]}, headers=bearer(owner)
    )
    assert rejected.status_code == 422
    assert rejected.json()["error"]["code"] == "pagination_limit_reached"
    assert rejected.json()["error"]["message"] == "请换搜索条件"
    configure("api.cursor_max_pages", 3)
    assert (
        api.client.get(
            "/v1/recipes",
            params={"limit": 1, "cursor": second["next_cursor"]},
            headers=bearer(owner),
        ).status_code
        == 200
    )


@pytest.mark.parametrize(
    "kind", ["versions", "candidates", "measures", "measure_history", "records", "taste_changes"]
)
def test_non_collection_lists_keep_valid_paging_shape_and_signed_boundary(
    api: Api, kind: str
) -> None:
    quiet_risk()
    tokens = api.login("other-lists@example.com")
    h = bearer(tokens)
    if kind in {"versions", "candidates"}:
        recipe = create_recipes(api, tokens)[0]
        for _ in range(2):
            response = api.client.post(
                f"/v1/recipes/{recipe['id']}/versions", json=recipe_input("游标菜"), headers=h
            )
            assert response.status_code == 201, response.text
        suffix = "versions" if kind == "versions" else "comparison-candidates"
        url = f"/v1/recipes/{recipe['id']}/{suffix}"
    elif kind in {"measures", "measure_history"}:
        measures = []
        for i in range(3):
            response = api.client.post(
                "/v1/me/measures",
                json={"name": f"勺{i}", "kind": "spoon", "capacity_ml": 10},
                headers=h,
            )
            assert response.status_code == 201, response.text
            measures.append(response.json())
        for i in range(2):
            response = api.client.patch(
                f"/v1/me/measures/{measures[0]['id']}", json={"capacity_ml": 11 + i}, headers=h
            )
            assert response.status_code == 200, response.text
        url = (
            "/v1/me/measures"
            if kind == "measures"
            else f"/v1/me/measures/{measures[0]['id']}/history"
        )
    elif kind == "records":
        for _ in range(3):
            response = api.client.post("/v1/records", json=_record(tokens["user"]["id"]), headers=h)
            assert response.status_code == 201, response.text
        url = "/v1/records"
    else:
        for value in (0.5, 0.75, 1.25):
            response = api.client.patch(
                "/v1/me/taste-profile", json={"flavors": {"spicy": value}}, headers=h
            )
            assert response.status_code == 200, response.text
        url = "/v1/me/taste-profile/changes"
    first = api.client.get(url, params={"limit": 1}, headers=h)
    assert first.status_code == 200, first.text
    cursor = first.json()["next_cursor"]
    assert cursor
    second = api.client.get(url, params={"limit": 1, "cursor": cursor}, headers=h)
    assert second.status_code == 200, second.text
    assert len(second.json()["items"]) == 1
    assert second.json()["items"] != first.json()["items"]
    assert_refresh(api.client.get(url, params={"limit": 2, "cursor": cursor}, headers=h))


def test_pending_changes_continue_without_repeating_the_first_page(api: Api) -> None:
    quiet_risk()
    tokens = api.login("pending-cursor@example.com")
    for ingredient in ("香菜", "葱", "蒜"):
        snapshot = {
            "format_version": 1,
            "dish_name": "测试菜",
            "ingredients": [
                {"display_name": ingredient, "disposition": "deleted", "category": "蔬菜"}
            ],
        }
        for _ in range(2):
            create(api, tokens, snapshot=snapshot, adjustments=[{"text": f"去掉{ingredient}"}])
    suggestions = run_learning(api, tokens)["pending_suggestions"]
    assert len(suggestions) == 3
    url = "/v1/me/taste-profile/changes/pending"
    seen = []
    cursor = None
    for _ in range(3):
        params = {"limit": 1}
        if cursor is not None:
            params["cursor"] = cursor
        response = api.client.get(url, params=params, headers=bearer(tokens))
        assert response.status_code == 200, response.text
        page = response.json()
        assert len(page["items"]) == 1
        seen.append(page["items"][0]["id"])
        cursor = page["next_cursor"]
    assert set(seen) == {row["id"] for row in suggestions}
    assert cursor is None


def test_public_search_cursor_stable_subject_body_binding_expiry_and_request_isolation(
    api: Api,
) -> None:
    quiet_risk()
    assert cli(["ingredients", "import", str(Path(__file__).parent / "data" / "ingredients")]) == 0
    url, body = "/v1/ingredients/search", {"query": "测试"}
    with (
        TestClient(api.client.app, client=("192.0.2.10", 10000)) as first_client,
        TestClient(api.client.app, client=("192.0.2.10", 10001)) as same_subject,
        TestClient(api.client.app, client=("192.0.2.11", 10000)) as other_subject,
    ):
        first = first_client.post(
            url, json=body, params={"limit": 1}, headers={"X-Device-ID": "public-a"}
        )
        assert first.status_code == 200, first.text
        cursor = first.json()["next_cursor"]
        assert cursor
        params = {"limit": 1, "cursor": cursor}
        second = same_subject.post(
            url, json=body, params=params, headers={"X-Device-ID": "public-a"}
        )
        assert second.status_code == 200, second.text
        assert second.json()["items"] != first.json()["items"]
        assert_refresh(
            other_subject.post(url, json=body, params=params, headers={"X-Device-ID": "public-a"})
        )
        assert_refresh(
            same_subject.post(url, json=body, params=params, headers={"X-Device-ID": "public-b"})
        )
        assert_refresh(
            first_client.post(
                url, json={"query": "测试盐"}, params=params, headers={"X-Device-ID": "public-a"}
            )
        )
        with ThreadPoolExecutor(max_workers=4) as pool:
            responses = list(
                pool.map(
                    lambda i: (same_subject if i % 2 == 0 else other_subject).post(
                        url, json=body, params=params, headers={"X-Device-ID": "public-a"}
                    ),
                    range(4),
                )
            )
        assert [r.status_code for r in responses] == [200, 422, 200, 422]
        api.clock.advance(seconds=601)
        assert_refresh(
            same_subject.post(url, json=body, params=params, headers={"X-Device-ID": "public-a"})
        )
