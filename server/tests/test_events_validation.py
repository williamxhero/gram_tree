"""SPEC-010.1 票 2：登记表校验、拒收（原因代码）、版本兼容、单批上限配置项。"""

from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.cli import main as cli
from gramtree.events.models import Event
from tests.accounts_support import Api, bearer, new_uuid


def _event(**overrides: object) -> dict:
    body = {
        "id": new_uuid(),
        "event_type": "pipeline.self_check",
        "type_version": 1,
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
            {"id": str(r.id), "type_version": r.type_version, "content": r.content} for r in rows
        ]


# —— 未登记的类型 ——


def test_unknown_event_type_is_rejected(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    bad = _event(event_type="nonexistent.type", content={})
    resp = api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))
    assert resp.status_code == 200
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "unknown_event_type"
    assert _rows(engine) == []


# —— 未登记的版本 / 已停止支持的版本 ——


def test_unregistered_version_of_known_type_is_rejected(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    bad = _event(type_version=999)
    resp = api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "unsupported_version"
    assert _rows(engine) == []


def test_deprecated_version_is_rejected(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    deprecated = _event(event_type="pipeline.retired_demo", type_version=1, content={"ping": "x"})
    resp = api.client.post(
        "/v1/events/upload", json={"events": [deprecated]}, headers=bearer(tokens)
    )
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "unsupported_version"
    assert _rows(engine) == []


# —— 缺字段 / 字段类型不对 ——


def test_missing_required_content_field_is_rejected(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    bad = _event(content={})
    resp = api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "invalid_content"
    assert _rows(engine) == []


def test_wrong_content_field_type_is_rejected(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    bad = _event(content={"ping": {"not": "a string"}})
    resp = api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "invalid_content"
    assert _rows(engine) == []


def test_rejection_reason_never_echoes_event_content(api: Api) -> None:
    tokens = api.login("cook@example.com")
    secret_value = "私密内容不应该出现在拒收原因里-xyz123"
    # ping 要求是字符串，这里故意给错类型触发 invalid_content，同时把敏感值放进去，
    # 校验答复不应该把它带回来
    bad = _event(content={"ping": {"secret": secret_value}})
    resp = api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    reason = result["reason"]
    assert secret_value not in reason["message"]
    assert secret_value not in reason["code"]


# —— 关联 ID 格式不对 ——


def test_invalid_correlation_id_is_rejected_but_batch_continues(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    bad = _event(correlation={"plan_id": "not-a-uuid"})
    good = _event()
    resp = api.client.post(
        "/v1/events/upload", json={"events": [bad, good]}, headers=bearer(tokens)
    )
    assert resp.status_code == 200
    by_id = {r["id"]: r for r in resp.json()["results"]}
    assert by_id[bad["id"]]["status"] == "rejected"
    assert by_id[bad["id"]]["reason"]["code"] == "invalid_correlation_id"
    assert by_id[good["id"]]["status"] == "accepted"
    rows = _rows(engine)
    assert len(rows) == 1
    assert rows[0]["id"] == good["id"]


# —— 版本兼容：旧版本在支持期内仍然接收，按上传时的版本存下 ——


def test_old_and_new_registered_versions_are_both_accepted_and_stored_as_uploaded(
    api: Api, engine: Engine
) -> None:
    tokens = api.login("cook@example.com")
    v1_event = _event(type_version=1, content={"ping": "pong"})
    v2_event = _event(type_version=2, content={"ping": "pong", "note": "extra"})

    resp = api.client.post(
        "/v1/events/upload", json={"events": [v1_event, v2_event]}, headers=bearer(tokens)
    )
    assert resp.status_code == 200
    assert {r["status"] for r in resp.json()["results"]} == {"accepted"}

    rows = {r["id"]: r for r in _rows(engine)}
    assert rows[v1_event["id"]]["type_version"] == 1
    assert rows[v2_event["id"]]["type_version"] == 2


# —— 同一批里合法/不合法的事件混在一起：合法的照常接收 ——


def test_valid_events_in_batch_are_accepted_even_when_others_are_rejected(
    api: Api, engine: Engine
) -> None:
    tokens = api.login("cook@example.com")
    good = _event()
    unknown_type = _event(event_type="nonexistent.type", content={})
    bad_content = _event(content={})
    resp = api.client.post(
        "/v1/events/upload",
        json={"events": [good, unknown_type, bad_content]},
        headers=bearer(tokens),
    )
    assert resp.status_code == 200
    by_id = {r["id"]: r["status"] for r in resp.json()["results"]}
    assert by_id[good["id"]] == "accepted"
    assert by_id[unknown_type["id"]] == "rejected"
    assert by_id[bad_content["id"]] == "rejected"
    rows = _rows(engine)
    assert len(rows) == 1
    assert rows[0]["id"] == good["id"]


# —— 单批条数/大小上限：配置项，超限整批返回明确错误 ——


def test_batch_over_max_items_is_rejected_with_clear_error(api: Api, engine: Engine) -> None:
    assert cli(["config", "set", "events.upload_max_items", "2", "--by", "t", "--reason", "t"]) == 0
    tokens = api.login("cook@example.com")
    events = [_event() for _ in range(3)]
    resp = api.client.post("/v1/events/upload", json={"events": events}, headers=bearer(tokens))
    assert resp.status_code == 422
    body = resp.json()
    assert body["error"]["code"] == "too_many_events"
    assert _rows(engine) == []


def test_batch_over_max_bytes_is_rejected_with_clear_error(api: Api, engine: Engine) -> None:
    # 配置项本身有下限（1000 字节），所以用允许的最小值，改用一批多条事件把请求体撑过这个下限
    assert (
        cli(["config", "set", "events.upload_max_bytes", "1000", "--by", "t", "--reason", "t"]) == 0
    )
    tokens = api.login("cook@example.com")
    events = [_event() for _ in range(20)]
    resp = api.client.post("/v1/events/upload", json={"events": events}, headers=bearer(tokens))
    assert resp.status_code == 422
    body = resp.json()
    assert body["error"]["code"] == "payload_too_large"
    assert _rows(engine) == []


def test_max_items_config_is_changeable_via_cli(api: Api) -> None:
    assert cli(["config", "set", "events.upload_max_items", "3", "--by", "t", "--reason", "t"]) == 0
    tokens = api.login("cook@example.com")
    events = [_event() for _ in range(3)]
    resp = api.client.post("/v1/events/upload", json={"events": events}, headers=bearer(tokens))
    assert resp.status_code == 200
    assert {r["status"] for r in resp.json()["results"]} == {"accepted"}
