"""服务端认识的组件类型登记表。

服务端只会在组合结果里使用这里登记过的类型；是否真的下发给某个 App，还要看
App 请求时声明的“已登记组件清单”（协议信封校验、逐组件的 data 校验见
`gramtree.ui_protocol.schema_validation`，那边按 `contracts/ui_protocol/schema/<版本>/
components/<type>.schema.json` 校验）。

新增一个组件类型：在 `ITEMS` 里加一项，并在
`contracts/ui_protocol/schema/<版本>/components/<type>.schema.json` 加它的数据格式。
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class ComponentSpec:
    type: str
    description: str
    # 页面类型声明它必须出现哪些必显组件时用这个字段名标记（SPEC-009.1 #79）
    always_required: bool = False


ITEMS: tuple[ComponentSpec, ...] = (
    ComponentSpec("hint_bar", "提示条：结论 + 可选动作"),
    ComponentSpec("empty_state", "标准空态：结论 + 可选依据说明"),
)

BY_TYPE: dict[str, ComponentSpec] = {item.type: item for item in ITEMS}

KNOWN_COMPONENT_TYPES: frozenset[str] = frozenset(BY_TYPE)


def is_registered(component_type: str) -> bool:
    return component_type in BY_TYPE
