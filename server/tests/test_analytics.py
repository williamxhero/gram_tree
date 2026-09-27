"""产品埋点通道（SPEC-010.1 票 6）：和经验层事件完全分开的独立存储和接口。"""

import uuid
from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy import inspect, select
from sqlalchemy.orm import Session

from gramtree.analytics.models import AnalyticsEvent
from gramtree.cli import main as cli
from gramtree.tasks.jobs import purge_expired_analytics_events
from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape


def _event(event_type: str = "page_view", **kw: object) -> dict[str, object]:
    body: dict[str, object] = {
        "id": str(uuid.uuid4()),
        "event_type": event_type,
        "target": "today",
        "occurred_at": "2026-09-27T12:00:00+08:00",
        "device_id": "device-1",
    }
    body.update(kw)
    return body


def test_anonymous_analytics_event_is_accepted(client: TestClient) -> None:
    resp = client.post("/v1/analytics/events", json={"events": [_event()]})
    assert resp.status_code == 204


def test_logged_in_user_id_is_filled_by_server_not_by_body(api: Api, engine) -> None:
    tokens = api.login("cook@example.com")
    event_id = str(uuid.uuid4())
    resp = api.client.post(
        "/v1/analytics/events",
        json={"events": [_event(id=event_id, user_id="not-a-real-field")]},
        headers=bearer(tokens),
    )
    # 请求体里不允许出现 user_id 这种登记字段之外的内容，直接拒收
    assert resp.status_code == 422

    resp = api.client.post(
        "/v1/analytics/events",
        json={"events": [_event(id=event_id)]},
        headers=bearer(tokens),
    )
    assert resp.status_code == 204
    with Session(engine) as session:
        row = session.get(AnalyticsEvent, uuid.UUID(event_id))
        assert row is not None
        assert row.user_id is not None


def test_rejects_fields_outside_the_registered_schema(client: TestClient) -> None:
    bad = _event()
    bad["recipe_title"] = "番茄炒蛋"  # 菜谱内容之类的字段一律拒收
    error = assert_error_shape(
        client.post("/v1/analytics/events", json={"events": [bad]}), 422, "invalid_request"
    )
    assert error["detail"]


def test_rejects_unknown_event_type(client: TestClient) -> None:
    assert_error_shape(
        client.post("/v1/analytics/events", json={"events": [_event(event_type="something_else")]}),
        422,
        "invalid_request",
    )


def test_duplicate_id_is_not_recorded_twice(client: TestClient, engine) -> None:
    event = _event()
    client.post("/v1/analytics/events", json={"events": [event]})
    client.post("/v1/analytics/events", json={"events": [event]})
    with Session(engine) as session:
        rows = list(
            session.scalars(
                select(AnalyticsEvent).where(AnalyticsEvent.id == uuid.UUID(str(event["id"])))
            )
        )
        assert len(rows) == 1


def test_load_duration_event_carries_duration(client: TestClient, engine) -> None:
    event = _event(event_type="load_duration", target="today", duration_ms=420)
    resp = client.post("/v1/analytics/events", json={"events": [event]})
    assert resp.status_code == 204
    with Session(engine) as session:
        row = session.get(AnalyticsEvent, uuid.UUID(str(event["id"])))
        assert row is not None
        assert row.duration_ms == 420


def test_expired_analytics_events_are_purged_by_background_task(client: TestClient, engine) -> None:
    assert (
        cli(["config", "set", "analytics.retention_days", "1", "--by", "test", "--reason", "测"])
        == 0
    )
    old_id = uuid.uuid4()
    fresh_id = uuid.uuid4()
    now = datetime.now(UTC)
    with Session(engine) as session:
        session.add(
            AnalyticsEvent(
                id=old_id,
                event_type="page_view",
                target="today",
                occurred_at=now - timedelta(days=5),
                received_at=now - timedelta(days=5),
            )
        )
        session.add(
            AnalyticsEvent(
                id=fresh_id,
                event_type="page_view",
                target="today",
                occurred_at=now,
                received_at=now,
            )
        )
        session.commit()

    deleted = purge_expired_analytics_events.apply(args=(now.isoformat(),)).get()
    assert deleted == 1
    with Session(engine) as session:
        assert session.get(AnalyticsEvent, old_id) is None
        assert session.get(AnalyticsEvent, fresh_id) is not None


def test_analytics_storage_is_fully_independent_of_any_experience_event_module(
    engine,
) -> None:
    """埋点表和经验层事件表是完全独立的两张表/两个模块。

    #69/#72 的经验层事件管道在这个 worktree 里还没有实现（该分支是并行开发的），
    所以这里用两种方式确认“分开”：
    1. 静态检查：`gramtree.analytics` 模块源码里没有 import 任何 `gramtree.events` 之类的
       经验层模块（这条独立于 #69 是否已经存在都能跑）。
    2. 数据库层面：`product_analytics_events` 是独立的一张表，字段里没有任何指向
       经验层事件表的外键；写埋点用的是 analytics.service，完全不会碰到别的表。
    """
    from gramtree.analytics import models as analytics_models
    from gramtree.analytics import router as analytics_router
    from gramtree.analytics import service as analytics_service

    for module in (analytics_models, analytics_router, analytics_service):
        imported = {getattr(v, "__module__", "") for v in vars(module).values()}
        assert not any(m.startswith("gramtree.events") for m in imported if m)

    insp = inspect(engine)
    assert "product_analytics_events" in insp.get_table_names()
    fks = insp.get_foreign_keys("product_analytics_events")
    assert fks == []
