"""产品埋点上传接口：/v1/analytics/events。

只登记这些字段，多余字段一律拒收（每个模型都 extra="forbid"）；用户 ID 不认请求体，
一律由服务端按登录状态（OptionalAuth）填入，未登录允许匿名埋点。
"""

from typing import Any, Literal

from fastapi import APIRouter, status
from pydantic import BaseModel, ConfigDict, Field

from gramtree.accounts.deps import DeviceIdDep, OptionalAuth
from gramtree.analytics import service
from gramtree.core.clock import ClockDep
from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse
from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp
from gramtree.deps import SessionDep

router = APIRouter(prefix="/analytics", tags=["analytics"])

AnalyticsEventType = Literal["page_view", "tap", "load_duration"]


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    out: dict[int | str, dict[str, Any]] = dict(ERROR_RESPONSES)
    for code in codes:
        out[code] = {"model": ErrorResponse}
    return out


class AnalyticsEventIn(BaseModel):
    """只允许这些字段：事件类型、页面/入口标识、可选耗时、发生时间、设备 ID。

    不含菜谱内容、口味档案、过敏和健康信息；也不接受用户 ID（服务端按登录状态填入）。
    """

    model_config = ConfigDict(extra="forbid")

    id: IdV4 = Field(description="客户端生成的 UUID v4，用于去重")
    event_type: AnalyticsEventType
    target: str = Field(min_length=1, max_length=200, description="页面或入口标识")
    duration_ms: int | None = Field(
        default=None, ge=0, le=600_000, description="耗时（毫秒），仅部分事件类型有意义"
    )
    occurred_at: Timestamp
    device_id: str | None = Field(default=None, max_length=64)


class AnalyticsUploadRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    events: list[AnalyticsEventIn] = Field(min_length=1, max_length=100)


@router.post(
    "/events",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=_errors(422),
    summary="上传产品埋点（页面访问 / 入口点击 / 加载耗时）",
    description=(
        "同意隐私政策前、或关闭“产品改进统计”开关后，客户端不应调用这个接口。"
        "服务端只按登记好的字段接收，多余字段一律拒收；不接受第三方分析服务转发。"
    ),
)
def upload_analytics_events(
    body: AnalyticsUploadRequest,
    session: SessionDep,
    auth: OptionalAuth,
    device_id: DeviceIdDep,
    clock: ClockDep,
) -> None:
    service.record_events(
        session,
        [
            service.AnalyticsEventInput(
                id=e.id,
                event_type=e.event_type,
                target=e.target,
                occurred_at=e.occurred_at,
                duration_ms=e.duration_ms,
                device_id=e.device_id or device_id,
            )
            for e in body.events
        ],
        user_id=auth.user.id if auth is not None else None,
        now=clock(),
    )
