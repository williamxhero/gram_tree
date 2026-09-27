"""经验层事件表：只追加存储。

不提供任何修改、删除接口，也不提供任何读取事件明细的对外接口（SPEC-010.1 票 1 验收标准）。
后续子 SPEC（票 3 起的内部查询、导出等）按需直接用 SQLAlchemy 查这张表，不是通过 HTTP。
"""

import uuid
from datetime import datetime
from typing import Any, cast

from sqlalchemy import Boolean, ForeignKey, Index, Integer, String, case
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.time import utcnow
from gramtree.db import Base


class Event(Base):
    __tablename__ = "events"
    __table_args__ = (
        # 内部查询（gramtree.events.queries）按用户、类型、时间过滤最常见
        Index("ix_events_user_id_event_type_received_at", "user_id", "event_type", "received_at"),
        # 按关联 ID 的包含查询（correlation @> {...}）用得上，见 gramtree.events.queries
        Index("ix_events_correlation_gin", "correlation", postgresql_using="gin"),
    )

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
    # 设备时间和服务端接收时间相差超过阈值（配置项 events.device_time_suspicious_
    # threshold_seconds）时置 True；由 gramtree.events.service 在落库前计算好，
    # 这里只存结果，不重复算
    device_time_suspicious: Mapped[bool] = mapped_column(Boolean, default=False)

    @hybrid_property
    def analysis_time(self) -> datetime:  # pyright: ignore[reportRedeclaration]
        """ "分析用时间"：设备时间可疑时改用服务端接收时间，否则用设备时间。

        供票 3 的内部查询排序用，这样上传顺序乱了、或者设备时间被篡改/跑偏，
        依然能按事件发生的先后正确排序。这是一个 hybrid property：既能在 Python
        侧对单个 Event 实例取值，也能通过下面的 `.expression` 在 SQL 查询里
        直接拿来 order_by / 比较范围。
        """
        return self.received_at if self.device_time_suspicious else self.device_time

    @analysis_time.expression
    def analysis_time(cls) -> Any:
        return case(
            (cast("Any", cls).device_time_suspicious.is_(True), cast("Any", cls).received_at),
            else_=cast("Any", cls).device_time,
        )
