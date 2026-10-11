"""Confirmation time is a stable server fact, not the time of a retry."""

from datetime import datetime

from tests.accounts_support import Api
from tests.test_sync_writes import envelope, submit


def test_replay_preserves_actual_server_confirmation_time(api: Api) -> None:
    tokens = api.login("confirmation-time@example.com")
    write = envelope(tokens["user"]["id"])
    first = submit(api, tokens, write)[0]
    assert first["status"] == "confirmed"
    confirmed = datetime.fromisoformat(first["confirmed_at"].replace("Z", "+00:00"))
    assert confirmed.tzinfo is not None
    assert confirmed.year >= 2026
    replay = submit(api, tokens, write)[0]
    assert replay["status"] == "already_processed"
    assert replay["confirmed_at"] == first["confirmed_at"]
    failed = submit(api, tokens, envelope(tokens["user"]["id"], write_type="unknown"))[0]
    assert failed["status"] == "failed"
    assert failed["confirmed_at"] is None
