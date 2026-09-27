"""事件类型登记表：每种经验层事件类型的唯一出处。

登记表回答三个问题：这种类型长什么样（字段、含义）、关联哪些 ID、要不要进用户本人的
数据导出。上传接口（`gramtree.events.router`）和校验逻辑（`gramtree.events.validation`）
都只认这张表，不允许旁路。

## 新增一种事件类型 / 新版本，照这几步做

1. 在下面 `ITEMS` 元组末尾加一个 `EventTypeSpec`：
   - `event_type` / `version`：新类型从 `version=1` 开始；已有类型要出新版本时，新加一项
     `version=旧版本号+1`，**不要改动、不要删除旧版本那一项**——类型版本只增不改，旧版本
     在被标记停止支持之前一直照常接收。
   - `description`：给后面看这张表的人看的一句话说明。
   - `correlation_fields`：这个类型会用到 `events.router.EventCorrelationIds` 里的哪些
     字段名（例如 `"plan_id"`），纯文档用途，上传时不会拿它做强制校验。
   - `exportable`：是否进用户本人的数据导出（SPEC-011 之后用到）。
   - `content_schema`：一个 `pydantic.BaseModel` 子类，字段就是这个类型的 `content` 里
     应该有哪些字段、什么类型。上传时用 `content_schema.model_validate(content)` 校验，
     校验不过的事件被逐条拒收（原因码 `invalid_content`，答复里不回显事件内容，只带
     字段路径和错误类型）。留 `None` 表示这个类型不校验 `content`（不建议，只在过渡期用）。
   - `supported`：默认 `True`。一个版本正式停止支持时，把已有登记项的这个字段改成
     `False`（不要删除、不要改其它字段）；停止支持之后这个版本的事件会被拒收，原因码
     `unsupported_version`。
2. 不需要改这个文件里的其它地方：`BY_KEY`、`KNOWN_EVENT_TYPES` 都是从 `ITEMS` 自动派生的。
"""

from dataclasses import dataclass

from pydantic import BaseModel


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
    # 用来逐字段校验 content 的 pydantic model；None 表示这一版不做逐字段校验
    content_schema: type[BaseModel] | None = None
    # 这个版本是否还接收新事件；正式停止支持后改成 False，事件会被拒收（不要删除登记项）
    supported: bool = True


class SelfCheckContentV1(BaseModel):
    """`pipeline.self_check` v1 的 content：只用来验证链路是否畅通。"""

    ping: str


class SelfCheckContentV2(BaseModel):
    """`pipeline.self_check` v2：比 v1 多一个可选的 `note` 字段，用来验证版本兼容——
    v1、v2 都在支持期内，客户端用哪个版本上传都应该被正常接收。
    """

    ping: str
    note: str | None = None


class _RetiredDemoContent(BaseModel):
    ping: str


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
        content_schema=SelfCheckContentV1,
    ),
    EventTypeSpec(
        event_type="pipeline.self_check",
        version=2,
        description=(
            "管道自检事件 v2：在 v1 基础上加了可选的 note 字段，"
            "用来验证同一类型新旧版本能否在支持期内同时被接收"
        ),
        correlation_fields=(),
        exportable=False,
        content_schema=SelfCheckContentV2,
    ),
    EventTypeSpec(
        event_type="pipeline.retired_demo",
        version=1,
        description=(
            "仅用于测试“已停止支持的版本被拒收”这条验收标准的示例登记项，"
            "不是真实业务事件类型，不要在客户端里使用"
        ),
        correlation_fields=(),
        exportable=False,
        content_schema=_RetiredDemoContent,
        supported=False,
    ),
)

BY_KEY: dict[tuple[str, int], EventTypeSpec] = {
    (item.event_type, item.version): item for item in ITEMS
}

# 所有登记过至少一个版本的事件类型名字，用来区分“类型完全没登记过”
# 和“类型登记过，但没登记这个版本”这两种不同的拒收原因
KNOWN_EVENT_TYPES: frozenset[str] = frozenset(item.event_type for item in ITEMS)


def is_registered(event_type: str, version: int) -> bool:
    return (event_type, version) in BY_KEY
