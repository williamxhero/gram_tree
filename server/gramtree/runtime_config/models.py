import uuid
from datetime import datetime

from sqlalchemy import String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class ConfigValue(Base):
    """被改过的配置项当前值；没改过的项不在表里。"""

    __tablename__ = "config_values"

    key: Mapped[str] = mapped_column(String(128), primary_key=True)
    value: Mapped[object] = mapped_column(JSONB)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow)


class ConfigChange(Base):
    """每次修改的历史。"""

    __tablename__ = "config_changes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    key: Mapped[str] = mapped_column(String(128), index=True)
    old_value: Mapped[object] = mapped_column(JSONB, nullable=True)
    new_value: Mapped[object] = mapped_column(JSONB)
    changed_by: Mapped[str] = mapped_column(String(128))
    reason: Mapped[str] = mapped_column(Text)
    changed_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)
