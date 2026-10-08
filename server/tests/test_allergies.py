"""Sensitive owner HTTP journeys; DB/log audits are explicitly required by #151."""

import base64
import json
import os
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import make_url, text
from sqlalchemy.engine import Engine

from gramtree.cli import main as cli
from gramtree.main import create_app
from gramtree.ops import backup
from tests.accounts_support import Api, bearer
from tests.conftest import make_settings
from tests.test_account_deletion import _reauth_email

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
        "id": str(uuid.uuid4()),
        "kind": "sensitive_personal_info",
        "version": "allergies-v1",
        "action": action,
        "occurred_at": api.clock.now.isoformat(),
        **changes,
    }
    result = api.client.post(CONSENTS, headers=owner, json={"records": [record]})
    assert result.status_code == 204, result.text
    return record


def save(api: Api, owner: dict[str, str], state: dict, categories: list[str], ingredients=None):
    return api.client.put(
        PATH,
        headers=owner,
        json={
            "consent_id": state["consent_id"],
            "authorization_version": state["authorization_version"],
            "categories": categories,
            "ingredient_ids": ingredients or [],
        },
    )


def test_explicit_sensitive_grant_is_required_and_manual_changes_are_private(sensitive_api: Api):
    api = sensitive_api
    owner = bearer(api.login("allergy-owner@example.com"))
    denied = api.client.put(
        PATH,
        headers=owner,
        json={
            "consent_id": str(uuid.uuid4()),
            "authorization_version": 0,
            "categories": ["花生"],
            "ingredient_ids": [],
        },
    )
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


def test_deletion_erases_sensitive_copies_immediately_without_key(
    sensitive_api: Api, engine: Engine
):
    api = sensitive_api
    tokens = api.login("allergy-delete@example.com")
    owner = bearer(tokens)
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert save(api, owner, state, ["花生"]).status_code == 200
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"sensitive_data_key": None}
    )
    assert _reauth_email(api, tokens, "allergy-delete@example.com") == 204
    deletion = api.client.post("/v1/me/deletion", headers=owner)
    assert deletion.status_code == 202, deletion.text
    with engine.connect() as conn:
        assert conn.scalar(text("SELECT count(*) FROM owner_allergies")) == 0
        assert (
            conn.scalar(text("SELECT count(*) FROM taste_profile_changes WHERE field='allergies'"))
            == 0
        )
        assert (
            conn.scalar(
                text("SELECT count(*) FROM events WHERE correlation ? 'taste_profile_change_id'")
            )
            == 0
        )
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


def test_sensitive_validation_never_echoes_values_or_unknown_keys(sensitive_api: Api, caplog):
    api = sensitive_api
    owner = bearer(api.login("private-errors@example.com"))
    secret = "private-health-marker-DO-NOT-LOG"
    for path, method, payload in (
        (PATH, "put", {secret: secret}),
        ("/v1/me/taste-profile", "patch", {secret: secret}),
        (CONSENTS, "post", {"records": [{"kind": secret}]}),
        (PATH + "/changes/" + secret, "get", None),
    ):
        response = getattr(api.client, method)(
            path, headers=owner, **({"json": payload} if payload else {})
        )
        assert response.status_code == 422
        assert secret not in response.text
        assert secret not in str(
            [record.__dict__ for record in caplog.records if record.name.startswith("gramtree")]
        )


def test_consent_idempotence_rejects_mutation_and_cross_account_id_collision(sensitive_api: Api):
    api = sensitive_api
    owner = bearer(api.login("idempotent-allergy@example.com"))
    record = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    consent(api, owner, **record)
    assert api.client.get(PATH, headers=owner).json() == state
    for headers, altered in (
        (owner, {**record, "action": "withdraw"}),
        (bearer(api.login("collision-allergy@example.com", device="other")), record),
    ):
        result = api.client.post(CONSENTS, headers=headers, json={"records": [altered]})
        assert result.status_code == 409, result.text
    assert api.client.get(PATH, headers=owner).json()["consent_id"] == record["id"]


def test_encrypted_current_history_and_metadata_fail_closed_then_keyless_withdraw(
    sensitive_api: Api, engine: Engine, caplog
):
    api = sensitive_api
    assert cli(["ingredients", "import", str(Path(__file__).parent / "data" / "ingredients")]) == 0
    owner = bearer(api.login("encrypted-allergies@example.com"))
    ordinary = api.client.patch(
        "/v1/me/taste-profile", headers=owner, json={"flavors": {"salty": 0.75}}
    ).json()
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    ingredient = api.client.post("/v1/ingredients/search", json={"query": "测试酱油"}).json()[
        "items"
    ][0]
    saved = save(api, owner, state, ["花生"], [ingredient["id"]])
    assert saved.status_code == 200, saved.text
    assert saved.json()["ingredients"] == [
        {"ingredient_id": ingredient["id"], "name": ingredient["standard_name"]}
    ]
    history = api.client.get(PATH + "/changes", headers=owner).json()["items"]
    assert api.client.get(PATH + "/changes/" + history[0]["id"], headers=owner).json() == history[0]
    assert save(api, owner, state, ["花生"], [ingredient["id"]]).json() == saved.json()
    assert save(api, owner, state, ["自造过敏原"]).status_code == 422
    assert save(api, owner, state, [], [str(uuid.uuid4())]).status_code == 422
    with engine.connect() as conn:
        ciphertext = conn.scalar(text("SELECT ciphertext FROM owner_allergies"))
        raw_history = conn.execute(
            text("SELECT old_value,new_value FROM taste_profile_changes WHERE field='allergies'")
        ).one()
        events = conn.execute(
            text("SELECT content,correlation FROM events WHERE id=:id"), {"id": history[0]["id"]}
        ).one()
    for secret in ("花生", ingredient["id"], ingredient["standard_name"]):
        assert secret.encode() not in ciphertext
        assert secret not in str(raw_history)
        assert secret not in str(events)
        assert secret not in str(
            [r.__dict__ for r in caplog.records if r.name.startswith("gramtree")]
        )
    assert events.content == {}
    original_settings = api.client.app.state.settings
    for key in (None, SecretStr(base64.urlsafe_b64encode(os.urandom(32)).decode())):
        api.client.app.state.settings = original_settings.model_copy(
            update={"sensitive_data_key": key}
        )
        assert api.client.get(PATH, headers=owner).status_code == 503
        assert api.client.get(PATH + "/changes", headers=owner).status_code == 503
        assert save(api, owner, state, []).status_code == 503
        with engine.connect() as conn:
            assert conn.scalar(text("SELECT ciphertext FROM owner_allergies")) == ciphertext
    api.client.app.state.settings = original_settings
    # Authenticated data binds storage role and change identity: current ciphertext
    # copied into encrypted history must not be readable as a change.
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE taste_profile_changes SET old_value=:blob WHERE field='allergies'"),
            {"blob": json.dumps({"encrypted": base64.b64encode(ciphertext).decode()})},
        )
    assert api.client.get(PATH + "/changes", headers=owner).status_code == 503
    api.client.app.state.settings = original_settings.model_copy(
        update={"sensitive_data_key": None}
    )
    api.clock.advance(seconds=1)
    consent(api, owner, "withdraw")
    assert api.client.get(PATH, headers=owner).json()["categories"] == []
    with engine.connect() as conn:
        assert conn.scalar(text("SELECT count(*) FROM owner_allergies")) == 0
        assert (
            conn.scalar(text("SELECT count(*) FROM taste_profile_changes WHERE field='allergies'"))
            == 0
        )
        assert (
            conn.scalar(text("SELECT count(*) FROM events WHERE id=:id"), {"id": history[0]["id"]})
            == 0
        )
    assert (
        api.client.get("/v1/me/taste-profile", headers=owner).json()["flavors"]
        == ordinary["flavors"]
    )
    assert len(api.client.get("/v1/me/taste-profile/changes", headers=owner).json()["items"]) == 1


def test_private_unhandled_validation_traceback_is_not_logged(
    sensitive_api: Api, engine: Engine, caplog
):
    api = sensitive_api
    owner = bearer(api.login("private-traceback@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert save(api, owner, state, ["花生"]).status_code == 200
    marker = "private-health-do-not-report"
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE taste_profile_changes SET source=:source WHERE field='allergies'"),
            {"source": marker},
        )
    response = api.client.get(PATH + "/changes", headers=owner)
    assert response.status_code == 500
    assert marker not in response.text
    app_logs = [r for r in caplog.records if r.name.startswith("gramtree")]
    assert marker not in str([r.__dict__ for r in app_logs])
    assert all(r.exc_info is None for r in app_logs)


@pytest.mark.parametrize("reverse", [False, True])
def test_batch_ties_and_out_of_order_uploads_do_not_revive_sensitive_values(
    sensitive_api: Api, reverse: bool
):
    api = sensitive_api
    owner = bearer(api.login("batch-sensitive@example.com"))
    grant = consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert save(api, owner, state, ["花生"]).status_code == 200
    api.clock.advance(seconds=2)
    withdraw = {
        **grant,
        "id": str(uuid.uuid4()),
        "action": "withdraw",
        "occurred_at": api.clock.now.isoformat(),
    }
    fresh = {**withdraw, "id": str(uuid.uuid4()), "action": "agree"}
    records = [grant, withdraw, fresh]
    result = api.client.post(
        CONSENTS, headers=owner, json={"records": records[::-1] if reverse else records}
    )
    assert result.status_code == 204
    assert api.client.get(PATH, headers=owner).json()["consent_id"] is None
    assert api.client.get(PATH, headers=owner).json()["categories"] == []
    api.clock.advance(seconds=1)
    new = consent(api, owner)
    current = api.client.get(PATH, headers=owner).json()
    assert current["consent_id"] == new["id"]
    assert current["categories"] == []
    assert api.client.get(PATH + "/changes", headers=owner).json()["items"] == []
    assert save(api, owner, state, ["花生"]).status_code == 409


@pytest.mark.skipif(not backup.tools_available(), reason="需要 pg_dump/pg_restore")
def test_backup_restore_does_not_resurrect_withdrawn_sensitive_authorization(
    sensitive_api: Api, database_url: str, tmp_path: Path
):
    api = sensitive_api
    owner = bearer(api.login("restore-sensitive@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    assert save(api, owner, state, ["花生"]).status_code == 200
    # Restore ONLY to a dedicated isolated target. The live test database is
    # deliberately never overwritten. pg_dump is the public backup boundary.
    dump = backup.run_backup(database_url, tmp_path)
    consent(api, owner, "withdraw")
    target = (
        make_url(database_url)
        .set(database="gramtree_t151_restore")
        .render_as_string(hide_password=False)
    )
    assert cli(["backup", "restore", str(dump), "--to", target]) == 0
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
        assert response.json()["consent_id"] is None
        assert response.json()["categories"] == []
        assert restored.get(PATH + "/changes", headers=owner).status_code == 403
        # Trigger recomputation via an ordinary consent upload; restored old grants
        # must not become active again.
        result = restored.post(
            CONSENTS,
            headers=owner,
            json={
                "records": [
                    {
                        "id": str(uuid.uuid4()),
                        "kind": "privacy",
                        "action": "agree",
                        "version": "v1",
                        "occurred_at": api.clock.now.isoformat(),
                    }
                ]
            },
        )
        assert result.status_code == 204
        assert restored.get(PATH, headers=owner).json()["consent_id"] is None


def test_concurrent_write_and_withdraw_serialize_with_no_sensitive_residue(
    sensitive_api: Api, engine: Engine
):
    api = sensitive_api
    owner = bearer(api.login("concurrent-sensitive@example.com"))
    consent(api, owner)
    state = api.client.get(PATH, headers=owner).json()
    api.clock.advance(seconds=1)
    with ThreadPoolExecutor(max_workers=2) as pool:
        write = pool.submit(save, api, owner, state, ["花生"])
        withdrawal = pool.submit(consent, api, owner, "withdraw")
        assert write.result().status_code in (200, 403)
        withdrawal.result()
    assert api.client.get(PATH, headers=owner).json()["consent_id"] is None
    assert api.client.get(PATH, headers=owner).json()["categories"] == []
    with engine.connect() as conn:
        assert conn.scalar(text("SELECT count(*) FROM owner_allergies")) == 0
        assert (
            conn.scalar(text("SELECT count(*) FROM taste_profile_changes WHERE field='allergies'"))
            == 0
        )
        assert (
            conn.scalar(
                text("SELECT count(*) FROM events WHERE correlation ? 'taste_profile_change_id'")
            )
            == 0
        )
