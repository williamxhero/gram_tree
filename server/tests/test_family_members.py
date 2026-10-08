"""Family HTTP journeys plus the ticket-required encrypted-storage/deletion audits."""

import base64
import os
import uuid

import pytest
from pydantic import SecretStr

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
