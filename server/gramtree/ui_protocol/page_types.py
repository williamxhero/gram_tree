"""页面类型登记表：这个页面类型应该有哪些必显组件（SPEC-009.1 #79）。

`required_component_types` 里的组件类型，如果组合结果里没有一个同类型、`required`
标成 `True` 的组件，视为校验失败（见 `gramtree.ui_protocol.validation.
classify_invalid_description`）——机制本身在 #79 就做完并有测试覆盖了（测试里临时
注册一个带必显组件要求的页面类型来验证），但目前还没有真正需要标必显的业务组件，
`today` 先留空；后续子 SPEC（食品安全提醒 #22、过敏提示、来源署名、隐私控制等）
往这里加对应的组件类型。
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class PageTypeSpec:
    page_type: str
    required_component_types: tuple[str, ...] = ()


ITEMS: tuple[PageTypeSpec, ...] = (PageTypeSpec("today"),)

BY_PAGE_TYPE: dict[str, PageTypeSpec] = {item.page_type: item for item in ITEMS}
