"""Family HTTP journeys plus the ticket-required encrypted-storage/deletion audits."""

import base64
import json
import os
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pydantic import SecretStr
from sqlalchemy import make_url, text
from sqlalchemy.engine import Engine

from gramtree.cli import main as cli
from gramtree.main import create_app
from gramtree.ops import backup
from gramtree.settings import get_settings
from tests.accounts_support import Api, bearer
from tests.conftest import make_settings
from tests.test_account_deletion import _purge, _reauth_email
from tests.test_allergies import consent
from tests.test_allergies import save as save_allergies

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


def test_current_history_and_events_are_encrypted_and_role_bound(
    family_api: Api, engine: Engine, caplog
):
    api = family_api
    owner = bearer(api.login("family-encryption@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    marker = "private-family-cipher-marker"
    first = api.client.post(PATH, headers=owner, json=member_body(state, nickname=marker)).json()
    second = api.client.post(
        PATH, headers=owner, json=member_body(state, nickname="另一位家人")
    ).json()
    history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    first_change = next(row for row in history if row["field"] == "family_members." + first["id"])
    audit = audit_storage(api, owner)
    assert audit["family_current_encrypted"] is True
    assert audit["sensitive_changes_encrypted"] is True
    assert audit["metadata_only"] is True
    with engine.connect() as conn:
        ciphertexts = {
            str(row.id): row.ciphertext
            for row in conn.execute(text("SELECT id,ciphertext FROM family_members"))
        }
        raw_history = list(
            conn.execute(text("SELECT old_value,new_value FROM taste_profile_changes"))
        )
        raw_events = list(conn.execute(text("SELECT content,correlation FROM events")))
    for secret in (marker, "花生", "3_to_6"):
        assert all(secret.encode() not in value for value in ciphertexts.values())
        assert secret not in str(raw_history)
        assert secret not in str(raw_events)
    settings = api.client.app.state.settings
    for key in (None, SecretStr(base64.urlsafe_b64encode(os.urandom(32)).decode())):
        api.client.app.state.settings = settings.model_copy(update={"sensitive_data_key": key})
        assert api.client.get(PATH, headers=owner).status_code == 503
        assert api.client.get(PATH + "/" + first["id"], headers=owner).status_code == 503
        assert api.client.get(PATH + "/changes", headers=owner).status_code == 503
        assert (
            api.client.get(PATH + "/changes/" + first_change["id"], headers=owner).status_code
            == 503
        )
        assert (
            api.client.put(
                PATH + "/" + first["id"], headers=owner, json=member_body(state)
            ).status_code
            == 503
        )
        assert api.client.post(PATH, headers=owner, json=member_body(state)).status_code == 503
        assert save_allergies(api, owner, state, ["蛋类"]).status_code == 503
        audit = audit_storage(api, owner)
        assert audit["family_members"] == 2
        assert audit["family_changes"] == 2
        assert audit["family_current_encrypted"] is False
        assert audit["sensitive_changes_encrypted"] is False
    api.client.app.state.settings = settings
    with engine.begin() as conn:
        # Required storage-audit fixture: a valid ciphertext from a different
        # member must not authenticate, even when its owner and key are correct.
        conn.execute(
            text("UPDATE family_members SET ciphertext=:blob WHERE id=:id"),
            {"blob": ciphertexts[second["id"]], "id": first["id"]},
        )
    assert api.client.get(PATH + "/" + first["id"], headers=owner).status_code == 503
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE family_members SET ciphertext=:blob WHERE id=:id"),
            {"blob": ciphertexts[first["id"]], "id": first["id"]},
        )
        conn.execute(
            text("UPDATE taste_profile_changes SET old_value=CAST(:blob AS jsonb) WHERE id=:id"),
            {
                "blob": json.dumps(
                    {"encrypted": base64.b64encode(ciphertexts[first["id"]]).decode()}
                ),
                "id": first_change["id"],
            },
        )
    assert api.client.get(PATH + "/changes/" + first_change["id"], headers=owner).status_code == 503
    assert audit_storage(api, owner)["sensitive_changes_encrypted"] is False
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE taste_profile_changes SET source=:source WHERE id=:id"),
            {"source": marker, "id": first_change["id"]},
        )
    response = api.client.get(PATH + "/changes/" + first_change["id"], headers=owner)
    assert response.status_code == 500
    assert marker not in response.text
    app_logs = [row for row in caplog.records if row.name.startswith("gramtree")]
    assert marker not in str([row.__dict__ for row in app_logs])
    assert all(row.exc_info is None for row in app_logs)
    # Corrupted storage still erases atomically with no key or plaintext fallback.
    api.client.app.state.settings = settings.model_copy(update={"sensitive_data_key": None})
    consent(api, owner, "withdraw")
    audit = audit_storage(api, owner)
    assert audit["family_members"] == audit["family_changes"] == audit["events"] == 0


def test_withdrawal_erases_all_family_owner_allergies_and_regrant_starts_empty(family_api: Api):
    api = family_api
    owner = bearer(api.login("family-withdraw@example.com"))
    ordinary = api.client.patch(
        "/v1/me/taste-profile",
        headers=owner,
        json={
            "flavors": {"salty": 0.75},
            "ingredient_preferences": [{"category": "蔬菜", "preference": "liked"}],
        },
    ).json()
    grant = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    self_state = api.client.get("/v1/me/taste-profile/allergies", headers=owner).json()
    assert save_allergies(api, owner, self_state, ["蛋类"]).status_code == 200
    first = api.client.post(PATH, headers=owner, json=member_body(state)).json()
    second = api.client.post(
        PATH, headers=owner, json=member_body(state, nickname="老人", age_band="elder")
    ).json()
    version = api.client.get(PATH, headers=owner).json()["profile_version"]
    settings = api.client.app.state.settings
    api.client.app.state.settings = settings.model_copy(update={"sensitive_data_key": None})
    consent(api, owner, "withdraw", occurred_at=(api.clock.now + timedelta(days=365)).isoformat())
    revoked = api.client.get(PATH, headers=owner).json()
    assert revoked["members"] == []
    assert revoked["consent_id"] is None
    assert revoked["authorization_version"] > state["authorization_version"]
    assert revoked["profile_version"] == version + 1
    assert (
        api.client.get("/v1/me/taste-profile/allergies", headers=owner).json()["categories"] == []
    )
    for member in (first, second):
        assert api.client.get(PATH + "/" + member["id"], headers=owner).status_code == 404
        assert (
            api.client.put(
                PATH + "/" + member["id"], headers=owner, json=member_body(state)
            ).status_code
            == 404
        )
    assert api.client.get(PATH + "/changes", headers=owner).status_code == 403
    assert api.client.post(PATH, headers=owner, json=member_body(state)).status_code == 403
    audit = audit_storage(api, owner)
    assert (
        audit["family_members"]
        == audit["family_changes"]
        == audit["owner_allergies"]
        == audit["sensitive_changes"]
        == 0
    )
    assert audit["changes"] == audit["events"] == 2  # ordinary flavor + preference remain
    now_ordinary = api.client.get("/v1/me/taste-profile", headers=owner).json()
    assert now_ordinary["flavors"] == ordinary["flavors"]
    assert now_ordinary["ingredient_preferences"] == ordinary["ingredient_preferences"]
    consent(api, owner, **grant)
    assert api.client.get(PATH, headers=owner).json()["consent_id"] is None
    api.clock.advance(seconds=1)
    fresh = consent(api, owner)
    empty = api.client.get(PATH, headers=owner).json()
    assert empty["consent_id"] == fresh["id"]
    assert empty["members"] == []
    assert api.client.get(PATH + "/changes", headers=owner).json()["items"] == []
    api.client.app.state.settings = settings
    assert api.client.post(PATH, headers=owner, json=member_body(state)).status_code == 409
    created = api.client.post(PATH, headers=owner, json=member_body(empty))
    assert created.status_code == 201, created.text
    assert created.json()["id"] not in {first["id"], second["id"]}


def test_account_deletion_and_purge_clear_family_storage_with_no_key(family_api: Api):
    api = family_api
    email = "family-purge@example.com"
    tokens = api.login(email)
    owner = bearer(tokens)
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert api.client.post(PATH, headers=owner, json=member_body(state)).status_code == 201
    assert (
        save_allergies(
            api,
            owner,
            api.client.get("/v1/me/taste-profile/allergies", headers=owner).json(),
            ["花生"],
        ).status_code
        == 200
    )
    before = audit_storage(api, owner)
    assert before["family_members"] == before["family_changes"] == before["owner_allergies"] == 1
    observer = bearer(api.login("family-purge-observer@example.com", device="observer"))
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"sensitive_data_key": None}
    )
    assert _reauth_email(api, tokens, email) == 204
    result = api.client.post("/v1/me/deletion", headers=owner)
    assert result.status_code == 202, result.text
    assert api.client.get(PATH, headers=owner).status_code == 401
    assert "已删除 1 个" in _purge(result.json()["deletion_due_at"])
    audit = audit_storage(api, observer, owner_id=tokens["user"]["id"])
    assert audit["profiles"] == audit["changes"] == audit["events"] == 0
    assert audit["family_members"] == audit["family_changes"] == audit["owner_allergies"] == 0
    fresh = bearer(api.login(email))
    reopened = api.client.get(PATH, headers=fresh).json()
    assert reopened["consent_id"] is None
    assert reopened["members"] == []


def test_member_delete_erases_large_legacy_links_but_preserves_unrelated_storage(
    family_api: Api, engine: Engine
):
    api = family_api
    owner = bearer(api.login("family-capacity@example.com"))
    assert (
        api.client.patch(
            "/v1/me/taste-profile", headers=owner, json={"flavors": {"salty": 0.75}}
        ).status_code
        == 200
    )
    ordinary_id = api.client.get("/v1/me/taste-profile/changes", headers=owner).json()["items"][0][
        "id"
    ]
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    member = api.client.post(PATH, headers=owner, json=member_body(state)).json()
    change_id = api.client.get(PATH + "/changes", headers=owner).json()["items"][0]["id"]
    base = {
        "event_type": "pipeline.self_check",
        "type_version": 1,
        "device_id": "family-capacity",
        "device_time": api.clock.now.isoformat(),
        "app_version": "1.0.0",
        "content": {"ping": "pong"},
    }
    linked = {
        **base,
        "id": str(uuid.uuid4()),
        "correlation": {"taste_profile_change_id": change_id},
    }
    response = api.client.post("/v1/events/upload", headers=owner, json={"events": [linked]})
    assert response.json()["results"][0]["status"] == "accepted"
    malformed = [
        {"taste_profile_change_id": {"nested": change_id}},
        {"taste_profile_change_id": 12345678123441238123123456789012},
        ["not-an-object"],
        {"taste_profile_change_id": ordinary_id.upper()},
    ]
    retained = {}
    for correlation in malformed:
        event = {**base, "device_id": "family-retained", "id": str(uuid.uuid4())}
        uploaded = api.client.post("/v1/events/upload", headers=owner, json={"events": [event]})
        assert uploaded.json()["results"][0]["status"] == "accepted"
        retained[event["id"]] = correlation
    other = bearer(api.login("family-capacity-other@example.com", device="other"))
    other_event = {**base, "device_id": "family-other-retained", "id": str(uuid.uuid4())}
    assert (
        api.client.post("/v1/events/upload", headers=other, json={"events": [other_event]}).json()[
            "results"
        ][0]["status"]
        == "accepted"
    )
    with engine.begin() as conn:
        # Ticket-authorized legacy audit fixture: many historical accepted
        # batches, noncanonical UUIDs, malformed JSON, and another owner's link.
        conn.execute(
            text(
                "INSERT INTO events (id,user_id,event_type,type_version,device_id,device_time,"
                "app_version,correlation,content,content_fingerprint,received_at,"
            "device_time_suspicious) "
                "SELECT gen_random_uuid(),user_id,event_type,type_version,device_id,device_time,"
                "app_version,CAST(:correlation AS jsonb),content,content_fingerprint,received_at,"
                "device_time_suspicious FROM events CROSS JOIN generate_series(1,65536) "
            "WHERE id=:id"
            ),
            {
                "id": linked["id"],
                "correlation": json.dumps(
                    {"taste_profile_change_id": "{{" + change_id.upper() + "}}"}
                ),
            },
        )
        for event_id, correlation in retained.items():
            conn.execute(
                text("UPDATE events SET correlation=CAST(:value AS jsonb) WHERE id=:id"),
                {"id": event_id, "value": json.dumps(correlation)},
            )
        conn.execute(
            text("UPDATE events SET correlation=CAST(:value AS jsonb) WHERE id=:id"),
            {
                "id": other_event["id"],
                "value": json.dumps({"taste_profile_change_id": change_id.upper()}),
            },
        )
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"sensitive_data_key": None}
    )
    assert api.client.delete(PATH + "/" + member["id"], headers=owner).status_code == 204
    audit = audit_storage(api, owner)
    assert audit["family_members"] == 0
    assert audit["family_changes"] == 1  # target-free deletion receipt
    assert audit["events"] == len(retained) + 2  # ordinary event + receipt + malformed/unrelated
    assert audit_storage(api, other)["events"] == 1
    with engine.connect() as conn:
        assert (
            conn.scalar(text("SELECT count(*) FROM events WHERE device_id='family-capacity'")) == 0
        )
        rows = conn.execute(
            text("SELECT id,correlation FROM events WHERE device_id='family-retained'")
        )
        assert {str(row.id): row.correlation for row in rows} == retained


@pytest.mark.parametrize("action", ["withdraw", "delete"])
def test_concurrent_family_write_and_erasure_leave_no_identifiable_residue(
    family_api: Api, action: str
):
    api = family_api
    owner = bearer(api.login("family-race@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    member = api.client.post(PATH, headers=owner, json=member_body(state)).json()
    api.clock.advance(seconds=1)
    with ThreadPoolExecutor(max_workers=2) as pool:
        write = pool.submit(
            api.client.put,
            PATH + "/" + member["id"],
            headers=owner,
            json=member_body(state, nickname="修改后的孩子"),
        )
        erasure = (
            pool.submit(consent, api, owner, "withdraw")
            if action == "withdraw"
            else pool.submit(api.client.delete, PATH + "/" + member["id"], headers=owner)
        )
        assert write.result().status_code in (200, 403, 404, 409)
        erased = erasure.result()
        if action == "delete":
            assert isinstance(erased, Response)
            assert erased.status_code == 204, erased.text
    assert api.client.get(PATH, headers=owner).json()["members"] == []
    assert api.client.get(PATH + "/" + member["id"], headers=owner).status_code == 404
    audit = audit_storage(api, owner)
    assert audit["family_members"] == audit["sensitive_changes"] == 0
    assert audit["family_changes"] == (1 if action == "delete" else 0)
    if action == "withdraw":
        assert audit["events"] == 0
    else:
        history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
        assert len(history) == 1
        assert history[0]["field"] == "family_members"
        assert "修改后的孩子" not in str(history)


@pytest.mark.skipif(not backup.tools_available(), reason="需要 pg_dump/pg_restore")
def test_public_backup_restore_erases_family_and_does_not_revive_stale_consent(
    family_api: Api, database_url: str, tmp_path: Path, monkeypatch
):
    api = family_api
    owner = bearer(api.login("family-restore@example.com"))
    assert (
        api.client.patch(
            "/v1/me/taste-profile", headers=owner, json={"flavors": {"salty": 0.75}}
        ).status_code
        == 200
    )
    grant = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert api.client.post(PATH, headers=owner, json=member_body(state)).status_code == 201
    assert save_allergies(api, owner, state, ["花生"]).status_code == 200
    monkeypatch.setenv("GRAMTREE_BACKUP_DIR", str(tmp_path))
    monkeypatch.setenv("GRAMTREE_BACKUP_REMOTE", "")
    get_settings.cache_clear()
    try:
        assert cli(["backup", "run"]) == 0
        dumps = list(tmp_path.glob("gramtree-*.dump"))
        assert len(dumps) == 1
        consent(api, owner, "withdraw")
        target = (
            make_url(database_url)
            .set(database="gramtree_t154_family_restore")
            .render_as_string(hide_password=False)
        )
        assert cli(["backup", "restore", str(dumps[0]), "--to", target]) == 0
        with TestClient(
            create_app(
                make_settings(
                    database_url=target,
                    sensitive_data_key=api.client.app.state.settings.sensitive_data_key,
                )
            ),
            raise_server_exceptions=False,
        ) as restored:
            response = restored.get(PATH, headers=owner)
            assert response.status_code == 200, response.text
            assert response.json()["members"] == []
            assert response.json()["consent_id"] is None
            assert restored.get(PATH + "/changes", headers=owner).status_code == 403
            assert restored.post(PATH, headers=owner, json=member_body(state)).status_code == 403
            assert (
                restored.get("/v1/me/taste-profile/allergies", headers=owner).json()["categories"]
                == []
            )
            assert (
                restored.get("/v1/me/taste-profile", headers=owner).json()["flavors"]["salty"][
                    "coefficient"
                ]
                == 0.75
            )
            replay = restored.post("/v1/me/consents", headers=owner, json={"records": [grant]})
            assert replay.status_code == 204
            assert restored.get(PATH, headers=owner).json()["consent_id"] is None
            audit = restored.get(
                "/v1/dev/events/taste-profile-storage",
                headers=owner,
                params={"include_sensitive": "true"},
            ).json()
            assert (
                audit["family_members"] == audit["family_changes"] == audit["owner_allergies"] == 0
            )
            assert audit["changes"] == audit["events"] == 1
    finally:
        get_settings.cache_clear()


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
