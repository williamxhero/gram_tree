"""登录后批量上传经验层事件。

事件表只追加：这个模块只有一个上传接口，不提供任何修改、删除接口，也不提供任何
读取事件明细的对外接口（票 3 起需要的内部查询是纯 Python 函数，不挂 HTTP 路由）。
"""

import uuid
from typing import Any, Literal

from fastapi import APIRouter
from pydantic import BaseModel, Field

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES
from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp, utcnow
from gramtree.deps import SessionDep
from gramtree.events import service

router = APIRouter(prefix="/events", tags=["events"])

# 单批最多几条事件；票 2 会把它换成服务端配置项（带拒收原因），这里先给一个够用的硬上限，
# 防止单次请求体无限大，不代表最终的业务上限。
_MAX_BATCH_SIZE = 500


class EventCorrelationIds(BaseModel):
    """关联 ID：都可以留空。这些字段名是所有事件类型统一使用的命名，
    后面新增的关联类型也照这个模式加字段，不要另起一套命名。
    """

    recipe_version_id: IdV4 | None = Field(default=None, description="菜谱版本")
    cooking_record_id: IdV4 | None = Field(default=None, description="做菜记录")
    ui_composition_id: IdV4 | None = Field(default=None, description="界面组合")
    taste_profile_change_id: IdV4 | None = Field(default=None, description="口味档案变更")
    plan_id: IdV4 | None = Field(default=None, description="规划")
    recommendation_exposure_id: IdV4 | None = Field(default=None, description="推荐曝光")
    suggestion_id: IdV4 | None = Field(default=None, description="建议")


class EventUploadItem(BaseModel):
    id: IdV4 = Field(description="客户端生成的事件 ID（UUID v4），全局唯一，按它去重")
    event_type: str = Field(min_length=1, max_length=100)
    type_version: int = Field(ge=1, description="事件类型的版本号")
    device_id: str = Field(min_length=1, max_length=64)
    device_time: Timestamp = Field(description="设备本地时间，必须带时区")
    app_version: str = Field(min_length=1, max_length=32)
    correlation: EventCorrelationIds = Field(default_factory=EventCorrelationIds)
    content: dict[str, Any] = Field(
        default_factory=dict,
        description=("事件内容。用户 ID 只按登录状态填入，这里出现的任何 user_id 字段都不采信"),
    )


class EventUploadRequest(BaseModel):
    events: list[EventUploadItem] = Field(min_length=1, max_length=_MAX_BATCH_SIZE)


EventUploadStatus = Literal["accepted", "duplicate"]


class EventUploadResultItem(BaseModel):
    id: uuid.UUID
    status: EventUploadStatus = Field(
        description="accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动"
    )


class EventUploadResponse(BaseModel):
    results: list[EventUploadResultItem]


@router.post(
    "/upload",
    response_model=EventUploadResponse,
    responses=ERROR_RESPONSES,
    summary="批量上传经验层事件（需要登录，按事件 ID 去重，只追加存储）",
)
def upload_events(
    body: EventUploadRequest, auth: CurrentAuth, session: SessionDep
) -> EventUploadResponse:
    items = [
        service.EventInput(
            id=e.id,
            event_type=e.event_type,
            type_version=e.type_version,
            device_id=e.device_id,
            device_time=e.device_time,
            app_version=e.app_version,
            correlation=e.correlation.model_dump(mode="json", exclude_none=True),
            content=e.content,
        )
        for e in body.events
    ]
    outcome = service.upload(session, auth.user.id, items, now=utcnow())
    return EventUploadResponse(
        results=[EventUploadResultItem(id=e.id, status=outcome[e.id]) for e in body.events]
    )
