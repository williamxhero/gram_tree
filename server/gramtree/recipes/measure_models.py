"""Account-owned measuring tools; display preferences never enter recipe versions."""

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, Float, ForeignKey, Index, String, text
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class PersonalMeasure(Base):
    __tablename__ = "personal_measures"
    __table_args__ = (
        Index(
            "uq_personal_measures_owner_name",
            "owner_id",
            "name",
            unique=True,
            postgresql_where=text("deleted_at IS NULL"),
        ),
        CheckConstraint("capacity_ml > 0 AND capacity_ml <= 10000", name="ck_measure_capacity"),
        CheckConstraint("kind IN ('spoon', 'bowl', 'cup')", name="ck_measure_kind"),
        Index("ix_personal_measures_owner_created", "owner_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(64))
    kind: Mapped[str] = mapped_column(String(16))
    capacity_ml: Mapped[float] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)
    deleted_at: Mapped[datetime | None]
