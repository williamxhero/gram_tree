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
