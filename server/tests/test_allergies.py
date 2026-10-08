"""Sensitive owner HTTP journeys; DB/log audits are explicitly required by #151."""
import base64
import os
import uuid
from datetime import timedelta

from sqlalchemy import text
from sqlalchemy.engine import Engine

from tests.test_account_deletion import _reauth_email

import pytest
from pydantic import SecretStr

from tests.accounts_support import Api, bearer

PATH = "/v1/me/taste-profile/allergies"
CONSENTS = "/v1/me/consents"


@pytest.fixture
def sensitive_api(api: Api) -> Api:
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"sensitive_data_key": SecretStr(base64.urlsafe_b64encode(os.urandom(32)).decode())}
    )
    return api


def consent(api: Api, owner: dict[str, str], action: str = "agree", **changes):
    record = {
        "id": str(uuid.uuid4()), "kind": "sensitive_personal_info",
        "version": "allergies-v1", "action": action,
        "occurred_at": api.clock.now.isoformat(), **changes,
    }
    result = api.client.post(CONSENTS, headers=owner, json={"records": [record]})
    assert result.status_code == 204, result.text
    return record


def save(api: Api, owner: dict[str, str], state: dict, categories: list[str], ingredients=None):
    return api.client.put(PATH, headers=owner, json={
        "consent_id": state["consent_id"],
        "authorization_version": state["authorization_version"],
        "categories": categories, "ingredient_ids": ingredients or [],
    })


def test_explicit_sensitive_grant_is_required_and_manual_changes_are_private(sensitive_api: Api):
    api = sensitive_api
    owner = bearer(api.login("allergy-owner@example.com"))
    denied = api.client.put(PATH, headers=owner, json={
        "consent_id": str(uuid.uuid4()), "authorization_version": 0,
        "categories": ["花生"], "ingredient_ids": [],
    })
    assert denied.status_code == 403, denied.text
    before = api.client.get(PATH, headers=owner)
    assert before.status_code == 200, before.text
    assert before.json()["consent_id"] is None
    assert before.json()["categories"] == []
    consent(api, owner, kind="privacy")
    consent(api, owner, version="v1")  # legacy upload is recorded, not allergy authorization
    assert api.client.get(PATH, headers=owner).json()["consent_id"] is None
    grant = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert state["consent_id"] == grant["id"]
    assert len(state["available_categories"]) == 8
    saved = save(api, owner, state, ["花生", "乳及乳制品"])
    assert saved.status_code == 200, saved.text
    current = saved.json()
    assert current["categories"] == ["乳及乳制品", "花生"]
    assert api.client.get(PATH, headers=owner).json() == current
    history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert len(history) == 1
    assert history[0]["old_value"] == {"categories": [], "ingredients": []}
    assert history[0]["new_value"] == {"categories": current["categories"], "ingredients": []}
    assert history[0]["version"] == current["profile_version"]
    assert history[0]["field"] == "allergies"
    assert history[0]["source"] == "manual"
    assert history[0]["reason"] == "你手动修改"
    assert history[0]["status"] == "active"
    ordinary = api.client.get("/v1/me/taste-profile/changes", headers=owner).json()["items"]
    assert ordinary == []
    other = bearer(api.login("other-allergy@example.com", device="other"))
    assert api.client.get(PATH, headers=other).json()["categories"] == []
    assert api.client.get(PATH + "/changes/" + history[0]["id"], headers=other).status_code == 403
    assert api.client.get(PATH).status_code == 401


def test_deletion_erases_sensitive_copies_immediately_without_key(sensitive_api: Api, engine: Engine):
    api = sensitive_api
    tokens = api.login("allergy-delete@example.com")
    owner = bearer(tokens)
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert save(api, owner, state, ["花生"]).status_code == 200
    api.client.app.state.settings = api.client.app.state.settings.model_copy(update={"sensitive_data_key": None})
    assert _reauth_email(api, tokens, "allergy-delete@example.com") == 204
    deletion = api.client.post("/v1/me/deletion", headers=owner)
    assert deletion.status_code == 202, deletion.text
    with engine.connect() as conn:
        assert conn.scalar(text("SELECT count(*) FROM owner_allergies")) == 0
        assert conn.scalar(text("SELECT count(*) FROM taste_profile_changes WHERE field='allergies'")) == 0
        assert conn.scalar(text("SELECT count(*) FROM events WHERE correlation ? 'taste_profile_change_id'")) == 0
    assert api.client.get(PATH, headers=owner).status_code == 401


def test_future_withdrawal_is_immediate_but_does_not_poison_fresh_regrant(sensitive_api: Api):
    api = sensitive_api
    owner = bearer(api.login("future-withdraw@example.com"))
    grant = consent(api, owner)
    stale = api.client.get(PATH, headers=owner).json()
    assert save(api, owner, stale, ["花生"]).status_code == 200
    consent(api, owner, "withdraw", occurred_at=(api.clock.now + timedelta(days=3650)).isoformat())
    revoked = api.client.get(PATH, headers=owner).json()
    assert revoked["consent_id"] is None
    assert revoked["categories"] == []
    assert revoked["authorization_version"] > stale["authorization_version"]
    assert api.client.get(PATH + "/changes", headers=owner).status_code == 403
    assert save(api, owner, stale, ["花生"]).status_code == 403
    # Replayed/older/future grants must never authorize, even after time passes.
    consent(api, owner, **grant)
    consent(api, owner, occurred_at=(api.clock.now - timedelta(seconds=1)).isoformat())
    future = consent(api, owner, occurred_at=(api.clock.now + timedelta(days=1)).isoformat())
    assert api.client.get(PATH, headers=owner).json()["consent_id"] is None
    api.clock.advance(days=2)
    owner = bearer(api.login("future-withdraw@example.com"))
    consent(api, owner, **future)
    assert api.client.get(PATH, headers=owner).json()["consent_id"] is None
    fresh = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert state["consent_id"] == fresh["id"]
    assert state["categories"] == []
    assert api.client.get(PATH + "/changes", headers=owner).json()["items"] == []
    assert save(api, owner, stale, ["花生"]).status_code == 409
    assert save(api, owner, state, ["蛋类"]).status_code == 200
