"""开发和测试环境才挂载的辅助接口：查询当前登录用户已入库的事件条数。

只用于端到端测试确认"服务端每条事件只收到一次"（SPEC-010.1 票 7：安卓模拟器离线
补传、网页版端到端）——只回一个数字，不回事件内容，也不回具体记录的任何字段，不是
票 1 定下的"事件表没有对外可读明细接口"这条规矩的例外。正式环境不挂载，也不进
OpenAPI 描述，写法照抄 `gramtree.accounts.dev`。

内部实现直接调用票 3 已经有的 `gramtree.events.queries.query_events`，不另开一条
查询路径。
"""

from fastapi import APIRouter, Query

from gramtree.accounts.deps import CurrentAuth
from gramtree.deps import SessionDep
from gramtree.events.queries import query_events

router = APIRouter(prefix="/dev/events", include_in_schema=False)


@router.get("/count")
def count_events(
    auth: CurrentAuth,
    session: SessionDep,
    event_type: str = Query(),
    version: int | None = Query(default=None, description="不给就统计这个类型的所有版本"),
    device_id: str | None = Query(default=None, description="不给就不按设备过滤"),
) -> dict[str, int]:
    events = query_events(
        session,
        user_id=auth.user.id,
        event_type=event_type,
        version=version,
    )
    if device_id is not None:
        events = [e for e in events if e.device_id == device_id]
    return {"count": len(events)}
