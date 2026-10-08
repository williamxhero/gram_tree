"""经验层事件的去重和落库逻辑。

- 事件 ID 全局唯一：批量插入用 `ON CONFLICT DO NOTHING`，冲突的一律答复"重复"，不改原记录。
- 同一个 ID 但内容不一样：同样答复"重复"、不改原记录，另外记一条 ERROR 日志并走
  SPEC-013.1 的告警通道（`gramtree.observability.alerts.notify`），每个事件 ID
  一小时内只告警一次，避免同一个 ID 被反复重传时刷爆告警通道。
- 用户 ID 只认调用方传入的登录用户 ID（由路由层从 CurrentAuth 取），这一层根本不从
  事件内容里读 user_id，所以客户端在内容里自报的用户 ID 不可能影响归属。
- 设备时间和服务端接收时间相差超过配置项
  `events.device_time_suspicious_threshold_seconds` 时，落库前把这条事件标记成
  "设备时间可疑"（`Event.device_time_suspicious`）。分析用的时间见
  `Event.analysis_time`（SPEC-010.1 票 3）。
"""

import hashlib
import json
import logging
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Literal

from redis import Redis
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from gramtree.events.models import Event
from gramtree.observability import alerts
from gramtree.runtime_config import service as config_service

# 同一个事件 ID 反复被重传（内容还是不一致）时，同一个 ID 一个窗口内只告警一次，
# 不然一个客户端 bug（或者故意的）循环重传就能把告警通道刷爆。
_CONFLICT_ALERT_THROTTLE_SECONDS = 3600

logger = logging.getLogger("gramtree.events")

UploadStatus = Literal["accepted", "duplicate"]


@dataclass(frozen=True)
class EventInput:
    id: uuid.UUID
    event_type: str
    type_version: int
    device_id: str
    device_time: datetime
    app_version: str
    correlation: dict[str, str]
    content: dict[str, Any]


def _fingerprint(user_id: uuid.UUID, item: EventInput) -> str:
    """内容指纹：同一个事件 ID 再次上传时，用它判断内容是否和原记录一致。

    故意把服务端认定的 user_id 也算进去——同一个事件 ID 被不同用户提交，
    同样属于"内容不同"，不应该悄悄改变归属或被当成普通重复。
    """
    payload = {
        "user_id": str(user_id),
        "event_type": item.event_type,
        "type_version": item.type_version,
        "device_id": item.device_id,
        "device_time": item.device_time.isoformat(),
        "app_version": item.app_version,
        "correlation": item.correlation,
        "content": item.content,
    }
    raw = json.dumps(payload, sort_keys=True, ensure_ascii=False, default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


def upload(
    session: Session,
    redis: Redis,
    user_id: uuid.UUID,
    items: list[EventInput],
    now: datetime,
    *,
    commit: bool = True,
) -> dict[uuid.UUID, UploadStatus]:
    """批量落库，返回每个事件 ID 对应的答复。"""
    if not items:
        return {}

    threshold_seconds = float(
        config_service.get(session, "events.device_time_suspicious_threshold_seconds")
    )
    fingerprints = {item.id: _fingerprint(user_id, item) for item in items}
    rows = [
        {
            "id": item.id,
            "user_id": user_id,
            "event_type": item.event_type,
            "type_version": item.type_version,
            "device_id": item.device_id,
            "device_time": item.device_time,
            "app_version": item.app_version,
            "correlation": item.correlation,
            "content": item.content,
            "content_fingerprint": fingerprints[item.id],
            "received_at": now,
            "device_time_suspicious": abs((item.device_time - now).total_seconds())
            > threshold_seconds,
        }
        for item in items
    ]

    inserted_ids = set(
        session.scalars(
            pg_insert(Event)
            .values(rows)
            .on_conflict_do_nothing(index_elements=[Event.id])
            .returning(Event.id)
        )
    )
    if commit:
        session.commit()

    results: dict[uuid.UUID, UploadStatus] = {}
    conflicted_ids = [item.id for item in items if item.id not in inserted_ids]
    existing_by_id: dict[uuid.UUID, Event] = {}
    if conflicted_ids:
        existing_by_id = {
            row.id: row
            for row in session.scalars(select(Event).where(Event.id.in_(conflicted_ids)))
        }

    for item in items:
        if item.id in inserted_ids:
            results[item.id] = "accepted"
            continue
        results[item.id] = "duplicate"
        existing = existing_by_id.get(item.id)
        if existing is not None and existing.content_fingerprint != fingerprints[item.id]:
            _report_conflict(session, redis, existing)
    return results


def _report_conflict(session: Session, redis: Redis, existing: Event) -> None:
    logger.error(
        "event id reused with different content",
        extra={
            "event_id": str(existing.id),
            "event_type": existing.event_type,
            "type_version": existing.type_version,
        },
    )
    # 每个事件 ID 一个窗口只告警一次：客户端反复重传同一个（内容不一致的）ID
    # 不应该把告警通道刷爆，日志（上面的 logger.error）不受这个节流影响。
    throttle_key = f"alerts:events:conflict:{existing.id}"
    if not redis.set(throttle_key, "1", nx=True, ex=_CONFLICT_ALERT_THROTTLE_SECONDS):
        return
    alerts.notify(
        session,
        "味谱事件管道：事件 ID 重复但内容不同",
        (
            f"事件 {existing.id}（类型 {existing.event_type} v{existing.type_version}）"
            "再次上传时内容和已存记录不一致，新内容已忽略，原记录未改动，请排查客户端为什么"
            "复用了同一个事件 ID。"
        ),
    )


def record_taste_profile_changed(
    session: Session, user_id: uuid.UUID, change_id: uuid.UUID, *, now: datetime
) -> None:
    """Append metadata in the caller's profile/history transaction, without commit.

    The immutable change UUID is also the event UUID. Upload retries therefore
    use the existing global deduplication rule, never invent a second event.
    """
    item = EventInput(
        id=change_id,
        event_type="taste_profile.changed",
        type_version=1,
        device_id="server",
        device_time=now,
        app_version="server",
        correlation={"taste_profile_change_id": str(change_id)},
        content={},
    )
    session.add(
        Event(
            id=item.id,
            user_id=user_id,
            event_type=item.event_type,
            type_version=item.type_version,
            device_id=item.device_id,
            device_time=now,
            app_version=item.app_version,
            correlation=item.correlation,
            content=item.content,
            content_fingerprint=_fingerprint(user_id, item),
            received_at=now,
            device_time_suspicious=False,
        )
    )


def record_recipe_version_saved(
    session: Session,
    redis: Redis,
    user_id: uuid.UUID,
    version_id: uuid.UUID,
    previous_version_id: uuid.UUID | None,
    edit_operations: list[dict[str, Any]],
    ai_assisted: bool,
    *,
    now: datetime,
) -> None:
    """Write one idempotent experience event for a saved recipe version.

    The recipe transaction is already committed when this function is called. A
    transient event-pipeline failure therefore cannot roll back the user's save;
    the caller logs the failure and a later reconciliation can retry it.
    """
    # The event worker depends on Redis for its delivery path.  Check it before
    # writing the event so a Redis outage leaves the durable recipe outbox row
    # pending instead of falsely marking delivery complete.
    redis.ping()
    existing = session.scalar(
        select(Event).where(
            Event.user_id == user_id,
            Event.event_type == "recipe.version_saved",
            Event.correlation["recipe_version_id"].astext == str(version_id),
        )
    )
    if existing is not None:
        return
    item = EventInput(
        # A version is immutable and emitted once: replays must keep its event ID.
        id=version_id,
        event_type="recipe.version_saved",
        type_version=1,
        device_id="server",
        device_time=now,
        app_version="server",
        correlation={"recipe_version_id": str(version_id)},
        content={
            "recipe_version_id": str(version_id),
            "previous_version_id": str(previous_version_id) if previous_version_id else None,
            "edit_operations": edit_operations,
            "ai_assisted": ai_assisted,
        },
    )
    upload(session, redis, user_id, [item], now=now)
