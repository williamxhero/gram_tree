"""Durable, data-minimized request access records."""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta

from sqlalchemy import JSON, DateTime, Index, Integer, String, delete, select
from sqlalchemy.orm import Mapped, Session, mapped_column

from gramtree.core.time import utcnow
from gramtree.db import Base


class AccessLog(Base):
    __tablename__ = "access_logs"
    __table_args__ = (Index("ix_access_logs_created_at", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    request_id: Mapped[str] = mapped_column(String(36), index=True)
    account_id: Mapped[uuid.UUID | None]
    device_id: Mapped[str | None] = mapped_column(String(64))
    ip_address: Mapped[str | None] = mapped_column(String(45))
    method: Mapped[str] = mapped_column(String(10))
    endpoint: Mapped[str] = mapped_column(String(255))
    content_ids: Mapped[list[str]] = mapped_column(JSON, default=list)
    status_code: Mapped[int] = mapped_column(Integer)


def record(session: Session, **values: object) -> None:
    session.add(AccessLog(**values))
    session.commit()


def purge_expired(session: Session, now: datetime, retention_days: int) -> int:
    threshold = now - timedelta(days=retention_days)
    result = session.execute(delete(AccessLog).where(AccessLog.created_at < threshold))
    session.commit()
    return result.rowcount or 0  # type: ignore[attr-defined]


def recent(session: Session, *, request_id: str | None = None, limit: int = 100) -> list[AccessLog]:
    statement = (
        select(AccessLog).order_by(AccessLog.created_at.desc()).limit(min(1000, max(1, limit)))
    )
    if request_id:
        statement = statement.where(AccessLog.request_id == request_id)
    return list(session.scalars(statement))
