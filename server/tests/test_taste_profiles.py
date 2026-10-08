"""Owner-scoped taste profile behavior through HTTP, using real PostgreSQL."""

from tests.accounts_support import Api, bearer

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
