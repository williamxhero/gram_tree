"""Positive, boundary and forbidden completion handoffs over HTTP and sync."""

from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from datetime import UTC, datetime, timedelta

import pytest

from tests.accounts_support import Api, bearer, new_uuid
from tests.cooking_completion_support import completed_record_body
from tests.test_recipes import recipe_input
from tests.test_sync_writes import envelope, submit


def _recipe(api: Api, tokens: dict) -> dict:
    body = recipe_input()
    body["snapshot"]["steps"][1]["heat"] = "大火，油面波纹"
    response = api.client.post("/v1/recipes", headers=bearer(tokens), json=body)
    assert response.status_code == 201, response.text
    return response.json()


@pytest.mark.parametrize("view", ["original", "personalized"])
def test_signed_complete_view_is_verified_and_replay_has_one_record(api: Api, view: str) -> None:
    tokens = api.login(f"completion-{view}@example.com")
    recipe = _recipe(api, tokens)
    body = completed_record_body(api, tokens, recipe, view=view)
    response = api.client.post("/v1/records", headers=bearer(tokens), json=body)
    assert response.status_code == 201, response.text
    row = response.json()
    assert row["verification"] == "cooking_mode"
    assert row["source_context"]["server_completed"] is True
    again = api.client.post("/v1/records", headers=bearer(tokens), json=body)
    assert again.status_code == 201, again.text
    assert again.json()["id"] == row["id"]
    assert len(api.client.get("/v1/records", headers=bearer(tokens)).json()["items"]) == 1


@pytest.mark.parametrize(
    "case",
    [
        "missing_step",
        "foreign_step",
        "overlap",
        "duplicate",
        "session",
        "future",
        "reverse",
        "alter_snapshot",
        "bad_receipt",
        "wrong_source",
        "reserved",
        "self_attest",
    ],
)
def test_completion_cannot_forge_or_skip_execution_evidence(api: Api, case: str) -> None:
    tokens = api.login(f"completion-invalid-{case}@example.com")
    recipe = _recipe(api, tokens)
    body = completed_record_body(api, tokens, recipe)
    evidence = body["completion"]
    if case == "missing_step":
        evidence["completed_steps"].pop()
    elif case == "foreign_step":
        evidence["completed_steps"].append("other-version-step")
    elif case == "overlap":
        evidence["skipped_steps"] = [evidence["completed_steps"][0]]
    elif case == "duplicate":
        evidence["completed_steps"].append(evidence["completed_steps"][0])
    elif case == "session":
        evidence["session_id"] = new_uuid()
    elif case == "future":
        evidence["finished_at"] = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
        body["occurred_at"] = evidence["finished_at"]
    elif case == "reverse":
        evidence["started_at"] = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
    elif case == "alter_snapshot":
        body["snapshot"]["detail"]["version"]["snapshot"]["ingredients"][0]["quantity"] += 1
    elif case == "bad_receipt":
        evidence["execution_token"] = "0" * 64
    elif case == "wrong_source":
        body["source"] = "external_cooking"
    elif case == "reserved":
        body["source_context"] = {
            "server_completed": True,
            "executed_snapshot": recipe["version"]["snapshot"],
        }
    else:
        body["verification"] = "cooking_mode"
    response = api.client.post("/v1/records", headers=bearer(tokens), json=body)
    assert response.status_code == 422, response.text
    assert api.client.get("/v1/records", headers=bearer(tokens)).json()["items"] == []
    panel = api.client.get(f"/v1/recipes/{recipe['id']}/publication", headers=bearer(tokens))
    assert panel.status_code == 200, panel.text
    assert panel.json()["state"] == "draft"


def test_receipt_is_scoped_to_executor_even_when_version_is_public(api: Api) -> None:
    author = api.login("completion-executor-author@example.com")
    reader = api.login("completion-executor-reader@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe)
    first = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert first.status_code == 201, first.text
    published = api.client.get(f"/v1/recipes/{recipe['id']}/publication", headers=bearer(author))
    assert published.status_code == 200, published.text
    assert published.json()["state"] == "published", published.text
    readable = api.client.get(f"/v1/recipes/{recipe['id']}", headers=bearer(reader))
    assert readable.status_code == 200, readable.text
    forged = deepcopy(body)
    forged["client_id"] = new_uuid()
    forged["completion"]["session_id"] = forged["client_id"]
    response = api.client.post("/v1/records", headers=bearer(reader), json=forged)
    assert response.status_code == 422, response.text
    assert api.client.get("/v1/records", headers=bearer(reader)).json()["items"] == []


@pytest.mark.parametrize("same_record", [False, True])
def test_concurrent_completion_does_not_deadlock_or_duplicate(api: Api, same_record: bool) -> None:
    author = api.login("completion-concurrent@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe)
    second = deepcopy(body)
    if not same_record:
        second["client_id"] = new_uuid()
        second["completion"]["session_id"] = second["client_id"]
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(
            pool.map(
                lambda value: api.client.post("/v1/records", headers=bearer(author), json=value),
                [body, second],
            )
        )
    assert all(response.status_code == 201 for response in responses), [
        response.text for response in responses
    ]
    records = api.client.get("/v1/records", headers=bearer(author)).json()["items"]
    assert len(records) == (1 if same_record else 2)
    assert {record["verification"] for record in records} == {"cooking_mode"}
    events = api.client.get(
        "/v1/dev/events/count",
        headers=bearer(author),
        params={"event_type": "recipe.version_published"},
    )
    assert events.status_code == 200, events.text
    assert events.json()["count"] == 1


def test_legacy_session_without_receipt_stays_unverified_and_private(api: Api) -> None:
    author = api.login("completion-legacy@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe)
    body.pop("completion")
    body["source_context"] = {
        "completed_steps": [s["id"] for s in recipe["version"]["snapshot"]["steps"]]
    }
    response = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    assert response.json()["verification"] == "unverified"
    assert (
        api.client.get(f"/v1/recipes/{recipe['id']}/publication", headers=bearer(author)).json()[
            "state"
        ]
        == "draft"
    )


def test_offline_completion_uses_same_validation_and_replay_is_idempotent(api: Api) -> None:
    author = api.login("completion-offline@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe)
    write = envelope(
        author["user"]["id"], write_type="cooking_record.create", payload={"record": body}
    )
    first = submit(api, author, write)[0]
    assert first["status"] == "confirmed", first
    assert submit(api, author, write)[0]["status"] == "already_processed"
    records = api.client.get("/v1/records", headers=bearer(author)).json()["items"]
    assert len(records) == 1
    assert records[0]["verification"] == "cooking_mode"
    assert (
        api.client.get(f"/v1/recipes/{recipe['id']}/publication", headers=bearer(author)).json()[
            "state"
        ]
        == "published"
    )


def test_text_adjustments_are_kept_but_do_not_certify_an_arbitrary_derivative(api: Api) -> None:
    author = api.login("completion-text@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe, adjustments=[{"text": "少放一点盐"}])
    response = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    assert response.json()["adjustments"] == [{"text": "少放一点盐"}]
    assert response.json()["source_context"]["derivation_available"] is False


@pytest.mark.parametrize("transport", ["http", "sync"])
def test_same_record_id_cannot_replace_actual_adjustments(api: Api, transport: str) -> None:
    author = api.login(f"completion-reuse-{transport}@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe)
    saved = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert saved.status_code == 201, saved.text
    altered = deepcopy(body)
    altered["adjustments"] = [{"ingredient_id": "chicken", "quantity": 200, "unit": "g"}]
    if transport == "http":
        response = api.client.post("/v1/records", headers=bearer(author), json=altered)
        assert response.status_code == 409, response.text
        assert response.json()["error"]["code"] == "record_id_reused"
    else:
        result = submit(
            api,
            author,
            envelope(
                author["user"]["id"],
                write_type="cooking_record.create",
                payload={"record": altered},
            ),
        )[0]
        assert result["status"] == "failed", result
        assert result["reason_code"] == "record_id_reused", result
    records = api.client.get("/v1/records", headers=bearer(author)).json()["items"]
    assert len(records) == 1
    assert records[0]["adjustments"] == []


@pytest.mark.parametrize(
    "adjustment",
    [
        {"ingredient_id": "foreign", "quantity": 1},
        {"ingredient_id": "chicken", "quantity": -1},
        {"ingredient_id": "chicken", "quantity": True},
        {"ingredient_id": "chicken", "quantity": 1, "unit": "ml"},
        {"step_id": "cook", "fields": {"duration_seconds": -1}},
        {"step_id": "foreign", "fields": {"duration_seconds": 1}},
        {"step_id": "cook", "fields": {"id": "forged"}},
    ],
)
def test_invalid_structured_adjustments_never_create_records(api: Api, adjustment: dict) -> None:
    author = api.login("completion-bad-adjustment@example.com")
    recipe = _recipe(api, author)
    body = completed_record_body(api, author, recipe, adjustments=[adjustment])
    response = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert response.status_code == 422, response.text
    assert api.client.get("/v1/records", headers=bearer(author)).json()["items"] == []


def test_precise_actual_result_preserves_source_ids_and_exact_changes(api: Api) -> None:
    author = api.login("completion-exact-result@example.com")
    recipe = _recipe(api, author)
    adjustments = [
        {"ingredient_id": "chicken", "quantity": 250, "unit": "g"},
        {"step_id": "cook", "fields": {"duration_seconds": 90}},
    ]
    body = completed_record_body(api, author, recipe, adjustments=adjustments)
    body.pop("occurred_at")
    response = api.client.post("/v1/records", headers=bearer(author), json=body)
    assert response.status_code == 201, response.text
    row = response.json()
    context = row["source_context"]
    assert context["derivation_available"] is True
    assert row["occurred_at"] == context["finished_at"]
    result = context["executed_snapshot"]
    assert [item["id"] for item in result["ingredients"]] == ["chicken", "pepper"]
    assert result["ingredients"][0]["quantity"] == 250
    assert result["steps"][1]["duration_seconds"] == 90
    assert row["adjustments"] == adjustments
