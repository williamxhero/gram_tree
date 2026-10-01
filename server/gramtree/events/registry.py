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
from typing import Literal

from pydantic import BaseModel, Field


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


class RecipeVersionSavedContentV1(BaseModel):
    """`recipe.version_saved` v1：保存一版菜谱时由服务端登记。"""

    recipe_version_id: str
    previous_version_id: str | None = None
    edit_operations: list[dict[str, object]] = Field(default_factory=list)
    ai_assisted: bool = False


class SelfCheckContentV2(BaseModel):
    """`pipeline.self_check` v2：比 v1 多一个可选的 `note` 字段，用来验证版本兼容——
    v1、v2 都在支持期内，客户端用哪个版本上传都应该被正常接收。
    """

    ping: str
    note: str | None = None


class _RetiredDemoContent(BaseModel):
    ping: str


# —— SPEC-009.1 票 2（#78）：四种界面事件 ——
#
# 都通过 `EventCorrelationIds.ui_composition_id` 关联到产生它们的那次界面组合，
# 这里的 content 只放组合 ID 以外、和"这次界面交互本身"有关的字段。按 CLAUDE.md
# 第 3 节和 #82 的"开放边界"：content 里不出现内部分数、精确统计，只出现等级、
# 代码、一句话说明这类用户看得懂/程序可判断的信息。

# 来源标记的五种取值（CLAUDE.md 第 6 节 UI 规范 / #82）：作者填写、按你的口味换算、
# 按场景调整、AI 估算、已验证。打开"为什么"面板、来源反馈都会用到。
SourceType = Literal[
    "author_filled",
    "taste_adjusted",
    "scenario_adjusted",
    "ai_estimated",
    "verified",
]


class ComponentSummary(BaseModel):
    """组合展示事件里，一个组件的摘要：类型、详略、理由，不含组件实例 ID
    （实例 ID 是"这次渲染出的具体组件"，属于组件动作/为什么面板等事件，不属于
    "这次组合选了什么"）。"""

    type: str
    detail: Literal["brief", "standard", "detailed"]
    reason_code: str
    reason_text: str


class CompositionExperiment(BaseModel):
    experiment: str
    variant: str


class CompositionShownContentV1(BaseModel):
    """`ui.composition_shown` v1：服务端每次 `POST /v1/ui/compositions` 成功返回时
    写的那一条（`gramtree.ui_protocol.composition_events`），content 和接口返回的
    页面描述必须一致（组件类型、详略、理由）。"""

    page_type: str
    components: list[ComponentSummary] = Field(default_factory=list)
    experiment: CompositionExperiment | None = None
    is_fallback: bool = False
    fallback_reason: str | None = Field(
        default=None, description="非空表示这份组合是标准布局兜底，取值见票 3（#79）"
    )


class ComponentActionContentV1(BaseModel):
    """`ui.component_action` v1：组件上的动作被触发时记（#81 触发，这里先登记类型）。"""

    component_id: str = Field(description="这份页面描述里的组件实例 ID")
    intent: str = Field(description="已登记的意图名（#81）")


class WhyPanelOpenedContentV1(BaseModel):
    """`ui.why_panel_opened` v1：打开"为什么"面板时记（#82 触发，这里先登记类型）。"""

    component_id: str = Field(description="这份页面描述里的组件实例 ID")
    source_type: SourceType


class SourceFeedbackContentV1(BaseModel):
    """`ui.source_feedback` v1：在"为什么"面板里点"这次不用"或"以后别这样"时记
    （#82 触发，这里先登记类型）。"""

    component_id: str = Field(description="这份页面描述里的组件实例 ID")
    source_type: SourceType
    feedback: Literal["skip_once", "never_again"] = Field(
        description="skip_once＝这次不用（只影响这次查看，不写口味档案）；"
        "never_again＝以后别这样（写入来源反馈，由 SPEC-005.3/SPEC-009.2 消化）"
    )


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
    EventTypeSpec(
        event_type="recipe.version_saved",
        version=1,
        description="菜谱版本保存：版本快照不可变，记录上一版和作者/AI 编辑操作。",
        correlation_fields=("recipe_version_id",),
        exportable=True,
        content_schema=RecipeVersionSavedContentV1,
    ),
    EventTypeSpec(
        event_type="ui.composition_shown",
        version=1,
        description=(
            "界面组合展示：服务端每次成功返回一份页面描述时写一条，记这次选了哪些"
            "组件类型、详略、理由、是否命中实验分组、是否是标准布局兜底及兜底原因"
        ),
        correlation_fields=("ui_composition_id",),
        exportable=True,
        content_schema=CompositionShownContentV1,
    ),
    EventTypeSpec(
        event_type="ui.component_action",
        version=1,
        description="组件动作：组件上的一个动作（已登记意图）被触发时记",
        correlation_fields=("ui_composition_id",),
        exportable=True,
        content_schema=ComponentActionContentV1,
    ),
    EventTypeSpec(
        event_type="ui.why_panel_opened",
        version=1,
        description='打开"为什么"面板：点任意来源标记或组件的理由入口时记',
        correlation_fields=("ui_composition_id",),
        exportable=True,
        content_schema=WhyPanelOpenedContentV1,
    ),
    EventTypeSpec(
        event_type="ui.source_feedback",
        version=1,
        description='来源反馈：在"为什么"面板里点"这次不用"或"以后别这样"时记',
        correlation_fields=("ui_composition_id",),
        exportable=True,
        content_schema=SourceFeedbackContentV1,
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
