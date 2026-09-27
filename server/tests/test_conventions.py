"""全局接口约定：错误格式、请求编号、日志、ID、时间、游标分页。"""

import io
import json
import logging
import uuid
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from gramtree.core.logging import JsonFormatter


def assert_error_shape(resp, status: int, code: str) -> dict:
    assert resp.status_code == status
    error = resp.json()["error"]
    assert set(error) == {"code", "message", "detail", "request_id"}
    assert error["code"] == code
    assert error["message"]
    assert error["request_id"] == resp.headers["X-Request-ID"]
    return error


@pytest.fixture
def access_log() -> Iterator[io.StringIO]:
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    logger = logging.getLogger("gramtree")
    logger.addHandler(handler)
    yield stream
    logger.removeHandler(handler)


def test_not_found_uses_error_format(client: TestClient) -> None:
    error = assert_error_shape(client.get(f"/v1/examples/samples/{uuid.uuid4()}"), 404, "not_found")
    assert "不存在" in error["detail"]


def test_unknown_route_uses_error_format(client: TestClient) -> None:
    assert_error_shape(client.get("/v1/nope"), 404, "not_found")


def test_non_v4_id_rejected(client: TestClient) -> None:
    assert_error_shape(client.get(f"/v1/examples/samples/{uuid.uuid1()}"), 422, "invalid_request")
    assert_error_shape(client.get("/v1/examples/samples/123"), 422, "invalid_request")


def test_unhandled_error_uses_error_format_and_is_logged(
    client: TestClient, access_log: io.StringIO
) -> None:
    error = assert_error_shape(client.get("/v1/examples/boom"), 500, "internal_error")
    lines = [json.loads(line) for line in access_log.getvalue().splitlines()]
    mine = [line for line in lines if line.get("request_id") == error["request_id"]]
    assert any(line["msg"] == "unhandled error" for line in mine)
    assert any(line["msg"] == "request" and line["status"] == 500 for line in mine)


def test_request_id_is_echoed_and_logged(client: TestClient, access_log: io.StringIO) -> None:
    rid = str(uuid.uuid4())
    resp = client.get("/v1/health", headers={"X-Request-ID": rid})
    assert resp.headers["X-Request-ID"] == rid
    lines = [json.loads(line) for line in access_log.getvalue().splitlines()]
    entry = next(line for line in lines if line.get("request_id") == rid)
    assert entry["path"] == "/v1/health"
    assert entry["status"] == 200
    assert "duration_ms" in entry


def test_bad_request_id_is_replaced(client: TestClient) -> None:
    resp = client.get("/v1/health", headers={"X-Request-ID": "not-a-uuid"})
    assert uuid.UUID(resp.headers["X-Request-ID"]).version == 4


def test_client_generated_id_is_deduplicated_and_time_has_timezone(client: TestClient) -> None:
    sample_id = str(uuid.uuid4())
    first = client.put("/v1/examples/samples", json={"id": sample_id, "title": "番茄炒蛋"})
    assert first.status_code == 201
    again = client.put("/v1/examples/samples", json={"id": sample_id, "title": "改了标题"})
    assert again.status_code == 200
    assert again.json() == first.json()
    assert first.json()["created_at"].endswith("+00:00")
    assert client.get(f"/v1/examples/samples/{sample_id}").json()["title"] == "番茄炒蛋"


def test_cursor_pagination_walks_all_items(client: TestClient) -> None:
    ids = {str(uuid.uuid4()) for _ in range(5)}
    for i, sample_id in enumerate(sorted(ids)):
        client.put("/v1/examples/samples", json={"id": sample_id, "title": f"第{i}道"})
    seen: list[str] = []
    cursor = None
    while True:
        params: dict[str, str | int] = {"limit": 2}
        if cursor:
            params["cursor"] = cursor
        page = client.get("/v1/examples/samples", params=params).json()
        assert len(page["items"]) <= 2
        seen += [item["id"] for item in page["items"]]
        cursor = page["next_cursor"]
        if cursor is None:
            break
    assert len(seen) == 5
    assert set(seen) == ids


def test_page_size_limit_follows_server_config(client: TestClient) -> None:
    assert client.get("/v1/examples/samples", params={"limit": 100}).status_code == 200
    assert_error_shape(
        client.get("/v1/examples/samples", params={"limit": 101}), 422, "invalid_request"
    )
    assert cli(["config", "set", "api.page_size_max", "3", "--by", "test", "--reason", "测"]) == 0
    assert_error_shape(
        client.get("/v1/examples/samples", params={"limit": 4}), 422, "invalid_request"
    )


def test_bad_cursor_rejected(client: TestClient) -> None:
    assert_error_shape(
        client.get("/v1/examples/samples", params={"cursor": "garbage"}), 422, "invalid_cursor"
    )


def test_examples_not_mounted_in_prod(database_url: str) -> None:
    from gramtree.main import create_app
    from tests.conftest import make_settings

    with TestClient(create_app(make_settings(env="prod"))) as c:
        assert c.get("/v1/examples/samples").status_code == 404
