"""页面类型登记表：这个页面类型应该有哪些必显组件（SPEC-009.1 #79）。

`required_component_types` 里的组件类型如果最终没有出现在组合结果里，视为校验失败
（见 `gramtree.ui_protocol.service`）。#77 阶段还没有任何必显组件，`today` 先留空；
后续子 SPEC（食品安全提醒 #22、来源署名等）往这里加。
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class PageTypeSpec:
    page_type: str
    required_component_types: tuple[str, ...] = ()


ITEMS: tuple[PageTypeSpec, ...] = (PageTypeSpec("today"),)

BY_PAGE_TYPE: dict[str, PageTypeSpec] = {item.page_type: item for item in ITEMS}
