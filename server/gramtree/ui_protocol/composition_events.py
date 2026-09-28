"""服务端主动写"组合展示"事件：每次 `POST /v1/ui/compositions` 成功返回时记一条
（SPEC-009.1 票 2，#78）。

这条事件不走客户端上传接口（`gramtree.events.router.upload_events`）。它描述的是
"服务端刚刚决定了下发什么"，这件事在服务端产生的那一刻就该落库，不必等 App 把它当成
一条普通事件再传回来——等 App 上传的话，未登录/离线时会丢，多一趟网络，而且这本该是
"服务端知道自己下发了什么"，不是"App 转述服务端说了什么"（转述容易和 App 自己看到的
渲染结果不一致，正好违反本票要求的"事件里的组件类型、详略、理由和接口返回的描述
一致"）。

写库逻辑仍然只走 `gramtree.events.service.upload`（"写事件的唯一入口"），不另起一条
落库/去重路径。`upload()` 的参数形状是为"客户端批量上传一批事件"设计的
（`EventInput` 要求 `id`/`device_id`/`device_time`/`app_version`，都是"这条事件来自
哪个设备、哪次上传"的信息），这里是服务端自己产生单条事件，没有真实设备，按下面的
方式填，两者都不是编造一个看起来像真实值的值，而是用能一眼看出"这是服务端事件"的
固定哨兵：

- `id`：客户端生成事件 ID 是为了离线场景下重试上传也能去重；这里服务端一次组合只
  调用一次，直接生成一个新的 UUID v4，不会有重复上传的问题。
- `device_id`/`app_version`：固定成 `SERVER_DEVICE_ID`/`SERVER_APP_VERSION`
  （值都是 `"server"`），标记"这条事件由服务端产生，不来自任何设备或 App 版本"。
  `Event.device_id`/`Event.app_version` 的列注释写的是面向客户端上传场景的说明，
  这是目前唯一的例外来源。
- `device_time`：没有设备本地时间，直接用服务端当前时间；连同 `upload()` 的
  `now` 参数传同一个值，两者相等，不会被误判成"设备时间可疑"。
"""

import uuid

from redis import Redis
from sqlalchemy.orm import Session

from gramtree.core.time import utcnow
from gramtree.events import service as events_service
from gramtree.ui_protocol.protocol import ComponentDescriptor, PageDescription

SERVER_DEVICE_ID = "server"
SERVER_APP_VERSION = "server"

EVENT_TYPE = "ui.composition_shown"
EVENT_TYPE_VERSION = 1


def _component_summary(component: ComponentDescriptor) -> dict[str, object]:
    return {
        "type": component.type,
        "detail": component.detail,
        "reason_code": component.reason.code,
        "reason_text": component.reason.text,
    }


def composition_shown_content(description: PageDescription) -> dict[str, object]:
    """`ui.composition_shown` 的 content：和接口返回的页面描述里的组件类型、详略、
    理由必须一致——这里直接从同一个 `PageDescription` 读，不是重新计算一遍。
    """
    content: dict[str, object] = {
        "page_type": description.page_type,
        "components": [_component_summary(c) for c in description.components],
        "is_fallback": description.fallback is not None,
        "fallback_reason": (
            description.fallback.reason_code if description.fallback is not None else None
        ),
    }
    if description.experiment is not None:
        content["experiment"] = {
            "experiment": description.experiment.experiment,
            "variant": description.experiment.variant,
        }
    else:
        content["experiment"] = None
    return content


def record_composition_shown(
    session: Session,
    redis: Redis,
    user_id: uuid.UUID,
    description: PageDescription,
) -> None:
    now = utcnow()
    item = events_service.EventInput(
        id=uuid.uuid4(),
        event_type=EVENT_TYPE,
        type_version=EVENT_TYPE_VERSION,
        device_id=SERVER_DEVICE_ID,
        device_time=now,
        app_version=SERVER_APP_VERSION,
        correlation={"ui_composition_id": str(description.composition_id)},
        content=composition_shown_content(description),
    )
    events_service.upload(session, redis, user_id, [item], now=now)
