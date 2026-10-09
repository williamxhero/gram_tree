"""Typed producer references use their confirmed version, never the newest one."""

from tests.accounts_support import Api
from tests.test_offline_recipe_sync import create, save_write
from tests.test_sync_writes import count, envelope, submit


def test_event_waits_for_its_recipe_producer_and_reports_exact_version(api: Api) -> None:
    tokens = api.login("typed-recipe-reference@example.com")
    original = create(api, tokens)
    parent = save_write(tokens, original)
    child = envelope(tokens["user"]["id"], dependencies=[parent["write_id"]])
    child["payload"]["recipe_version_write_id"] = parent["write_id"]
    assert submit(api, tokens, child)[0]["status"] == "deferred"
    saved = submit(api, tokens, parent)[0]
    assert saved["status"] == "confirmed"
    delivered = submit(api, tokens, child)[0]
    assert delivered["status"] == "confirmed"
    assert (
        delivered["result"]["values"]["correlation"]["recipe_version_id"]
        == parent["payload"]["candidate_version_id"]
    )
    assert count(api, tokens) == 1
    assert submit(api, tokens, child)[0]["result"] == delivered["result"]
    assert count(api, tokens) == 1
