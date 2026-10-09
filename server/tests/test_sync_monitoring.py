"""Sync uploads observed via HTTP and the existing operator monitoring task."""

import json
from dataclasses import replace

import pytest

from gramtree.events.sync_contract import WriteApplication, WriteConflict
from gramtree.events.sync_registry import REGISTERED_WRITES
from gramtree.tasks.jobs import check_events_alerts
from tests.accounts_support import Api
from tests.test_sync_writes import envelope, submit


def test_replayed_content_counts_attempts_but_only_one_terminal_outcome(api: Api) -> None:
    tokens = api.login("sync-metrics@example.com")
    accepted = envelope(tokens["user"]["id"])
    rejected = envelope(tokens["user"]["id"], write_type="private-arbitrary-type")
    for _ in range(2):
        submit(api, tokens, accepted, rejected)
    stats = check_events_alerts.apply().get()["sync"]
    assert stats["attempt_count"] == 4
    assert stats["outcome_count"] == 2
    assert stats["failed_count"] == 1
    assert stats["conflict_count"] == 0
    assert {row["write_type"] for row in stats["attempts"]} == {"experience.event", "other"}
    serialized = json.dumps(stats)
    for private in [
        tokens["access_token"],
        tokens["user"]["id"],
        accepted["write_id"],
        rejected["write_id"],
        "private-arbitrary-type",
        "offline-device",
    ]:
        assert private not in serialized


def test_replayed_conflict_is_one_content_outcome_with_safe_reason_distribution(
    api: Api, monkeypatch: pytest.MonkeyPatch
) -> None:
    def conflicting(*args: object) -> WriteApplication:
        raise WriteConflict(
            {"local": {"recipe": "private-local-copy"}, "server": {"recipe": "private-server-copy"}}
        )

    spec = REGISTERED_WRITES["experience.event"]
    monkeypatch.setitem(REGISTERED_WRITES, "experience.event", replace(spec, apply=conflicting))
    tokens = api.login("sync-conflict-metrics@example.com")
    write = envelope(tokens["user"]["id"])
    for _ in range(2):
        assert submit(api, tokens, write)[0]["status"] == "conflict"
    stats = check_events_alerts.apply().get()["sync"]
    assert stats["attempt_count"] == 2
    assert stats["outcome_count"] == 1
    assert stats["conflict_count"] == 1
    assert stats["outcomes"] == [
        {"write_type": "experience.event", "status": "conflict", "reason": "conflict", "count": 1}
    ]
    assert "private" not in json.dumps(stats)


def test_dependency_deferrals_are_attempts_not_independent_failed_content(api: Api) -> None:
    tokens = api.login("sync-deferred-metrics@example.com")
    parent = envelope(tokens["user"]["id"])
    child = envelope(tokens["user"]["id"], dependencies=[parent["write_id"]])
    for _ in range(2):
        assert submit(api, tokens, child)[0]["status"] == "deferred"
    stats = check_events_alerts.apply().get()["sync"]
    assert stats["attempt_count"] == 2
    assert stats["outcome_count"] == 0
    assert stats["failed_count"] == 0
    assert stats["attempts"] == [
        {"write_type": "experience.event", "status": "deferred", "reason": "dependency", "count": 2}
    ]
