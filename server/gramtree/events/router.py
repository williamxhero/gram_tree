"""登录后批量上传经验层事件。

事件表只追加：这个模块只有一个上传接口，不提供任何修改、删除接口，也不提供任何
读取事件明细的对外接口（票 3 起需要的内部查询是纯 Python 函数，不挂 HTTP 路由）。

票 2（登记表校验、拒收、版本兼容、上限配置项）落在这里：
- 单批条数/大小上限是配置项（`events.upload_max_items`/`events.upload_max_bytes`，登记在
  `gramtree.runtime_config.registry`），取代了票 1 里硬编码的 `max_length=500`——超限时
  整批返回 `ApiError`，不逐条处理。
- 逐条按登记表校验（`gramtree.events.validation.validate_event`）：不合格的事件答复
  `status="rejected"` + 原因代码/说明，同一批里合格的事件照常走原来的去重入库逻辑
  （`gramtree.events.service.upload`）。
- 关联 ID 字段这里故意只做"格式是不是字符串"的结构校验（不是 `IdV4`），格式是否是合法
  UUID v4 放到 `validate_event` 里按条判断，这样单条关联 ID 写错不会让整批请求直接 422，
  而是这一条被拒收、其余合格事件仍然入库。

票 3（设备时间可疑标记、内部查询、上传监控告警）落在别的模块，这里只在每次上传处理完
之后调一次 `gramtree.events.metrics.record_upload_batch`，把这一批的接收/重复/拒收
条数和被接收事件的上传延迟记下来，供 SPEC-013.1 的监控和事件管道自己的告警任务
（`gramtree.events.alerts`）读。
"""

import uuid
from datetime import datetime
from typing import Any, Literal

from fastapi import APIRouter, Request
from pydantic import BaseModel, Field
from redis import Redis

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError
from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp, utcnow
from gramtree.deps import RedisDep, SessionDep
from gramtree.events import metrics as events_metrics
from gramtree.events import service, validation
from gramtree.runtime_config import service as config_service

router = APIRouter(prefix="/events", tags=["events"])


class EventCorrelationIds(BaseModel):
    """关联 ID：都可以留空。这些字段名是所有事件类型统一使用的命名，
    后面新增的关联类型也照这个模式加字段，不要另起一套命名。

    这里只要求"是字符串"，不在 pydantic 层面强制 UUID v4 格式——格式是否合法放在
    `gramtree.events.validation` 里按条判断，不合法的那一条被单独拒收
    （原因码 `invalid_correlation_id`），不会拖累同一批里其它合格的事件。
    """

    recipe_version_id: str | None = Field(default=None, description="菜谱版本")
    cooking_record_id: str | None = Field(default=None, description="做菜记录")
    ui_composition_id: str | None = Field(default=None, description="界面组合")
    taste_profile_change_id: str | None = Field(default=None, description="口味档案变更")
    plan_id: str | None = Field(default=None, description="规划")
    recommendation_exposure_id: str | None = Field(default=None, description="推荐曝光")
    suggestion_id: str | None = Field(default=None, description="建议")


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
    # 条数上限是配置项 events.upload_max_items，在路由函数里校验（读 body 之后、逐条处理
    # 之前），不在这里写死上限，避免出现两套上限。
    events: list[EventUploadItem] = Field(min_length=1)


EventUploadStatus = Literal["accepted", "duplicate", "rejected"]


class RejectionReason(BaseModel):
    code: str = Field(
        description=(
            "程序可判断的拒收原因代码：unknown_event_type / unsupported_version / "
            "invalid_content / invalid_correlation_id"
        )
    )
    message: str = Field(description="给人看的一句话说明，不包含事件内容本身")


class EventUploadResultItem(BaseModel):
    id: uuid.UUID
    status: EventUploadStatus = Field(
        description=(
            "accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；"
            "rejected：没通过登记表校验，未入库，见 reason"
        )
    )
    reason: RejectionReason | None = Field(
        default=None, description="status 是 rejected 时才有，说明被拒收的原因"
    )


class EventUploadResponse(BaseModel):
    results: list[EventUploadResultItem]


@router.post(
    "/upload",
    response_model=EventUploadResponse,
    responses=ERROR_RESPONSES,
    summary="批量上传经验层事件（需要登录，按登记表校验，按事件 ID 去重，只追加存储）",
)
def upload_events(
    request: Request,
    body: EventUploadRequest,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
) -> EventUploadResponse:
    _check_batch_limits(request, body, session)

    accepted_items: list[service.EventInput] = []
    rejections: dict[uuid.UUID, RejectionReason] = {}
    for e in body.events:
        correlation = e.correlation.model_dump(mode="json", exclude_none=True)
        rejection = validation.validate_event(e.event_type, e.type_version, correlation, e.content)
        if rejection is not None:
            rejections[e.id] = RejectionReason(code=rejection.code, message=rejection.message)
            continue
        accepted_items.append(
            service.EventInput(
                id=e.id,
                event_type=e.event_type,
                type_version=e.type_version,
                device_id=e.device_id,
                device_time=e.device_time,
                app_version=e.app_version,
                correlation=correlation,
                content=e.content,
            )
        )

    now = utcnow()
    outcome = service.upload(session, redis, auth.user.id, accepted_items, now=now)
    _record_batch_metrics(redis, accepted_items, outcome, rejections, now)

    results = []
    for e in body.events:
        if e.id in rejections:
            results.append(
                EventUploadResultItem(id=e.id, status="rejected", reason=rejections[e.id])
            )
        else:
            results.append(EventUploadResultItem(id=e.id, status=outcome[e.id]))
    return EventUploadResponse(results=results)


def _record_batch_metrics(
    redis: Redis,
    accepted_items: list[service.EventInput],
    outcome: dict[uuid.UUID, service.UploadStatus],
    rejections: dict[uuid.UUID, RejectionReason],
    now: datetime,
) -> None:
    """把这一批的上传结果和延迟记进事件管道指标（票 3）。

    延迟只算这一批里被新接收（`accepted`）的事件：设备时间到服务端接收时间
    （`now`）的差值，单位毫秒；重复、拒收的事件不产生新的延迟样本。
    """
    accepted = sum(1 for status in outcome.values() if status == "accepted")
    duplicate = sum(1 for status in outcome.values() if status == "duplicate")
    delays_ms = [
        (now - item.device_time).total_seconds() * 1000
        for item in accepted_items
        if outcome[item.id] == "accepted"
    ]
    events_metrics.record_upload_batch(
        redis,
        accepted=accepted,
        duplicate=duplicate,
        rejected=len(rejections),
        delays_ms=delays_ms,
    )


def _check_batch_limits(request: Request, body: EventUploadRequest, session: SessionDep) -> None:
    max_items = config_service.get(session, "events.upload_max_items")
    if len(body.events) > max_items:
        raise ApiError(
            422,
            "too_many_events",
            "单次上传的事件条数超过上限",
            f"最多 {max_items} 条，收到 {len(body.events)} 条，请分批上传",
        )

    max_bytes = config_service.get(session, "events.upload_max_bytes")
    content_length = request.headers.get("content-length")
    if content_length is not None and content_length.isdigit() and int(content_length) > max_bytes:
        raise ApiError(
            422,
            "payload_too_large",
            "单次上传的请求体大小超过上限",
            f"最多 {max_bytes} 字节，请分批上传",
        )
