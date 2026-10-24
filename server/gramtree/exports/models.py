import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.db import Base


class ExportJob(Base):
    __tablename__ = "data_exports"
    __table_args__ = (
        Index("ix_data_exports_owner_created", "owner_id", "created_at"),
        Index("ix_data_exports_status", "status"),
        CheckConstraint(
            "status IN ('pending','processing','completed','failed','expired')",
            name="ck_data_exports_status",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    status: Mapped[str] = mapped_column(String(16), default="pending")
    attempts: Mapped[int] = mapped_column(default=0)
    error_code: Mapped[str | None] = mapped_column(String(64), default=None)
    created_at: Mapped[datetime]
    completed_at: Mapped[datetime | None] = mapped_column(default=None)
    expires_at: Mapped[datetime | None] = mapped_column(default=None)
