import json
import uuid
from typing import Any

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input


def _read_logs(capsys, request_id: str) -> list[dict[str, Any]]:
    assert cli(["access-logs", "list", "--request-id", request_id]) == 0
    return json.loads(capsys.readouterr().out)


def test_denied_unmatched_request_logs_status_without_request_secrets(
    client: TestClient, capsys
) -> None:
    request_id = str(uuid.uuid4())
    secret = "do-not-log-this-value"
    response = client.post(
        "/v1/private/arbitrary-user-segment?access_token=" + secret,
        headers={
            "X-Request-ID": request_id,
            "Authorization": f"Bearer {secret}",
            "X-Device-ID": "device-test-1",
        },
        json={"private_snapshot": secret},
    )

    assert response.status_code == 404
    rows = _read_logs(capsys, request_id)
    assert len(rows) == 1
    row = rows[0]
    assert row["endpoint"] == "/__unmatched__"
    assert row["status_code"] == 404
    assert row["device_id"] == "device-test-1"
    assert secret not in json.dumps(row)


def test_matched_resource_request_logs_route_template_not_identifier(
    client: TestClient, capsys
) -> None:
    request_id = str(uuid.uuid4())
    resource_id = str(uuid.uuid4())
    response = client.get(f"/v1/recipes/{resource_id}", headers={"X-Request-ID": request_id})

    assert response.status_code == 401
    rows = _read_logs(capsys, request_id)
    assert len(rows) == 1
    assert rows[0]["endpoint"] == "/v1/recipes/{recipe_id}"
    assert resource_id in rows[0]["content_ids"]
    assert rows[0]["status_code"] == 401


def test_authenticated_records_identify_content_without_token_or_snapshot(api: Api, capsys) -> None:
    tokens = api.login("access-log@example.com", device="audit-device")
    headers = bearer(tokens)
    request_id = str(uuid.uuid4())
    response = api.client.post(
        "/v1/recipes", headers={**headers, "X-Request-ID": request_id}, json=recipe_input()
    )
    assert response.status_code == 201, response.text
    detail_id = str(uuid.uuid4())
    saved = response.json()
    read = api.client.get(
        f"/v1/recipes/{saved['id']}", headers={**headers, "X-Request-ID": detail_id}
    )
    assert read.status_code == 200
    rows = _read_logs(capsys, detail_id)
    assert rows[0]["account_id"] == tokens["user_id"]
    assert rows[0]["device_id"] == "audit-device"
    assert saved["id"] in rows[0]["content_ids"]
    assert rows[0]["method"] == "GET" and rows[0]["ip_address"]
    assert tokens["access_token"] not in json.dumps(rows)
    assert tokens["request_signing_key"] not in json.dumps(rows)
    assert "鸡腿肉" not in json.dumps(rows, ensure_ascii=False)
    list_id = str(uuid.uuid4())
    assert (
        api.client.get("/v1/recipes", headers={**headers, "X-Request-ID": list_id}).status_code
        == 200
    )
    assert saved["id"] in _read_logs(capsys, list_id)[0]["content_ids"]


def test_access_log_retention_defaults_to_180_days_and_changes_live(
    client: TestClient, capsys
) -> None:
    from datetime import UTC, datetime, timedelta

    assert cli(["config", "get", "ops.access_log_retention_days"]) == 0
    assert json.loads(capsys.readouterr().out) == 180
    request_id = str(uuid.uuid4())
    assert client.get("/v1/health", headers={"X-Request-ID": request_id}).status_code == 200
    now = datetime.now(UTC)
    assert cli(["access-logs", "purge", "--as-of", (now + timedelta(days=179)).isoformat()]) == 0
    capsys.readouterr()
    assert len(_read_logs(capsys, request_id)) == 1
    assert (
        cli(
            [
                "config",
                "set",
                "ops.access_log_retention_days",
                "1",
                "--by",
                "test",
                "--reason",
                "retention",
            ]
        )
        == 0
    )
    capsys.readouterr()
    assert cli(["access-logs", "purge", "--as-of", (now + timedelta(days=2)).isoformat()]) == 0
    capsys.readouterr()
    assert _read_logs(capsys, request_id) == []
