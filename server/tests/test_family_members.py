"""Family HTTP journeys plus the ticket-required encrypted-storage/deletion audits."""

import base64
import os
import uuid
from pathlib import Path

import pytest
from pydantic import SecretStr

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_allergies import consent

PATH = "/v1/me/taste-profile/family-members"


@pytest.fixture
def family_api(api: Api) -> Api:
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"sensitive_data_key": SecretStr(base64.urlsafe_b64encode(os.urandom(32)).decode())}
    )
    return api


def member_body(state: dict, **changes) -> dict:
    return {
        "consent_id": state["consent_id"] or str(uuid.uuid4()),
        "authorization_version": state["authorization_version"],
        "nickname": "孩子",
        "age_band": "3_to_6",
        "flavors": {"spicy": 0},
        "avoidances": [],
        "allergies": {"categories": ["花生"], "ingredient_ids": []},
        **changes,
    }


def test_family_creation_reuses_sensitive_consent_and_shared_manual_history(family_api: Api):
    api = family_api
    owner = bearer(api.login("family-owner@example.com"))
    before = api.client.get(PATH, headers=owner)
    assert before.status_code == 200, before.text
    assert before.json()["members"] == []
    denied = api.client.post(PATH, headers=owner, json=member_body(before.json()))
    assert denied.status_code == 403, denied.text
    grant = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert state["consent_id"] == grant["id"]
    created = api.client.post(PATH, headers=owner, json=member_body(state))
    assert created.status_code == 201, created.text
    member = created.json()
    assert member["nickname"] == "孩子"
    assert member["age_band"] == "3_to_6"
    assert member["flavors"] == {"spicy": 0}
    assert member["allergies"] == {"categories": ["花生"], "ingredients": []}
    assert member["source"] == "manual"
    assert api.client.get(PATH + "/" + member["id"], headers=owner).json() == member
    reopened = api.client.get(PATH, headers=owner).json()
    assert reopened["members"] == [member]
    assert reopened["profile_version"] == state["profile_version"] + 1
    history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert len(history) == 1
    assert history[0]["field"] == "family_members." + member["id"]
    assert history[0]["old_value"] == {}
    assert history[0]["new_value"]["nickname"] == "孩子"
    assert history[0]["reason"] == "你手动修改"
    assert history[0]["source"] == "manual"
    assert history[0]["version"] == reopened["profile_version"]
    assert api.client.get("/v1/me/taste-profile/changes", headers=owner).json()["items"] == []


def test_member_delete_is_keyless_erases_identifiable_history_and_linked_events(family_api: Api):
    api = family_api
    owner = bearer(api.login("family-delete@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    member = api.client.post(PATH, headers=owner, json=member_body(state)).json()
    kept = api.client.post(
        PATH, headers=owner, json=member_body(state, nickname="长辈", age_band="elder")
    ).json()
    changed = api.client.put(
        PATH + "/" + member["id"], headers=owner, json=member_body(state, nickname="小朋友")
    )
    assert changed.status_code == 200, changed.text
    changes = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    private_ids = [row["id"] for row in changes if row["field"] == "family_members." + member["id"]]
    event = {
        "id": str(uuid.uuid4()),
        "event_type": "pipeline.self_check",
        "type_version": 1,
        "device_id": "family-link",
        "device_time": api.clock.now.isoformat(),
        "app_version": "1.0.0",
        "content": {"ping": "pong"},
        "correlation": {"taste_profile_change_id": private_ids[0].upper()},
    }
    upload = api.client.post("/v1/events/upload", headers=owner, json={"events": [event]})
    assert upload.json()["results"][0]["status"] == "accepted"
    version = api.client.get(PATH, headers=owner).json()["profile_version"]
    settings = api.client.app.state.settings
    api.client.app.state.settings = settings.model_copy(update={"sensitive_data_key": None})
    response = api.client.delete(PATH + "/" + member["id"], headers=owner)
    assert response.status_code == 204, response.text
    assert api.client.get(PATH + "/" + member["id"], headers=owner).status_code == 404
    # Unrelated members are not readable without the key and must not be lost.
    assert api.client.get(PATH + "/" + kept["id"], headers=owner).status_code == 503
    api.client.app.state.settings = settings
    reopened = api.client.get(PATH, headers=owner).json()
    assert reopened["members"] == [kept]
    assert reopened["profile_version"] == version + 1
    history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert not any(row["id"] in private_ids for row in history)
    receipt = next(row for row in history if row["field"] == "family_members")
    assert receipt["old_value"] == {"present": True}
    assert receipt["new_value"] == {"present": False}
    assert receipt["reason"] == "你手动删除家庭成员"
    assert receipt["source"] == "manual"
    assert member["id"] not in str(history)
    late = api.client.post(
        "/v1/events/upload", headers=owner, json={"events": [{**event, "id": str(uuid.uuid4())}]}
    )
    assert late.json()["results"][0]["status"] == "rejected"
    audit = api.client.get(
        "/v1/dev/events/taste-profile-storage?include_sensitive=true", headers=owner
    ).json()
    assert audit["family_members"] == 1
    assert audit["family_changes"] == 2  # kept creation + non-identifying deletion receipt
    assert audit["events"] == 2
    assert audit["metadata_only"] is True
    assert reopened["authorization_version"] == state["authorization_version"] + 1
    assert reopened["consent_id"] == state["consent_id"]
    stale_write = api.client.put(PATH + "/" + kept["id"], headers=owner, json=member_body(state))
    assert stale_write.status_code == 409
    for change_id in private_ids:
        assert api.client.get(PATH + "/changes/" + change_id, headers=owner).status_code == 404


def audit_storage(api: Api, owner: dict, **params) -> dict:
    response = api.client.get(
        "/v1/dev/events/taste-profile-storage",
        headers=owner,
        params={"include_sensitive": "true", **params},
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_seven_age_bands_sparse_flavors_and_canonical_selections_are_manual(family_api: Api):
    api = family_api
    assert cli(["ingredients", "import", str(Path(__file__).parent / "data" / "ingredients")]) == 0
    owner = bearer(api.login("family-bands@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert state["available_age_bands"] == [
        "under_1",
        "1_to_3",
        "3_to_6",
        "6_to_12",
        "12_to_18",
        "adult",
        "elder",
    ]
    ingredient = api.client.post("/v1/ingredients/search", json={"query": "测试酱油"}).json()[
        "items"
    ][0]
    created_ids = []
    for band in state["available_age_bands"]:
        response = api.client.post(
            PATH,
            headers=owner,
            json=member_body(
                state,
                age_band=band,
                flavors={"salty": 0.75, "spicy": 0, "sweet": 1.0},
                avoidances=[{"ingredient_id": ingredient["id"]}, {"category": "蔬菜"}],
                allergies={"categories": ["花生", "花生"], "ingredient_ids": [ingredient["id"]]},
            ),
        )
        assert response.status_code == 201, response.text
        member = response.json()
        created_ids.append(member["id"])
        assert member["age_band"] == band
        assert member["flavors"] == {"salty": 0.75, "spicy": 0}
        assert {row["name"] for row in member["avoidances"]} == {"蔬菜", "测试酱油"}
        assert member["allergies"] == {
            "categories": ["花生"],
            "ingredients": [{"ingredient_id": ingredient["id"], "name": "测试酱油"}],
        }
    seen = []
    cursor = None
    while True:
        page = api.client.get(
            PATH, headers=owner, params={"limit": 2, **({"cursor": cursor} if cursor else {})}
        ).json()
        seen.extend(row["id"] for row in page["members"])
        cursor = page["next_cursor"]
        if cursor is None:
            break
    assert set(seen) == set(created_ids)
    assert len(seen) == 7
    assert api.client.get(PATH, headers=owner, params={"limit": 10001}).status_code == 422
    before = api.client.get(PATH, headers=owner).json()
    original = api.client.get(PATH + "/" + created_ids[0], headers=owner).json()
    replacement = member_body(
        state,
        age_band="under_1",
        flavors={"salty": 0.75, "spicy": 0},
        avoidances=[
            {"category": "蔬菜"},
            {"ingredient_id": ingredient["id"]},
            {"category": "蔬菜"},
        ],
        allergies={"categories": ["花生"], "ingredient_ids": [ingredient["id"], ingredient["id"]]},
    )
    assert (
        api.client.put(PATH + "/" + created_ids[0], headers=owner, json=replacement).json()
        == original
    )
    assert api.client.get(PATH, headers=owner).json() == before
    cleared = api.client.put(
        PATH + "/" + created_ids[0],
        headers=owner,
        json={
            "consent_id": state["consent_id"],
            "authorization_version": state["authorization_version"],
            "nickname": "婴儿",
            "age_band": "under_1",
        },
    )
    assert cleared.status_code == 200, cleared.text
    assert cleared.json()["flavors"] == {}
    assert cleared.json()["avoidances"] == []
    assert cleared.json()["allergies"] == {"categories": [], "ingredients": []}
    history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert all(row["source"] == "manual" for row in history)
    assert history[0]["old_value"]["allergies"]["categories"] == ["花生"]
    assert history[0]["new_value"]["allergies"] == {"categories": [], "ingredients": []}
    assert history[0]["version"] == before["profile_version"] + 1
    assert api.client.get(PATH + "/changes/" + history[0]["id"], headers=owner).json() == history[0]


def test_validation_is_atomic_private_and_forbids_extra_identity_or_inferred_fields(
    family_api: Api, caplog
):
    api = family_api
    owner = bearer(api.login("family-validation@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    marker = "private-family-never-log"
    invalid = [
        {"name": marker},
        {"real_name": marker},
        {"birthday": marker},
        {"photo": marker},
        {"source": "learning"},
        {"age_band": "child"},
        {"nickname": "  "},
        {"nickname": None},
        {"flavors": {"spicy": 0.25}},
        {"flavors": {"salty": 0}},
        {"flavors": {"sweet": 2.0}},
        {"flavors": {"spicy": True}},
        {"flavors": {"unknown": 0.75}},
        {"avoidances": [{"category": marker}]},
        {"avoidances": [{"ingredient_id": str(uuid.uuid4())}]},
        {"avoidances": [{"category": "蔬菜", "name": marker}]},
        {"avoidances": [{"category": "蔬菜", "ingredient_id": str(uuid.uuid4())}]},
        {"allergies": {"categories": [marker]}},
        {"allergies": {"ingredient_ids": [str(uuid.uuid4())]}},
        {"allergies": {"source": "ai", "categories": []}},
    ]
    for value in invalid:
        response = (
            api.client.post(PATH, headers=owner, json=member_body(state, nickname=marker, **value))
            if "nickname" not in value
            else api.client.post(PATH, headers=owner, json=member_body(state, **value))
        )
        assert response.status_code == 422, response.text
        assert marker not in response.text
    assert api.client.get(PATH, headers=owner).json() == state
    assert api.client.get(PATH + "/changes", headers=owner).json()["items"] == []
    audit = audit_storage(api, owner)
    assert audit["family_members"] == 0
    assert audit["family_changes"] == 0
    assert audit["events"] == 0
    assert marker not in str(
        [row.__dict__ for row in caplog.records if row.name.startswith("gramtree")]
    )


def test_family_and_history_are_owner_scoped_not_ordinary_profile_or_public(family_api: Api):
    api = family_api
    owner = bearer(api.login("family-private@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    member = api.client.post(PATH, headers=owner, json=member_body(state)).json()
    change = api.client.get(PATH + "/changes", headers=owner).json()["items"][0]
    other_tokens = api.login("family-other@example.com", device="other")
    other = bearer(other_tokens)
    consent(api, other)
    other_state = api.client.get(PATH, headers=other).json()
    assert other_state["members"] == []
    for method, path, body in (
        ("get", PATH + "/" + member["id"], None),
        ("put", PATH + "/" + member["id"], member_body(other_state)),
        ("delete", PATH + "/" + member["id"], None),
        ("get", PATH + "/changes/" + change["id"], None),
    ):
        response = getattr(api.client, method)(
            path, headers=other, **({"json": body} if body else {})
        )
        assert response.status_code == 404, response.text
    assert api.client.get(PATH + "/changes", headers=other).json()["items"] == []
    assert api.client.get(PATH).status_code == 401
    assert (
        api.client.get("/v1/me/taste-profile/changes/" + change["id"], headers=owner).status_code
        == 404
    )
    assert "family_members" not in api.client.get("/v1/me/taste-profile", headers=owner).json()
    assert (
        api.client.get(
            "/v1/dev/events/taste-profile-storage",
            headers=other,
            params={
                "include_sensitive": "true",
                "owner_id": api.client.get("/v1/me", headers=owner).json()["id"],
            },
        ).status_code
        == 404
    )
    assert api.client.get(PATH + "/" + member["id"], headers=owner).json() == member
