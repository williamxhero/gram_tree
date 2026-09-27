"""经验层事件的去重和落库逻辑。

- 事件 ID 全局唯一：批量插入用 `ON CONFLICT DO NOTHING`，冲突的一律答复"重复"，不改原记录。
- 同一个 ID 但内容不一样：同样答复"重复"、不改原记录，另外记一条 ERROR 日志并走
  SPEC-013.1 的告警通道（`gramtree.observability.alerts.notify`）。
- 用户 ID 只认调用方传入的登录用户 ID（由路由层从 CurrentAuth 取），这一层根本不从
  事件内容里读 user_id，所以客户端在内容里自报的用户 ID 不可能影响归属。
"""

import hashlib
import json
import logging
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Literal

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from gramtree.events.models import Event
from gramtree.observability import alerts

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
    user_id: uuid.UUID,
    items: list[EventInput],
    now: datetime,
) -> dict[uuid.UUID, UploadStatus]:
    """批量落库，返回每个事件 ID 对应的答复。"""
    if not items:
        return {}

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
            _report_conflict(session, existing)
    return results


def _report_conflict(session: Session, existing: Event) -> None:
    logger.error(
        "event id reused with different content",
        extra={
            "event_id": str(existing.id),
            "event_type": existing.event_type,
            "type_version": existing.type_version,
        },
    )
    alerts.notify(
        session,
        "味谱事件管道：事件 ID 重复但内容不同",
        (
            f"事件 {existing.id}（类型 {existing.event_type} v{existing.type_version}）"
            "再次上传时内容和已存记录不一致，新内容已忽略，原记录未改动，请排查客户端为什么"
            "复用了同一个事件 ID。"
        ),
    )
