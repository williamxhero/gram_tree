"""SPEC-005.3 attribution, learning signal and change-fact storage."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import CheckConstraint, Float, ForeignKey, Index, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class TasteAttribution(Base):
    """Per-record attribution with a traceable internal rule decision."""

    __tablename__ = "taste_attributions"
    __table_args__ = (
        Index("ix_taste_attributions_owner", "owner_id"),
        Index("ix_taste_attributions_version", "recipe_version_id", "verdict"),
        CheckConstraint(
            "verdict IN ('personal', 'recipe', 'pending')",
            name="ck_taste_attribution_verdict",
        ),
        CheckConstraint(
            "decision_source IN ('rule', 'user', 'unanswered')",
            name="ck_taste_attribution_source",
        ),
    )

    record_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cooking_records.id", ondelete="CASCADE"), primary_key=True
    )
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("taste_profiles.id", ondelete="CASCADE")
    )
    recipe_version_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True, default=None)
    flavors: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    feedback_revision_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True, default=None)
    verdict: Mapped[str] = mapped_column(String(16), default="pending")
    decision_source: Mapped[str] = mapped_column(String(16), default="unanswered")
    reason_code: Mapped[str] = mapped_column(String(48), default="not_requested")
    rules_version: Mapped[str] = mapped_column(String(48), default="taste-learning-1")
    sample_size: Mapped[int] = mapped_column(Integer, default=0)
    automatic: Mapped[bool] = mapped_column(default=True)
    revision: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)

    @property
    def learning_eligibility(self) -> str:
        """strong | reduced | excluded for the feedback learning path."""
        if self.verdict == "recipe":
            return "excluded"
        if self.decision_source == "user" and self.verdict == "personal":
            return "strong"
        if self.verdict == "personal":
            return "strong"
        return "reduced"


class TasteLearningSignal(Base):
    __tablename__ = "taste_learning_signals"
    __table_args__ = (
        UniqueConstraint("owner_id", "signal_key", name="uq_taste_learning_signals_owner_key"),
        Index("ix_taste_learning_signals_owner_field", "owner_id", "field", "status"),
        CheckConstraint(
            "status IN ('active', 'consumed', 'retracted')", name="ck_taste_signal_status"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("taste_profiles.id", ondelete="CASCADE")
    )
    record_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cooking_records.id", ondelete="CASCADE"), nullable=True, default=None
    )
    signal_key: Mapped[str] = mapped_column(String(160))
    kind: Mapped[str] = mapped_column(String(32))
    field: Mapped[str] = mapped_column(String(100))
    scope: Mapped[str] = mapped_column(String(64), default="overall")
    direction: Mapped[int] = mapped_column(Integer, default=0)
    base_weight: Mapped[float] = mapped_column(Float, default=0.0)
    effective_weight: Mapped[float] = mapped_column(Float, default=0.0)
    status: Mapped[str] = mapped_column(String(16), default="active")
    consumed_by_change_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True, default=None)
    attribution_record_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cooking_records.id", ondelete="SET NULL"), nullable=True, default=None
    )
    flavor_key: Mapped[str | None] = mapped_column(String(16), nullable=True, default=None)
    ingredient_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True, default=None)
    ingredient_category: Mapped[str | None] = mapped_column(String(20), nullable=True, default=None)
    observed_at: Mapped[datetime] = mapped_column(default=utcnow)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class TasteChangeFact(Base):
    """Business facts for the revert-rate metric (SPEC-012)."""

    __tablename__ = "taste_change_facts"
    __table_args__ = (
        UniqueConstraint("owner_id", "change_id", "event_type", name="uq_taste_change_facts"),
        Index("ix_taste_change_facts_owner", "owner_id", "event_type"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    change_id: Mapped[uuid.UUID] = mapped_column()
    event_type: Mapped[str] = mapped_column(String(48))
    source: Mapped[str] = mapped_column(String(24), default="auto")
    origin_change_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True, default=None)
    field: Mapped[str] = mapped_column(String(100), default="")
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


__all__ = ["TasteAttribution", "TasteChangeFact", "TasteLearningSignal"]
