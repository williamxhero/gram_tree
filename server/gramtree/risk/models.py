import uuid
from datetime import datetime

from sqlalchemy import Index, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class RiskEvent(Base):
    """Durable explanation for a rule signal.

    Subject identifiers are HMACs, not the source IP, device ID, or token. Evidence is
    deliberately a small JSON object assembled by the rule engine, never request data.
    """

    __tablename__ = "risk_events"
    __table_args__ = (
        Index("ix_risk_events_subject_created", "subject_type", "subject_key_hash", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    subject_type: Mapped[str] = mapped_column(String(16), nullable=False)
    subject_key_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    rule: Mapped[str] = mapped_column(String(64), nullable=False)
    evidence: Mapped[dict[str, object]] = mapped_column(JSONB, nullable=False)
    points: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)


class RiskAction(Base):
    """Every graduated action, including how it was recovered."""

    __tablename__ = "risk_actions"
    __table_args__ = (
        Index("ix_risk_actions_subject_started", "subject_type", "subject_key_hash", "started_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    subject_type: Mapped[str] = mapped_column(String(16), nullable=False)
    subject_key_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    rule: Mapped[str] = mapped_column(String(64), nullable=False)
    evidence: Mapped[dict[str, object]] = mapped_column(JSONB, nullable=False)
    level: Mapped[str] = mapped_column(String(16), nullable=False)
    started_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)
    ends_at: Mapped[datetime | None] = mapped_column(default=None)
    lifted_at: Mapped[datetime | None] = mapped_column(default=None)
    lift_reason: Mapped[str | None] = mapped_column(String(32), default=None)
