"""产品埋点表：和经验层事件表（gramtree.events，见 SPEC-010.1 其它票）完全独立。

这张表不引用 users 表（没有外键），只按值存一份用户 ID 快照，避免和账号模块产生耦合；
注销账号清理个人数据时不需要联动这张表做级联删除判断。
"""

import uuid
from datetime import datetime

from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.time import utcnow
from gramtree.db import Base


class AnalyticsEvent(Base):
    """一条产品埋点：页面访问 / 入口点击 / 加载耗时。不含菜谱内容、口味档案、过敏和健康信息。"""

    __tablename__ = "product_analytics_events"

    # 客户端生成的 UUID v4，重复上传按它去重
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    event_type: Mapped[str] = mapped_column(String(32))
    # 页面或入口标识，例如 "today" "recipe_detail.cook_button"
    target: Mapped[str] = mapped_column(String(200))
    duration_ms: Mapped[int | None] = mapped_column(Integer, default=None)
    occurred_at: Mapped[datetime]
    received_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)
    device_id: Mapped[str | None] = mapped_column(String(64), default=None)
    # 登录则填服务端识别出的用户 ID；未登录允许匿名埋点，留空
    user_id: Mapped[uuid.UUID | None] = mapped_column(default=None)
