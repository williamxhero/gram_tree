"""产品埋点的写入和清理逻辑。只操作 AnalyticsEvent 一张表，不 import 经验层事件模块。"""

import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import delete
from sqlalchemy.orm import Session

from gramtree.analytics.models import AnalyticsEvent


@dataclass(frozen=True)
class AnalyticsEventInput:
    id: uuid.UUID
    event_type: str
    target: str
    occurred_at: datetime
    duration_ms: int | None = None
    device_id: str | None = None


def record_events(
    session: Session,
    events: list[AnalyticsEventInput],
    *,
    user_id: uuid.UUID | None,
    now: datetime,
) -> None:
    """按 ID 去重追加写入；重复提交同一个 ID 直接跳过。"""
    for e in events:
        existing = session.get(AnalyticsEvent, e.id)
        if existing is not None:
            continue
        session.add(
            AnalyticsEvent(
                id=e.id,
                event_type=e.event_type,
                target=e.target,
                duration_ms=e.duration_ms,
                occurred_at=e.occurred_at,
                received_at=now,
                device_id=e.device_id,
                user_id=user_id,
            )
        )
    session.commit()


def purge_expired(session: Session, now: datetime, retention_days: int) -> int:
    """删除超过保存期的埋点，返回删除条数。"""
    threshold = now - timedelta(days=retention_days)
    result = session.execute(delete(AnalyticsEvent).where(AnalyticsEvent.received_at < threshold))
    session.commit()
    return result.rowcount or 0  # type: ignore[attr-defined]
