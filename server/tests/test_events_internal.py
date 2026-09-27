"""SPEC-010.1 票 3：设备时间可疑标记、内部查询（gramtree.events.queries）。"""

import time
import uuid
from datetime import timedelta

import pytest
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.cli import main as cli
from gramtree.core.time import utcnow
from gramtree.events import queries
from gramtree.events.models import Event
from tests.accounts_support import Api, bearer, new_uuid


def _event(**overrides: object) -> dict:
    body = {
        "id": new_uuid(),
        "event_type": "pipeline.self_check",
        "type_version": 1,
        "device_id": "device-1",
        "device_time": utcnow().isoformat(),
        "app_version": "1.0.0",
        "content": {"ping": "pong"},
    }
    body.update(overrides)
    return body


def _upload(api: Api, tokens: dict, *events: dict) -> None:
    resp = api.client.post(
        "/v1/events/upload", json={"events": list(events)}, headers=bearer(tokens)
    )
    assert resp.status_code == 200, resp.text


def _get(engine: Engine, event_id: str) -> Event:
    with Session(engine) as session:
        row = session.get(Event, uuid.UUID(event_id))
        assert row is not None
        session.expunge(row)
        return row


# —— 设备时间可疑标记 ——


def test_device_time_close_to_now_is_not_suspicious(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    event = _event(device_time=utcnow().isoformat())
    _upload(api, tokens, event)
    assert _get(engine, event["id"]).device_time_suspicious is False


def test_device_time_far_from_now_is_suspicious(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    far_past = (utcnow() - timedelta(seconds=100_000)).isoformat()
    event = _event(device_time=far_past)
    _upload(api, tokens, event)
    assert _get(engine, event["id"]).device_time_suspicious is True


def test_device_time_future_beyond_threshold_is_suspicious(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    far_future = (utcnow() + timedelta(seconds=100_000)).isoformat()
    event = _event(device_time=far_future)
    _upload(api, tokens, event)
    assert _get(engine, event["id"]).device_time_suspicious is True


def test_suspicious_threshold_is_configurable(api: Api, engine: Engine) -> None:
    assert (
        cli(
            [
                "config",
                "set",
                "events.device_time_suspicious_threshold_seconds",
                "5",
                "--by",
                "t",
                "--reason",
                "t",
            ]
        )
        == 0
    )
    tokens = api.login("cook@example.com")
    # 10 秒的偏差，超过刚设的 5 秒阈值
    event = _event(device_time=(utcnow() - timedelta(seconds=10)).isoformat())
    _upload(api, tokens, event)
    assert _get(engine, event["id"]).device_time_suspicious is True


# —— 内部查询：按分析用时间排序（上传顺序乱了也能还原先后） ——


def test_query_events_orders_by_device_time_when_not_suspicious_regardless_of_upload_order(
    api: Api, engine: Engine
) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    base = utcnow()
    # 设备时间偏差都在默认阈值（300 秒）以内，都不可疑；故意乱序上传
    middle = _event(device_time=base.isoformat())
    earliest = _event(device_time=(base - timedelta(seconds=100)).isoformat())
    latest = _event(device_time=(base + timedelta(seconds=100)).isoformat())
    _upload(api, tokens, middle)
    _upload(api, tokens, earliest)
    _upload(api, tokens, latest)

    with Session(engine) as session:
        rows = queries.query_events(session, user_id=uuid.UUID(me["id"]))

    assert [str(r.id) for r in rows] == [earliest["id"], middle["id"], latest["id"]]


def test_query_events_suspicious_flag_can_reorder_relative_to_device_time(
    api: Api, engine: Engine
) -> None:
    """反证：把"看起来更早"的可疑事件放在后上传，证明排序确实按 received_at 而不是
    device_time 字面值。"""
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()

    # 先上传一个不可疑事件，device_time 只比"现在"早 10 秒
    normal = _event(device_time=(utcnow() - timedelta(seconds=10)).isoformat())
    _upload(api, tokens, normal)
    time.sleep(0.05)
    # 再上传一个可疑事件，它的 device_time 字面值比 normal 的还早很多（100000 秒前），
    # 但因为可疑，分析用时间改成它的 received_at（比 normal 的 received_at 更晚）
    suspicious = _event(device_time=(utcnow() - timedelta(seconds=100_000)).isoformat())
    _upload(api, tokens, suspicious)

    with Session(engine) as session:
        rows = queries.query_events(session, user_id=uuid.UUID(me["id"]))

    # 如果排序是按 device_time 字面值，suspicious（100000 秒前）会排在 normal（10 秒前）
    # 前面；实际应该是 normal 先，因为 suspicious 改用了更晚的 received_at
    assert [str(r.id) for r in rows] == [normal["id"], suspicious["id"]]


# —— 内部查询：按用户、类型、时间范围、关联 ID 过滤 ——


def test_query_events_only_returns_the_given_users_events(api: Api, engine: Engine) -> None:
    tokens_a = api.login("cook-a@example.com")
    me_a = api.client.get("/v1/me", headers=bearer(tokens_a)).json()
    tokens_b = api.login("cook-b@example.com")
    me_b = api.client.get("/v1/me", headers=bearer(tokens_b)).json()

    event_a = _event()
    event_b = _event()
    _upload(api, tokens_a, event_a)
    _upload(api, tokens_b, event_b)

    with Session(engine) as session:
        rows_a = queries.query_events(session, user_id=uuid.UUID(me_a["id"]))
        rows_b = queries.query_events(session, user_id=uuid.UUID(me_b["id"]))

    assert [str(r.id) for r in rows_a] == [event_a["id"]]
    assert [str(r.id) for r in rows_b] == [event_b["id"]]


def test_query_events_filters_by_type_and_version(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    v1 = _event(type_version=1, content={"ping": "pong"})
    v2 = _event(type_version=2, content={"ping": "pong", "note": "x"})
    _upload(api, tokens, v1, v2)

    with Session(engine) as session:
        only_v1 = queries.query_events(
            session, user_id=uuid.UUID(me["id"]), event_type="pipeline.self_check", version=1
        )
        both = queries.query_events(
            session, user_id=uuid.UUID(me["id"]), event_type="pipeline.self_check"
        )

    assert [str(r.id) for r in only_v1] == [v1["id"]]
    assert {str(r.id) for r in both} == {v1["id"], v2["id"]}


def test_query_events_filters_by_time_range_using_analysis_time(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    base = utcnow()
    early = _event(device_time=(base - timedelta(seconds=100)).isoformat())
    late = _event(device_time=(base + timedelta(seconds=100)).isoformat())
    _upload(api, tokens, early, late)

    with Session(engine) as session:
        since_now = queries.query_events(session, user_id=uuid.UUID(me["id"]), since=base)

    assert [str(r.id) for r in since_now] == [late["id"]]


def test_query_events_filters_by_correlation_id(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    plan_id = new_uuid()
    with_plan = _event(correlation={"plan_id": plan_id})
    without_plan = _event()
    _upload(api, tokens, with_plan, without_plan)

    with Session(engine) as session:
        matched = queries.query_events(
            session,
            user_id=uuid.UUID(me["id"]),
            correlation_field="plan_id",
            correlation_value=plan_id,
        )

    assert [str(r.id) for r in matched] == [with_plan["id"]]


def test_query_events_requires_both_correlation_args_or_neither(engine: Engine) -> None:
    with Session(engine) as session, pytest.raises(ValueError):
        queries.query_events(
            session, user_id=uuid.uuid4(), correlation_field="plan_id", correlation_value=None
        )


# —— 内部查询没有对应的对外路由 ——


def test_queries_module_does_not_define_a_router() -> None:
    assert not hasattr(queries, "router")
