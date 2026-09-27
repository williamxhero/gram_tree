import uuid
from datetime import datetime

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


class Sample(Base):
    """示例资源：演示客户端生成 ID、去重、时间和游标分页的写法。"""

    __tablename__ = "example_samples"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)


class TaskHeartbeat(Base):
    """示例后台任务写下的记录，证明“触发 → 任务进程执行 → 结果可查”可用。"""

    __tablename__ = "task_heartbeats"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    source: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)
