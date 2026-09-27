"""SPEC-010.1 票 1：登录后批量上传经验层事件，按事件 ID 去重、只追加存储。"""

import json
import threading
import uuid
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.cli import main as cli
from gramtree.events.models import Event
from gramtree.events.registry import BY_KEY, is_registered
from tests.accounts_support import Api, bearer, new_uuid
from tests.test_conventions import assert_error_shape

SELF_CHECK = {"event_type": "pipeline.self_check", "type_version": 1}


def _event(**overrides: object) -> dict:
    body = {
        "id": new_uuid(),
        "event_type": SELF_CHECK["event_type"],
        "type_version": SELF_CHECK["type_version"],
        "device_id": "device-1",
        "device_time": "2026-09-27T10:00:00+08:00",
        "app_version": "1.0.0",
        "content": {"ping": "pong"},
    }
    body.update(overrides)
    return body


def _rows(engine: Engine) -> list[dict]:
    with Session(engine) as session:
        rows = session.query(Event).order_by(Event.received_at).all()
        return [
            {
                "id": r.id,
                "user_id": r.user_id,
                "event_type": r.event_type,
                "type_version": r.type_version,
                "content": r.content,
                "correlation": r.correlation,
                "content_fingerprint": r.content_fingerprint,
            }
            for r in rows
        ]


# —— 登记表骨架 ——


def test_self_check_event_type_is_registered() -> None:
    assert is_registered("pipeline.self_check", 1)
    spec = BY_KEY[("pipeline.self_check", 1)]
    assert spec.exportable is False
    assert not is_registered("pipeline.self_check", 99)


# —— 未登录 ——


def test_upload_without_login_returns_401(client: TestClient) -> None:
    resp = client.post("/v1/events/upload", json={"events": [_event()]})
    error = assert_error_shape(resp, 401, "unauthorized")
    assert error["message"]


# —— 正常上传、落库 ——


def test_upload_batch_is_accepted_and_stored(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    events = [_event() for _ in range(3)]

    resp = api.client.post("/v1/events/upload", json={"events": events}, headers=bearer(tokens))
    assert resp.status_code == 200
    results = resp.json()["results"]
    assert len(results) == 3
    assert {r["status"] for r in results} == {"accepted"}
    assert {r["id"] for r in results} == {e["id"] for e in events}

    rows = _rows(engine)
    assert len(rows) == 3
    assert {str(r["id"]) for r in rows} == {e["id"] for e in events}
    assert all(str(r["user_id"]) == me["id"] for r in rows)


def test_correlation_ids_are_stored_and_optional(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    plan_id = new_uuid()
    event = _event(correlation={"plan_id": plan_id})
    resp = api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    assert resp.status_code == 200
    rows = _rows(engine)
    assert rows[0]["correlation"] == {"plan_id": plan_id}

    other = _event()
    resp = api.client.post("/v1/events/upload", json={"events": [other]}, headers=bearer(tokens))
    assert resp.status_code == 200
    rows = _rows(engine)
    stored = next(r for r in rows if str(r["id"]) == other["id"])
    assert stored["correlation"] == {}


# —— 去重 ——


def test_reupload_same_batch_is_all_duplicate_and_row_count_unchanged(
    api: Api, engine: Engine
) -> None:
    tokens = api.login("cook@example.com")
    events = [_event() for _ in range(3)]
    first = api.client.post("/v1/events/upload", json={"events": events}, headers=bearer(tokens))
    assert {r["status"] for r in first.json()["results"]} == {"accepted"}

    again = api.client.post("/v1/events/upload", json={"events": events}, headers=bearer(tokens))
    assert again.status_code == 200
    assert {r["status"] for r in again.json()["results"]} == {"duplicate"}
    assert len(_rows(engine)) == 3


def test_partial_overlap_only_new_ones_accepted(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    first_batch = [_event() for _ in range(2)]
    api.client.post("/v1/events/upload", json={"events": first_batch}, headers=bearer(tokens))

    new_event = _event()
    mixed = api.client.post(
        "/v1/events/upload",
        json={"events": [first_batch[0], new_event]},
        headers=bearer(tokens),
    )
    by_id = {r["id"]: r["status"] for r in mixed.json()["results"]}
    assert by_id[first_batch[0]["id"]] == "duplicate"
    assert by_id[new_event["id"]] == "accepted"
    assert len(_rows(engine)) == 3


# —— 同一个 ID 内容不同：不改原记录，触发告警 ——


class _Receiver(BaseHTTPRequestHandler):
    received: list[dict] = []  # noqa: RUF012

    def do_POST(self) -> None:
        length = int(self.headers["Content-Length"])
        _Receiver.received.append(json.loads(self.rfile.read(length)))
        self.send_response(200)
        self.end_headers()

    def log_message(self, format: str, *args: object) -> None:
        pass


@pytest.fixture
def webhook() -> Iterator[str]:
    _Receiver.received = []
    server = HTTPServer(("127.0.0.1", 0), _Receiver)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_port}/hook"
    server.shutdown()


def test_same_id_different_content_keeps_original_and_alerts(
    api: Api, engine: Engine, webhook: str
) -> None:
    assert cli(["config", "set", "ops.alert_channel", "webhook", "--by", "t", "--reason", "t"]) == 0
    assert cli(["config", "set", "ops.alert_target", webhook, "--by", "t", "--reason", "t"]) == 0

    tokens = api.login("cook@example.com")
    event_id = new_uuid()
    original = _event(id=event_id, content={"ping": "pong"})
    resp = api.client.post("/v1/events/upload", json={"events": [original]}, headers=bearer(tokens))
    assert resp.json()["results"][0]["status"] == "accepted"

    changed = _event(id=event_id, content={"ping": "changed!"})
    resp = api.client.post("/v1/events/upload", json={"events": [changed]}, headers=bearer(tokens))
    assert resp.status_code == 200
    assert resp.json()["results"][0]["status"] == "duplicate"

    rows = _rows(engine)
    assert len(rows) == 1
    assert rows[0]["content"] == {"ping": "pong"}  # 原记录没被改

    assert len(_Receiver.received) == 1
    assert event_id in _Receiver.received[0]["text"]


def test_same_id_same_content_does_not_alert(api: Api, webhook: str) -> None:
    assert cli(["config", "set", "ops.alert_channel", "webhook", "--by", "t", "--reason", "t"]) == 0
    assert cli(["config", "set", "ops.alert_target", webhook, "--by", "t", "--reason", "t"]) == 0

    tokens = api.login("cook@example.com")
    event = _event()
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    assert _Receiver.received == []


# —— 用户 ID 只认登录状态 ——


def test_user_id_spoofed_in_content_is_ignored(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    someone_else = new_uuid()
    event = _event(content={"ping": "pong", "user_id": someone_else, "note": "冒充别人"})

    resp = api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    assert resp.status_code == 200
    assert resp.json()["results"][0]["status"] == "accepted"

    rows = _rows(engine)
    assert str(rows[0]["user_id"]) == me["id"]
    assert str(rows[0]["user_id"]) != someone_else


# —— 事件表只追加：没有读明细/改/删的对外接口 ——


def _all_routes(app) -> list[tuple[str, tuple[str, ...]]]:
    """递归展开 app.routes，把每条路由解析成完整路径 + 方法集合。

    直接走 app.routes 而不是 OpenAPI схема，这样连 include_in_schema=False（比如
    dev-only 接口）挂的路由也会被查到，不会因为"藏起来不进文档"就漏检。
    """

    def walk(routes, prefix: str) -> list[tuple[str, tuple[str, ...]]]:
        out: list[tuple[str, tuple[str, ...]]] = []
        for r in routes:
            ctx = getattr(r, "include_context", None)
            if ctx is not None:
                out += walk(r.original_router.routes, prefix + (ctx.prefix or ""))
            elif hasattr(r, "path"):
                methods = tuple(sorted(getattr(r, "methods", None) or ()))
                out.append((prefix + r.path, methods))
        return out

    return walk(app.routes, "")


def test_no_public_route_reads_or_mutates_event_details(client: TestClient) -> None:
    event_routes = {
        (path, method)
        for path, methods in _all_routes(client.app)
        if "event" in path
        for method in methods
        if method not in ("HEAD", "OPTIONS")
    }
    assert event_routes == {("/v1/events/upload", "POST")}


def test_uuid_v1_event_id_is_rejected(api: Api) -> None:
    tokens = api.login("cook@example.com")
    bad_event = _event(id=str(uuid.uuid1()))
    resp = api.client.post(
        "/v1/events/upload", json={"events": [bad_event]}, headers=bearer(tokens)
    )
    assert_error_shape(resp, 422, "invalid_request")


def test_empty_batch_rejected(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = api.client.post("/v1/events/upload", json={"events": []}, headers=bearer(tokens))
    assert resp.status_code == 422
