"""服务端内部查询经验层事件（SPEC-010.1 票 3）。

纯 Python 函数，**不挂任何 FastAPI 路由**——后续派生统计、证据结论、本人数据导出等
服务端内部模块直接调用这里的函数，不通过 HTTP（延续票 1 定下的规矩：事件表没有对外
的读明细接口）。

排序按“分析用时间”（`Event.analysis_time`：设备时间可疑时改用服务端接收时间，见
`gramtree.events.models`），这样即使事件上传顺序被打乱，也能还原事件发生的真实先后。
"""

import uuid
from datetime import datetime

from sqlalchemy import cast, select
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Session

from gramtree.events.models import Event


def query_events(
    session: Session,
    *,
    user_id: uuid.UUID,
    event_type: str | None = None,
    version: int | None = None,
    since: datetime | None = None,
    until: datetime | None = None,
    correlation_field: str | None = None,
    correlation_value: str | None = None,
) -> list[Event]:
    """按用户、类型、时间范围、关联 ID 查事件，按“分析用时间”升序返回。

    - `user_id` 是必填的强制过滤条件：调用方永远只能查到指定用户自己的事件，
      不会漏出别的用户的数据。
    - `event_type`/`version` 都给出时精确匹配某个登记的事件类型版本；只给
      `event_type` 时匹配这个类型的所有版本。
    - `since`/`until` 按“分析用时间”（`Event.analysis_time`）比较，不是上传/接收
      时间——对设备时间可疑的事件，这两者不是一回事。两端都是闭区间，都可以省略。
    - `correlation_field` 传 `gramtree.events.router.EventCorrelationIds` 里的
      字段名（例如 `"plan_id"`），`correlation_value` 传要匹配的值；两个参数要么
      同时给出，要么都不给。用 JSONB 包含查询（`@>`）实现，能用上 `events` 表
      `correlation` 列上的 GIN 索引。
    """
    if (correlation_field is None) != (correlation_value is None):
        raise ValueError("correlation_field 和 correlation_value 必须同时提供或同时省略")

    stmt = select(Event).where(Event.user_id == user_id)
    if event_type is not None:
        stmt = stmt.where(Event.event_type == event_type)
    if version is not None:
        stmt = stmt.where(Event.type_version == version)
    if since is not None:
        stmt = stmt.where(Event.analysis_time >= since)
    if until is not None:
        stmt = stmt.where(Event.analysis_time <= until)
    if correlation_field is not None:
        needle = cast({correlation_field: correlation_value}, JSONB)
        stmt = stmt.where(Event.correlation.op("@>")(needle))
    stmt = stmt.order_by(Event.analysis_time)
    return list(session.scalars(stmt))
