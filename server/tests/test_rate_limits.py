"""Real Redis HTTP quotas, dimension isolation and atomic concurrent admission."""

from concurrent.futures import ThreadPoolExecutor

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_request_signing import configure, quiet_risk


def assert_limited(response, *, day: bool = False) -> None:
    assert response.status_code == 429, response.text
    error = response.json()["error"]
    assert error["code"] == "rate_limited"
    assert error["message"] == "操作太频繁，请稍后再试"
    assert error["detail"] is None
    assert error["request_id"]
    delay = int(response.headers["Retry-After"])
    assert 1 <= delay <= (86400 if day else 60)
    if day:
        assert delay > 60


@pytest.mark.parametrize("dimension", ["account", "device", "ip"])
@pytest.mark.parametrize("window", ["minute", "day"])
def test_each_dimension_and_window_blocks_independently_and_hot_updates(
    api: Api, dimension: str, window: str
) -> None:
    quiet_risk()
    first = api.login("quota-a@example.com", "device-a")
    same_account = api.login("quota-a@example.com", "device-b")
    other_account_same_device = api.login("quota-b@example.com", "device-a")
    isolated = api.login("quota-c@example.com", "device-c")
    configure(f"rate.detail.{dimension}_per_{window}", 2)
    with (
        TestClient(api.client.app, client=("192.0.2.1", 10000), raise_server_exceptions=False) as a,
        TestClient(api.client.app, client=("192.0.2.2", 10000), raise_server_exceptions=False) as b,
    ):
        assert a.get("/v1/me", headers=bearer(first)).status_code == 200
        tokens = same_account if dimension == "account" else other_account_same_device
        # Swap every other dimension; only the tested identity is shared.
        second_client = a if dimension == "ip" else b
        assert second_client.get("/v1/me", headers=bearer(tokens)).status_code == 200
        limited = second_client.get("/v1/me", headers=bearer(tokens))
        assert_limited(limited, day=window == "day")
        assert b.get("/v1/me", headers=bearer(isolated)).status_code == 200
        configure(f"rate.detail.{dimension}_per_{window}", 10)
        assert second_client.get("/v1/me", headers=bearer(tokens)).status_code == 200
        configure(f"rate.detail.{dimension}_per_{window}", 1)
        assert_limited(second_client.get("/v1/me", headers=bearer(tokens)), day=window == "day")


@pytest.mark.parametrize(
    ("kind", "method", "url", "body"),
    [
        ("search_list", "GET", "/v1/recipes", None),
        ("search_list", "POST", "/v1/ingredients/search", {"query": "test"}),
        ("detail", "GET", "/v1/me", None),
        ("write", "PATCH", "/v1/me", {"nickname": "quota"}),
        ("ai", "GET", "/v1/ai/recipes/status", None),
        (
            "auth",
            "POST",
            "/v1/auth/email/code",
            {"email": "category@example.com", "purpose": "login"},
        ),
        ("auth", "POST", "/v1/risk/captcha", {"challenge_id": "missing", "response": "ok"}),
        # Export is reserved for the future own-data SPEC. 404 proves routing was
        # reached; this deliberately does not claim that data export exists yet.
        ("export", "GET", "/v1/export", None),
    ],
)
@pytest.mark.parametrize("window", ["minute", "day"])
def test_categories_have_independent_configured_quotas(
    api: Api, kind: str, method: str, url: str, body: dict | None, window: str
) -> None:
    quiet_risk()
    tokens = api.login("categories@example.com", "category-device")
    # Login requests already consume the IP auth quota; use a fresh IP/device.
    with TestClient(
        api.client.app, client=("198.51.100.9", 10000), raise_server_exceptions=False
    ) as client:
        configure(f"rate.{kind}.ip_per_{window}", 1)
        first = client.request(method, url, json=body, headers=bearer(tokens))
        assert first.status_code != 429, first.text
        assert_limited(
            client.request(method, url, json=body, headers=bearer(tokens)), day=window == "day"
        )
        other_url = "/v1/export" if kind != "export" else "/v1/me"
        assert client.get(other_url, headers=bearer(tokens)).status_code != 429


@pytest.mark.parametrize("dimension", ["account", "device", "ip"])
def test_atomic_concurrent_admission_cannot_exceed_quota(api: Api, dimension: str) -> None:
    quiet_risk()
    tokens = api.login("concurrent@example.com", "concurrent-device")
    configure(f"rate.detail.{dimension}_per_minute", 3)
    with ThreadPoolExecutor(max_workers=12) as pool:
        responses = list(
            pool.map(lambda _: api.client.get("/v1/me", headers=bearer(tokens)), range(12))
        )
    assert sum(r.status_code == 200 for r in responses) == 3
    for response in responses:
        if response.status_code != 200:
            assert_limited(response)
    assert_limited(api.client.get("/v1/me", headers=bearer(tokens)))


def test_minute_expiration_preserves_daily_quota(api: Api) -> None:
    quiet_risk()
    tokens = api.login("windows@example.com")
    configure("rate.detail.account_per_minute", 1)
    configure("rate.detail.account_per_day", 2)
    assert api.client.get("/v1/me", headers=bearer(tokens)).status_code == 200
    api.clock.advance(seconds=60)
    assert api.client.get("/v1/me", headers=bearer(tokens)).status_code == 200
    api.clock.advance(seconds=60)
    assert_limited(api.client.get("/v1/me", headers=bearer(tokens)), day=True)
    api.clock.advance(seconds=86400)
    refreshed = api.client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refreshed.status_code == 200, refreshed.text
    assert api.client.get("/v1/me", headers=bearer(refreshed.json())).status_code == 200


def test_invalid_config_cannot_disable_a_quota_and_missing_uses_defaults(api: Api) -> None:
    quiet_risk()
    tokens = api.login("config@example.com")
    assert api.client.get("/v1/me", headers=bearer(tokens)).status_code == 200
    configure("rate.detail.account_per_minute", 1)
    for invalid in ("0", "-1", "false", "NaN", "10000001"):
        assert (
            cli(
                [
                    "config",
                    "set",
                    "rate.detail.account_per_minute",
                    invalid,
                    "--by",
                    "http-test",
                    "--reason",
                    "bad config",
                ]
            )
            == 1
        )
        assert_limited(api.client.get("/v1/me", headers=bearer(tokens)))


@pytest.mark.parametrize("dimension", ["account", "device", "ip"])
def test_distinct_recipe_day_quota_counts_unique_ids_not_revisits(api: Api, dimension: str) -> None:
    quiet_risk()
    tokens = api.login("distinct@example.com", "distinct-device")
    configure(f"rate.detail.{dimension}_distinct_recipes_per_day", 1)
    first = "/v1/recipes/00000000-0000-4000-8000-000000000001"
    second = "/v1/recipes/00000000-0000-4000-8000-000000000002"
    for _ in range(2):
        assert api.client.get(first, headers=bearer(tokens)).status_code == 404
    assert_limited(api.client.get(second, headers=bearer(tokens)), day=True)
    configure(f"rate.detail.{dimension}_distinct_recipes_per_day", 3)
    assert api.client.get(second, headers=bearer(tokens)).status_code == 404


def test_export_quota_does_not_share_browsing_or_write_counters(api: Api) -> None:
    quiet_risk()
    tokens = api.login("export@example.com", "export-device")
    for dimension in ("account", "device", "ip"):
        configure(f"rate.detail.{dimension}_per_minute", 1)
        configure(f"rate.search_list.{dimension}_per_minute", 1)
    assert api.client.get("/v1/me", headers=bearer(tokens)).status_code == 200
    assert_limited(api.client.get("/v1/me", headers=bearer(tokens)))
    assert api.client.get("/v1/recipes", headers=bearer(tokens)).status_code == 200
    assert_limited(api.client.get("/v1/recipes", headers=bearer(tokens)))
    assert api.client.get("/v1/export", headers=bearer(tokens)).status_code == 404
    assert (
        api.client.patch(
            "/v1/me", json={"nickname": "still allowed"}, headers=bearer(tokens)
        ).status_code
        == 200
    )
    configure("rate.export.account_per_minute", 1)
    assert_limited(api.client.get("/v1/export", headers=bearer(tokens)))


def test_comparison_candidates_and_pending_changes_use_list_quota(api: Api) -> None:
    quiet_risk()
    tokens = api.login("list-category@example.com")
    configure("rate.search_list.account_per_minute", 1)
    configure("rate.detail.account_distinct_recipes_per_day", 1)
    url = "/v1/recipes/00000000-0000-4000-8000-000000000001/comparison-candidates"
    assert api.client.get(url, headers=bearer(tokens)).status_code == 404
    assert_limited(api.client.get(url, headers=bearer(tokens)))
    assert_limited(api.client.get("/v1/me/taste-profile/changes/pending", headers=bearer(tokens)))
    # A list route must not consume the distinct-detail budget for its recipe ID.
    assert (
        api.client.get(
            "/v1/recipes/00000000-0000-4000-8000-000000000002", headers=bearer(tokens)
        ).status_code
        == 404
    )
