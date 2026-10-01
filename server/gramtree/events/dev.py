"""开发和测试环境才挂载的辅助接口：查询当前登录用户的事件收据。

只用于端到端测试确认经验层事件的条数和菜谱版本保存事件的固定收据字段。
这些接口只返回测试合同登记的最小字段，不提供通用事件明细查询；正式环境不挂载，也不进
OpenAPI 描述，写法照抄 `gramtree.accounts.dev`。

内部实现直接调用票 3 已经有的 `gramtree.events.queries.query_events`，不另开一条
查询路径。
"""

import uuid

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


@router.get("/recipe-version-saved")
def recipe_version_saved_receipt(
    auth: CurrentAuth,
    session: SessionDep,
    version_id: uuid.UUID,
) -> dict[str, list[dict[str, object]]]:
    """Return the fixed, owner-scoped receipt contract for one recipe save."""
    events = query_events(
        session,
        user_id=auth.user.id,
        event_type="recipe.version_saved",
        correlation_field="recipe_version_id",
        correlation_value=str(version_id),
    )
    return {
        "items": [
            {
                "event_id": str(event.id),
                "recipe_version_id": event.content.get("recipe_version_id"),
                "previous_version_id": event.content.get("previous_version_id"),
                "edit_operations": event.content.get("edit_operations", []),
                "ai_assisted": event.content.get("ai_assisted", False),
            }
            for event in events
        ]
    }
