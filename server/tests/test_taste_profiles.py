"""Owner-scoped taste profile behavior through HTTP, using real PostgreSQL."""

import json
import uuid
from concurrent.futures import ThreadPoolExecutor

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from gramtree.main import create_app
from tests.accounts_support import Api, bearer
from tests.conftest import make_settings
from tests.test_account_deletion import _purge, _reauth_email

PATH = "/v1/me/taste-profile"
KEYS = {"salty", "sweet", "sour", "spicy", "numbing", "umami", "oily"}


def test_defaults_manual_change_history_and_reset(api: Api) -> None:
    headers = bearer(api.login("taste-owner@example.com"))
    first = api.client.get(PATH, headers=headers)
    assert first.status_code == 200, first.text
    profile = first.json()
    assert profile["version"] == 1
    assert set(profile["flavors"]) == KEYS
    assert all(
        v["coefficient"] == 1.0 and v["confidence"] == "low" for v in profile["flavors"].values()
    )
    assert profile["local_cuisines"] == []
    assert api.client.get(PATH, headers=headers).json() == profile

    changed = api.client.patch(PATH, json={"flavors": {"salty": 0.75}}, headers=headers)
    assert changed.status_code == 200, changed.text
    assert changed.json()["version"] == 2
    assert changed.json()["flavors"]["salty"]["confidence"] == "high"
    other_device = bearer(api.login("taste-owner@example.com", device="second"))
    assert api.client.get(PATH, headers=other_device).json() == changed.json()
    history = api.client.get(PATH + "/changes", headers=headers).json()["items"]
    assert len(history) == 1
    assert history[0]["field"] == "flavors.salty"
    assert history[0]["old_value"] == {"coefficient": 1.0, "confidence": "low"}
    assert history[0]["new_value"] == {"coefficient": 0.75, "confidence": "high"}
    assert history[0]["reason"] == "你手动修改"
    assert history[0]["source"] == "manual"
    assert history[0]["status"] == "active"
    assert (
        api.client.patch(PATH, json={"flavors": {"salty": 0.75}}, headers=headers).json()["version"]
        == 2
    )
    restored = api.client.post(PATH + "/reset", headers=headers)
    assert restored.status_code == 200, restored.text
    assert restored.json()["version"] == 3
    assert restored.json()["flavors"] == profile["flavors"]
    assert api.client.get(PATH, headers=headers).json() == restored.json()
    assert len(api.client.get(PATH + "/changes", headers=headers).json()["items"]) == 2
    assert api.client.post(PATH + "/reset", headers=headers).json()["version"] == 3


def test_invalid_patch_is_atomic_and_history_is_private(api: Api) -> None:
    owner = bearer(api.login("taste-validation@example.com"))
    other = bearer(api.login("taste-other@example.com", device="other"))
    before = api.client.get(PATH, headers=owner).json()
    for body in (
        {"flavors": {"salty": 0.75, "sweet": 1.6}},
        {"flavors": {"salt": 0.75}},
        {"flavors": {"salty": None}},
        {"flavors": {"salty": "NaN"}},
        {"flavors": {"salty": True}},
        {"flavors": {}},
        {"flavors": {"salty": 0.75}, "owner_id": before["id"]},
        {"local_cuisines": []},
    ):
        response = api.client.patch(PATH, json=body, headers=owner)
        assert response.status_code == 422, response.text
        assert api.client.get(PATH, headers=owner).json() == before
        assert api.client.get(PATH + "/changes", headers=owner).json()["items"] == []
    for value in ("NaN", "Infinity", "-Infinity"):
        response = api.client.patch(
            PATH,
            content='{"flavors":{"salty":' + value + "}}",
            headers={**owner, "Content-Type": "application/json"},
        )
        assert response.status_code == 422, response.text
    changed = api.client.patch(PATH, json={"flavors": {"salty": 0.5, "sweet": 1.5}}, headers=owner)
    assert changed.status_code == 200
    assert changed.json()["version"] == 2
    changes = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert len(changes) == 2
    assert {change["version"] for change in changes} == {2}
    first_page = api.client.get(PATH + "/changes", params={"limit": 1}, headers=owner).json()
    second_page = api.client.get(
        PATH + "/changes", params={"limit": 1, "cursor": first_page["next_cursor"]}, headers=owner
    ).json()
    assert first_page["items"] + second_page["items"] == changes
    assert api.client.get(PATH + "/changes", headers=other).json()["items"] == []
    assert api.client.get(PATH + "/changes/" + changes[0]["id"], headers=other).status_code == 404
    assert api.client.get(PATH + "/changes/" + changes[0]["id"], headers=owner).json() == changes[0]
    assert api.client.get(PATH, headers=other).json()["id"] != before["id"]
    assert api.client.get(PATH).status_code == 401


def test_change_events_are_atomic_metadata_only_and_cannot_be_forged(api: Api) -> None:
    owner = bearer(api.login("taste-events@example.com"))
    other = bearer(api.login("taste-forger@example.com", device="forger"))
    api.client.patch(PATH, json={"flavors": {"salty": 0.75}}, headers=owner)
    change = api.client.get(PATH + "/changes", headers=owner).json()["items"][0]
    params = {"event_type": "taste_profile.changed"}
    assert api.client.get("/v1/dev/events/count", params=params, headers=owner).json() == {
        "count": 1
    }
    event = {
        "id": change["id"],
        "event_type": "taste_profile.changed",
        "type_version": 1,
        "device_id": "server",
        "app_version": "server",
        "device_time": change["created_at"],
        "correlation": {"taste_profile_change_id": change["id"]},
        "content": {},
    }

    def upload(item: dict, headers: dict) -> dict:
        response = api.client.post("/v1/events/upload", json={"events": [item]}, headers=headers)
        assert response.status_code == 200, response.text
        return response.json()["results"][0]

    assert upload(event, owner)["status"] == "duplicate"
    assert upload(event, other)["status"] == "rejected"
    assert upload({**event, "id": str(uuid.uuid4())}, owner)["status"] == "rejected"
    assert (
        upload({**event, "correlation": {"taste_profile_change_id": str(uuid.uuid4())}}, owner)[
            "status"
        ]
        == "rejected"
    )
    assert upload({**event, "correlation": {}}, owner)["status"] == "rejected"
    assert (
        upload({**event, "content": {"flavors": {"salty": 0.75}}}, owner)["reason"]["code"]
        == "invalid_content"
    )
    assert (
        upload(
            {
                **event,
                "correlation": {**event["correlation"], "recipe_version_id": str(uuid.uuid4())},
            },
            owner,
        )["status"]
        == "rejected"
    )
    # Other registered event types must not be a bypass for a forged profile link.
    assert (
        upload(
            {
                **event,
                "id": str(uuid.uuid4()),
                "event_type": "pipeline.self_check",
                "content": {"ping": "test"},
            },
            other,
        )["status"]
        == "rejected"
    )
    assert api.client.get("/v1/dev/events/count", params=params, headers=owner).json() == {
        "count": 1
    }
    assert api.client.get("/v1/dev/events/count", params=params, headers=other).json() == {
        "count": 0
    }
    api.client.patch(PATH, json={"flavors": {"salty": 0.75}}, headers=owner)
    assert api.client.get("/v1/dev/events/count", params=params, headers=owner).json() == {
        "count": 1
    }
    api.client.patch(PATH, json={"flavors": {"salty": 2}}, headers=owner)
    assert api.client.get("/v1/dev/events/count", params=params, headers=owner).json() == {
        "count": 1
    }


def test_concurrent_first_reads_and_distinct_mutations_keep_one_profile(api: Api) -> None:
    owner = bearer(api.login("taste-concurrent@example.com"))
    with ThreadPoolExecutor(max_workers=2) as pool:
        reads = list(pool.map(lambda _: api.client.get(PATH, headers=owner), range(2)))
        assert all(response.status_code == 200 for response in reads)
        assert reads[0].json() == reads[1].json()
        responses = list(
            pool.map(
                lambda patch: api.client.patch(PATH, json={"flavors": patch}, headers=owner),
                [{"salty": 0.5}, {"sweet": 1.5}],
            )
        )
    assert {response.json()["version"] for response in responses} == {2, 3}
    current = api.client.get(PATH, headers=owner).json()
    assert current["version"] == 3
    assert current["flavors"]["salty"]["coefficient"] == 0.5
    assert current["flavors"]["sweet"]["coefficient"] == 1.5
    assert len(api.client.get(PATH + "/changes", headers=owner).json()["items"]) == 2


def test_configurable_mapping_and_invalid_configuration_fail_closed(api: Api) -> None:
    owner = bearer(api.login("taste-config@example.com"))
    scale = {
        "minimum": 0.25,
        "maximum": 2.0,
        "default": 1.2,
        "levels": [
            {"coefficient": value, "label": label}
            for value, label in [
                (0.25, "很淡"),
                (0.6, "偏淡"),
                (1.2, "标准"),
                (1.6, "偏重"),
                (2.0, "很重"),
            ]
        ],
    }
    assert (
        cli(
            [
                "config",
                "set",
                "taste.scale",
                json.dumps(scale),
                "--by",
                "test",
                "--reason",
                "synthetic scale",
            ]
        )
        == 0
    )
    current = api.client.get(PATH, headers=owner).json()
    assert current["scale"] == scale
    assert all(
        flavor["coefficient"] == 1.2 and flavor["label"] == "标准"
        for flavor in current["flavors"].values()
    )
    changed = api.client.patch(PATH, json={"flavors": {"salty": 2.0}}, headers=owner)
    assert changed.status_code == 200
    assert changed.json()["flavors"]["salty"]["label"] == "很重"
    assert (
        api.client.patch(PATH, json={"flavors": {"salty": 2.01}}, headers=owner).status_code == 422
    )
    before = changed.json()
    invalid = {**scale, "default": 1.0}
    assert (
        cli(
            [
                "config",
                "set",
                "taste.scale",
                json.dumps(invalid),
                "--by",
                "test",
                "--reason",
                "invalid synthetic scale",
            ]
        )
        == 0
    )
    for method, path, body in [
        ("GET", PATH, None),
        ("PATCH", PATH, {"flavors": {"salty": 0.6}}),
        ("POST", PATH + "/reset", None),
    ]:
        assert api.client.request(method, path, json=body, headers=owner).status_code == 503
    assert (
        cli(
            [
                "config",
                "set",
                "taste.scale",
                json.dumps(scale),
                "--by",
                "test",
                "--reason",
                "restore scale",
            ]
        )
        == 0
    )
    assert api.client.get(PATH, headers=owner).json() == before


def test_storage_diagnostics_are_not_available_in_dev(api: Api) -> None:
    owner = bearer(api.login("taste-dev-diagnostics@example.com"))
    with TestClient(create_app(make_settings(env="dev"))) as client:
        assert client.get("/v1/dev/events/taste-profile-storage", headers=owner).status_code == 404


def test_profile_event_storage_is_metadata_only_and_purge_removes_private_data(api: Api) -> None:
    email = "taste-delete@example.com"
    tokens = api.login(email)
    owner = bearer(tokens)
    api.client.patch(PATH, json={"flavors": {"salty": 0.75}}, headers=owner)
    changes = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert len(changes) == 1
    diagnostic = "/v1/dev/events/taste-profile-storage"
    before = api.client.get(diagnostic, headers=owner)
    assert before.status_code == 200, before.text
    assert before.json() == {
        "profiles": 1,
        "changes": 1,
        "events": 1,
        "taste_events": 1,
        "metadata_only": True,
    }
    assert api.client.get(diagnostic).status_code == 401
    observer = bearer(api.login("taste-storage-observer@example.com"))
    assert (
        api.client.get(
            diagnostic, params={"owner_id": tokens["user"]["id"]}, headers=observer
        ).status_code
        == 404
    )
    assert diagnostic not in api.client.get("/openapi.json").json()["paths"]
    assert _reauth_email(api, tokens, email) == 204
    due = api.client.post("/v1/me/deletion", headers=owner).json()["deletion_due_at"]
    assert api.client.get(PATH, headers=owner).status_code == 401
    assert "已删除 1 个" in _purge(due)
    after = api.client.get(diagnostic, params={"owner_id": tokens["user"]["id"]}, headers=observer)
    assert after.status_code == 200, after.text
    assert after.json() == {
        "profiles": 0,
        "changes": 0,
        "events": 0,
        "taste_events": 0,
        "metadata_only": True,
    }
    api.clock.advance(seconds=61)
    fresh = bearer(api.login(email))
    assert api.client.get(PATH, headers=fresh).json()["version"] == 1
    assert api.client.get(PATH + "/changes", headers=fresh).json()["items"] == []
