"""页面描述协议 1.0 的 Pydantic 类型。

这些类型只是协议信封在 Python 里的类型提示，供 FastAPI 生成 OpenAPI/Dart 类型用。
协议真正的、两端共用的定义是 `contracts/ui_protocol/schema/1.0/page_description.schema.json`
（见 `docs/adr/0005-界面描述协议共享契约.md`）；组合接口返回前还会用
`gramtree.ui_protocol.schema_validation` 把这里序列化出的 dict 按那份 Schema 再校验一次，
两者出现分歧时以 Schema 校验为准。
"""

import uuid
from typing import Any, Literal

from pydantic import BaseModel, Field

from gramtree.core.time import Timestamp
from gramtree.events.registry import SourceType

DetailLevel = Literal["brief", "standard", "detailed"]

# 兜底原因代码，票 3（#79）用；#77 阶段只在文档里登记，服务端还不会主动返回它们。
FallbackReasonCode = Literal[
    "unknown_major",
    "unknown_component",
    "illegal_action",
    "invalid_data",
    "missing_required",
    "server_error",
    "timeout",
]


class ActionDescriptor(BaseModel):
    intent: str = Field(description="已登记的意图名（SPEC-009.1 #81）")
    params: dict[str, Any] = Field(default_factory=dict)


class ComponentReason(BaseModel):
    code: str = Field(description="理由代码，例如 default")
    text: str = Field(description="给人看的一句话说明")


class ComponentDescriptor(BaseModel):
    type: str = Field(description="组件类型名，必须是 App 声明支持的组件")
    id: str = Field(description="这份描述里的组件实例 ID")
    detail: DetailLevel
    data: dict[str, Any] = Field(description="组件数据，形状由该 type 的组件 Schema 定义")
    actions: list[ActionDescriptor] = Field(default_factory=list)
    reason: ComponentReason
    required: bool = Field(default=False, description="是否是必显组件")


class CacheInfo(BaseModel):
    depends_on: dict[str, str] = Field(default_factory=dict, description="依赖的内容版本")
    ttl_s: int = Field(ge=0, description="缓存有效期（秒）")


class ExperimentInfo(BaseModel):
    experiment: str
    variant: str


class FallbackInfo(BaseModel):
    reason_code: FallbackReasonCode


class PageDescription(BaseModel):
    protocol: str = Field(description="协议版本，大版本.小版本，例如 1.0")
    page_type: str
    composition_id: uuid.UUID
    generated_at: Timestamp
    cache: CacheInfo
    experiment: ExperimentInfo | None = None
    fallback: FallbackInfo | None = Field(
        default=None,
        description="非空表示这份描述是标准布局兜底，components 为空数组",
    )
    components: list[ComponentDescriptor] = Field(default_factory=list)


# —— SPEC-009.1 #82：来源标记与"为什么"面板 ——
#
# `SourcedValue` 是协议里"带来源的字段"这个通用形状：任何组件的 `data` 要给一个数值/
# 内容标来源时都照这个形状加字段（`SourceType` 取值见 CLAUDE.md 第 6 节 UI 规范/
# `gramtree.events.registry`）。这份 Schema 校验（App 端）不走这个 Pydantic 类型，走
# `contracts/ui_protocol/schema/1.0/components/source_demo.schema.json` 里同样形状的
# `source` 字段定义（两份定义都对应同一个形状，出现分歧时以 Schema 校验为准，见
# 文件顶部说明）——这里只有 `source_demo` 这一个组件用它，本子 SPEC 还没有真实的
# 换算内容，先用这一个测试专用组件驱动整条链路，见 `service.py` 的
# `_source_demo_component`。


class SourceBasis(BaseModel):
    """依据：只用等级、日期这类用户看得懂的信息，不含内部分数或精确统计
    （SPEC-010 开放边界，#82 明确要求）。"""

    reason_code: str = Field(description="理由代码，供程序判断用")
    text: str = Field(description="一句大白话说明")
    citation: str | None = Field(
        default=None, description="来源引用，例如记录日期、口味档案变更、菜谱原文"
    )


class SourcedValue(BaseModel):
    source_type: SourceType
    value: str
    original_value: str | None = Field(
        default=None, description="换算/调整前的原值，只有真的发生换算/调整时才有"
    )
    basis: SourceBasis


class SkipAdjustmentRequest(BaseModel):
    component_id: str = Field(description="要去掉来源调整的组件实例 ID")


class SkipAdjustmentResult(BaseModel):
    """ "这次不用"的返回：去掉这条调整后的来源字段，只影响这次查看，不写口味档案。"""

    component_id: str
    source: SourcedValue
