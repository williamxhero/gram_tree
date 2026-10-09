"""Field convergence observed through registered HTTP writes and owner history."""

import uuid
from datetime import datetime

import pytest
from pydantic import BaseModel, ConfigDict
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.ids import IdV4
from gramtree.events.field_adjudication import (
    FieldEdit,
    FieldEntity,
    FieldHistory,
    adjudicate,
    lock_entity,
)
from gramtree.events.sync_contract import (
    WriteApplication,
    WriteEnvelope,
    WriteFailure,
    WriteResourceResult,
    WriteTypeSpec,
)
from gramtree.events.sync_registry import REGISTERED_WRITES
from tests.accounts_support import Api, bearer, new_uuid
from tests.test_sync_writes import envelope, submit


def change(tokens, resource, action, fields, time="2026-10-08T10:00:00Z", **kwargs):
    return envelope(
        tokens["user"]["id"],
        write_type="personal_measure.change",
        payload={
            "resource_id": resource,
            "action": action,
            "fields": {key: {"value": value, "device_time": time} for key, value in fields.items()},
        },
        **kwargs,
    )


def test_measure_fields_converge_and_losing_write_has_owner_history(api: Api):
    tokens = api.login("fields@example.com")
    resource = new_uuid()
    create = change(
        tokens, resource, "create", {"name": "小勺", "kind": "spoon", "capacity_ml": 15}
    )
    assert submit(api, tokens, create)[0]["status"] == "confirmed"
    newer = change(tokens, resource, "update", {"name": "大勺"}, "2026-10-08T12:00:00Z")
    older = change(
        tokens, resource, "update", {"name": "旧勺", "capacity_ml": 18}, "2026-10-08T11:00:00Z"
    )
    assert submit(api, tokens, newer)[0]["status"] == "confirmed"
    result = submit(api, tokens, older)[0]
    assert result["result"]["values"]["name"] == "大勺"
    assert result["result"]["values"]["capacity_ml"] == 18
    assert result["result"]["values"]["field_outcomes"] == {"name": "lost", "capacity_ml": "won"}
    row = api.client.get(f"/v1/me/measures/{resource}", headers=bearer(tokens)).json()
    assert (row["name"], row["capacity_ml"]) == ("大勺", 18)
    history = api.client.get(f"/v1/me/measures/{resource}/history", headers=bearer(tokens))
    assert history.status_code == 200, history.text
    assert len(history.json()["items"]) == 6
    assert any(h["new_value"] == "旧勺" and h["outcome"] == "lost" for h in history.json()["items"])
    assert submit(api, tokens, older)[0]["status"] == "already_processed"
    assert (
        len(
            api.client.get(f"/v1/me/measures/{resource}/history", headers=bearer(tokens)).json()[
                "items"
            ]
        )
        == 6
    )
    other = api.login("other-fields@example.com")
    assert (
        api.client.get(f"/v1/me/measures/{resource}/history", headers=bearer(other)).status_code
        == 404
    )


def test_per_field_times_ties_batch_reverse_dependencies_and_tombstone(api: Api):
    tokens = api.login("measure-order@example.com")
    resource = new_uuid()
    creation = change(
        tokens, resource, "create", {"name": "勺", "kind": "spoon", "capacity_ml": 15}
    )
    child = change(
        tokens,
        resource,
        "update",
        {"name": "新勺"},
        "2026-10-08T11:00:00Z",
        dependencies=[creation["write_id"]],
    )
    assert submit(api, tokens, child, creation)[0]["status"] == "deferred"
    assert submit(api, tokens, child)[0]["status"] == "confirmed"
    low = change(
        tokens,
        resource,
        "update",
        {"name": "低 UUID", "capacity_ml": 20},
        "2026-10-08T12:00:00Z",
        write_id="00000000-0000-4000-8000-000000000001",
    )
    high = change(
        tokens,
        resource,
        "update",
        {"name": "高 UUID"},
        "2026-10-08T12:00:00Z",
        write_id="FFFFFFFF-FFFF-4FFF-8FFF-FFFFFFFFFFFF",
    )
    high["payload"]["fields"]["capacity_ml"] = {
        "value": 25,
        "device_time": "2026-10-08T11:30:00+00:00",
    }
    results = submit(api, tokens, high, low)
    assert results[1]["result"]["values"]["name"] == "高 UUID"
    assert results[1]["result"]["values"]["capacity_ml"] == 20
    assert results[1]["result"]["values"]["field_outcomes"] == {
        "name": "lost",
        "capacity_ml": "won",
    }
    deletion = change(tokens, resource, "delete", {"deleted": True}, "2026-10-08T13:00:00Z")
    assert submit(api, tokens, deletion)[0]["result"]["values"]["deleted"] is True
    late = change(tokens, resource, "update", {"name": "不能复活"}, "2026-10-08T14:00:00Z")
    result = submit(api, tokens, late)[0]["result"]["values"]
    assert result["deleted"] is True and result["applied"] is False
    assert result["field_outcomes"] == {"name": "tombstoned"}
    assert api.client.get(f"/v1/me/measures/{resource}", headers=bearer(tokens)).status_code == 404
    assert api.client.get("/v1/me/measures", headers=bearer(tokens)).json()["items"] == []
    assert (
        api.client.get(f"/v1/me/measures/{resource}/history", headers=bearer(tokens)).status_code
        == 200
    )
    recreate = change(
        tokens, resource, "create", {"name": "勺", "kind": "spoon", "capacity_ml": 15}
    )
    assert submit(api, tokens, recreate)[0]["reason_code"] == "resource_already_exists"
    recreate["write_id"], recreate["payload"]["resource_id"] = new_uuid(), new_uuid()
    assert submit(api, tokens, recreate)[0]["status"] == "confirmed"


@pytest.mark.parametrize("bad", [None, 0, 10001, float("inf")])
def test_measure_rejects_invalid_field_values_without_history(api: Api, bad):
    tokens = api.login("invalid-field@example.com")
    resource = new_uuid()
    # Infinity cannot be encoded as JSON, so use its string representation.
    write = change(
        tokens,
        resource,
        "create",
        {"name": "勺", "kind": "spoon", "capacity_ml": "Infinity" if bad == float("inf") else bad},
    )
    assert submit(api, tokens, write)[0]["reason_code"] == "invalid_content"
    assert api.client.get("/v1/me/measures", headers=bearer(tokens)).json()["items"] == []


def test_measure_rejects_naive_time_and_updates_never_create_unknown_identity(api: Api):
    tokens = api.login("missing-measure@example.com")
    write = change(tokens, new_uuid(), "update", {"name": "未知"})
    assert submit(api, tokens, write)[0]["reason_code"] == "reference_not_arrived"
    invalid = change(
        tokens,
        new_uuid(),
        "create",
        {"name": "勺", "kind": "spoon", "capacity_ml": 15},
        "2026-10-08T10:00:00",
    )
    assert submit(api, tokens, invalid)[0]["reason_code"] == "invalid_content"
    assert api.client.get("/v1/me/measures", headers=bearer(tokens)).json()["items"] == []
    invalid_delete = change(tokens, new_uuid(), "delete", {"deleted": 1})
    assert submit(api, tokens, invalid_delete)[0]["reason_code"] == "invalid_content"


class TestFields(BaseModel):
    __test__ = False
    model_config = ConfigDict(extra="forbid")
    resource_id: IdV4
    fields: dict[str, FieldEdit]


@pytest.fixture
def generic_fields(monkeypatch):
    """A second consumer registered only in this test process, with no new route."""
    resource_type = "test.fields"

    def authorize(session: Session, owner: uuid.UUID, payload: BaseModel):
        parsed = TestFields.model_validate(payload)
        row = session.get(FieldEntity, (resource_type, parsed.resource_id))
        if row is not None and row.owner_id != owner:
            raise WriteFailure("reference_forbidden")

    def apply(
        session: Session,
        owner: uuid.UUID,
        envelope: WriteEnvelope,
        payload: BaseModel,
        now: datetime,
    ):
        parsed = TestFields.model_validate(payload)
        lock_entity(session, resource_type, parsed.resource_id)
        session.expire_all()
        authorize(session, owner, parsed)
        entity = session.get(FieldEntity, (resource_type, parsed.resource_id))
        if entity is None:
            entity = FieldEntity(
                resource_type=resource_type,
                resource_id=parsed.resource_id,
                owner_id=owner,
                values={},
                clocks={},
                deleted=False,
            )
            session.add(entity)
        decision = adjudicate(session, entity, envelope.write_id, parsed.fields)
        session.flush()
        history = list(
            session.scalars(
                select(FieldHistory).where(
                    FieldHistory.resource_type == resource_type,
                    FieldHistory.resource_id == parsed.resource_id,
                )
            )
        )
        return WriteApplication(
            result=WriteResourceResult(
                resource_type=resource_type,
                resource_id=parsed.resource_id,
                values={
                    "fields": decision.values,
                    "deleted": decision.deleted,
                    "applied": bool(decision.changes),
                    "outcomes": decision.outcomes,
                    "history": [
                        {
                            "field": row.field,
                            "old_value": row.old_value,
                            "new_value": row.new_value,
                            "outcome": row.outcome,
                            "write_id": str(row.write_id),
                        }
                        for row in history
                    ],
                },
            ),
            facts=[decision.changes] if decision.changes else [],
        )

    monkeypatch.setitem(
        REGISTERED_WRITES,
        "test.fields",
        WriteTypeSpec(
            write_type="test.fields",
            conflict_rule="field_last_write_with_history",
            validate=TestFields.model_validate,
            authorize=authorize,
            resolve_references=lambda session, owner, payload, dependencies: payload,
            apply=apply,
        ),
    )


def test_registered_generic_consumer_converges_nullable_fields_and_preserves_losers(
    api: Api, generic_fields
):
    tokens = api.login("generic-fields@example.com")
    resource = new_uuid()

    def write(fields, time, **extra):
        return envelope(
            tokens["user"]["id"],
            write_type="test.fields",
            payload={
                "resource_id": resource,
                "fields": {
                    key: {"value": value, "device_time": time} for key, value in fields.items()
                },
            },
            **extra,
        )

    initial = write({"checked": False, "note": "原始"}, "2026-10-08T10:00:00Z")
    latest = write({"checked": True}, "2026-10-08T12:00:00Z")
    older = write({"checked": False, "note": None}, "2026-10-08T11:00:00Z")
    assert submit(api, tokens, initial)[0]["status"] == "confirmed"
    assert submit(api, tokens, latest)[0]["result"]["values"]["applied"] is True
    result = submit(api, tokens, older)[0]["result"]["values"]
    assert result["fields"] == {"checked": True, "note": None}
    assert result["outcomes"] == {"checked": "lost", "note": "won"}
    assert len(result["history"]) == 5
    assert submit(api, tokens, older)[0]["status"] == "already_processed"
    unchanged = write({"checked": True}, "2026-10-08T13:00:00Z")
    result = submit(api, tokens, unchanged)[0]["result"]["values"]
    assert result["applied"] is False and result["outcomes"] == {"checked": "unchanged"}
    assert len(result["history"]) == 6
    intruder = api.login("generic-other@example.com")
    stolen = {**unchanged, "write_id": new_uuid(), "owner_id": intruder["user"]["id"]}
    assert submit(api, intruder, stolen)[0]["reason_code"] == "reference_forbidden"
    assert submit(api, intruder, stolen)[0]["result"] is None
    # Explicit null on a previously absent field is a winning creation, not
    # an absent/no-op edit. A terminal entity cannot be restored by this seam.
    null_field = write({"optional": None}, "2026-10-08T14:00:00Z")
    result = submit(api, tokens, null_field)[0]["result"]["values"]
    assert result["applied"] is True and result["outcomes"] == {"optional": "won"}
    tombstone = write({"note": "不得生效", "deleted": True}, "2026-10-08T15:00:00Z")
    result = submit(api, tokens, tombstone)[0]["result"]["values"]
    assert result["deleted"] is True and result["outcomes"] == {
        "deleted": "won",
        "note": "tombstoned",
    }
    restore = write({"deleted": False, "checked": False}, "2026-10-08T16:00:00Z")
    result = submit(api, tokens, restore)[0]["result"]["values"]
    assert result["deleted"] is True and result["applied"] is False
    assert result["outcomes"] == {"deleted": "tombstoned", "checked": "tombstoned"}


def test_concurrent_distinct_fields_preserved_and_replay_no_history_duplicates(api: Api):
    from concurrent.futures import ThreadPoolExecutor

    tokens = api.login("concurrent-measures@example.com")
    resource = new_uuid()
    creation = change(
        tokens, resource, "create", {"name": "勺", "kind": "spoon", "capacity_ml": 15}
    )
    assert submit(api, tokens, creation)[0]["status"] == "confirmed"
    name = change(tokens, resource, "update", {"name": "并发勺"}, "2026-10-08T12:00:00Z")
    capacity = change(tokens, resource, "update", {"capacity_ml": 25}, "2026-10-08T12:00:00Z")
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(
            pool.map(lambda write: submit(api, tokens, write)[0], [name, capacity, name, capacity])
        )
    assert sum(result["status"] == "confirmed" for result in results) == 2
    row = api.client.get(f"/v1/me/measures/{resource}", headers=bearer(tokens)).json()
    assert (row["name"], row["capacity_ml"]) == ("并发勺", 25)
    assert (
        len(
            api.client.get(f"/v1/me/measures/{resource}/history", headers=bearer(tokens)).json()[
                "items"
            ]
        )
        == 5
    )


def test_purge_cleans_measure_tombstone_clocks_history_without_harming_other_owner(api: Api):
    from tests.test_account_deletion import _purge, _reauth_email

    alice = api.login("measure-purge@example.com")
    bob = api.login("measure-keep@example.com")
    resource, kept = new_uuid(), new_uuid()
    values = {"name": "勺", "kind": "spoon", "capacity_ml": 15}
    assert submit(api, alice, change(alice, resource, "create", values))[0]["status"] == "confirmed"
    assert (
        submit(api, alice, change(alice, resource, "delete", {"deleted": True}))[0]["status"]
        == "confirmed"
    )
    assert submit(api, bob, change(bob, kept, "create", values))[0]["status"] == "confirmed"
    assert _reauth_email(api, alice, "measure-purge@example.com") == 204
    deletion = api.client.post("/v1/me/deletion", headers=bearer(alice))
    assert deletion.status_code == 202
    assert "已删除 1 个" in _purge(deletion.json()["deletion_due_at"])
    assert api.client.get(f"/v1/me/measures/{kept}/history", headers=bearer(bob)).status_code == 200
    # Reusing a purged UUID is test evidence of absence, not a restore feature.
    reclaimed = change(bob, resource, "create", {**values, "name": "新身份"})
    result = submit(api, bob, reclaimed)[0]
    assert result["status"] == "confirmed" and result["result"]["values"]["deleted"] is False
    history = api.client.get(f"/v1/me/measures/{resource}/history", headers=bearer(bob)).json()[
        "items"
    ]
    assert len(history) == 3
    assert all(item["write_id"] == reclaimed["write_id"] for item in history)
