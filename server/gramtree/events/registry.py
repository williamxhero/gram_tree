"""事件类型登记表：骨架版（SPEC-010.1 票 1）。

每种经验层事件类型登记它的名称、类型版本、内容里有哪些字段、关联哪些 ID、是否进入本人数据导出。
业务事件类型由用到事件管道的后续子 SPEC 在这里登记；这一票只登记一个用来验证管道本身、
端到端跑通的自检类型（`pipeline.self_check`）。

严格的逐字段内容校验和拒收（SPEC-010.1 票 2）不在这一版做：`content_schema` 先留空表示
不校验。票 2 往这里加校验逻辑时，按 `(event_type, version)` 在 `BY_KEY` 查出登记项、
用 `content_schema` 校验 `content` 即可，不需要改这张表本身的结构；新增字段（比如拒收原因、
是否已下线）也照这个模式加，不影响已经登记的旧事件类型。
"""

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class EventTypeSpec:
    event_type: str
    # 类型版本：同一个 event_type 出新版本时只增不改旧版本的登记项，旧版本仍然接收
    version: int
    description: str
    # 这种事件类型会用到哪些关联 ID 字段，取值是
    # gramtree.events.router.EventCorrelationIds 里的字段名，例如 "recipe_version_id"
    correlation_fields: tuple[str, ...] = ()
    # 是否进入用户本人的数据导出（SPEC-011 之后用到）
    exportable: bool = False
    # 票 2 起用来校验 content 字段的 JSON Schema；先留空表示这一版不做逐字段校验
    content_schema: dict[str, Any] | None = None


ITEMS: tuple[EventTypeSpec, ...] = (
    EventTypeSpec(
        event_type="pipeline.self_check",
        version=1,
        description=(
            "管道自检事件：只用来验证客户端到落库这条链路是否畅通，"
            "不进入任何业务统计，也不进入本人数据导出"
        ),
        correlation_fields=(),
        exportable=False,
    ),
)

BY_KEY: dict[tuple[str, int], EventTypeSpec] = {
    (item.event_type, item.version): item for item in ITEMS
}


def is_registered(event_type: str, version: int) -> bool:
    return (event_type, version) in BY_KEY
