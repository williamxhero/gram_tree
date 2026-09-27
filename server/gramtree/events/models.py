"""经验层事件表：只追加存储。

不提供任何修改、删除接口，也不提供任何读取事件明细的对外接口（SPEC-010.1 票 1 验收标准）。
后续子 SPEC（票 3 起的内部查询、导出等）按需直接用 SQLAlchemy 查这张表，不是通过 HTTP。
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.time import utcnow
from gramtree.db import Base


class Event(Base):
    __tablename__ = "events"

    # 客户端生成的 UUID v4，全局唯一；重复上传按它去重，不允许改动已有记录
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    # 用户 ID 只认登录状态（CurrentAuth），事件内容里出现的任何 user_id 字段都不采信
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    event_type: Mapped[str] = mapped_column(String(100), index=True)
    type_version: Mapped[int] = mapped_column(Integer)
    device_id: Mapped[str] = mapped_column(String(64))
    # 设备本地时间，带时区；服务端另外记 received_at，两者不是一回事
    device_time: Mapped[datetime]
    app_version: Mapped[str] = mapped_column(String(32))
    # 关联 ID：菜谱版本/做菜记录/界面组合/口味档案变更/规划/推荐曝光/建议，字段名统一见
    # gramtree.events.router.EventCorrelationIds；都可以留空，序列化时留空的字段不写入
    correlation: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    content: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    # 用来判断同一个 ID 重复上传时内容是否一致；只在服务端内部用，不对外暴露
    content_fingerprint: Mapped[str] = mapped_column(String(64))
    received_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)
