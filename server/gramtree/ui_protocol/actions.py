"""服务端认识的意图登记表（SPEC-009.1 #81），镜像 App
`app/lib/ui_protocol/intent_registry.dart` 的 `defaultIntentRegistry`：名字和参数
格式两边要保持一致，登记表本身各写一份（和 `components.py`/`component_registry.dart`
的组件类型登记表、`page_types.py`/`page_types.dart` 的必显组件登记表是同一种分工）。

范围边界：这张表只用来在 `validation.classify_invalid_description` 里判断"一份
页面描述里的动作合不合法"——意图名有没有登记过、参数格式对不对；处理器（触发这个
意图真正要做的事）是 App 端的事，服务端不需要、也不会自己调用这些意图。
`REGISTERED_PAGES` 同理只是"打开页面"意图（`open_page`）的参数格式校验用得上的
页面名白名单，不是服务端自己认识的路由。

新增一个意图：在 `ITEMS` 里加一项，和 App 端的登记表保持同步。
"""

from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import dataclass
from typing import Any, get_args

from gramtree.events.registry import SourceType

_SOURCE_TYPES: frozenset[str] = frozenset(get_args(SourceType))

#: "打开页面"意图（`open_page`）能打开的页面名，和 App 端
#: `app/lib/ui_protocol/registered_pages.dart` 的 `registeredPages` 保持一致——只有
#: 这里登记过的名字算合法，其余一律不合法，包括任意网址。
REGISTERED_PAGES: frozenset[str] = frozenset({"create"})


def _require_non_empty_string(params: Mapping[str, Any], key: str) -> bool:
    value = params.get(key)
    return isinstance(value, str) and value != ""


def _validate_open_page(params: Mapping[str, Any]) -> bool:
    page = params.get("page")
    return isinstance(page, str) and page in REGISTERED_PAGES


def _validate_start_cooking(params: Mapping[str, Any]) -> bool:
    return _require_non_empty_string(params, "recipe_version_id")


def _validate_open_record_card(params: Mapping[str, Any]) -> bool:
    return _require_non_empty_string(params, "cooking_record_id")


def _validate_call_operation(params: Mapping[str, Any]) -> bool:
    return _require_non_empty_string(params, "operation")


def _accept_any_params(params: Mapping[str, Any]) -> bool:
    # 存进口味/应用改动：还没有实现处理器的子 SPEC 接手，先只登记名字，见 App 端
    # `intent_registry.dart` 里同样的说明。
    return True


def _validate_source_feedback(params: Mapping[str, Any]) -> bool:
    # 这次不用/以后别这样（SPEC-009.1 #82 收紧）：两个意图共用同一套参数格式——
    # `component_id`（这份页面描述里的组件实例 ID）和 `source_type`（登记过的来源
    # 类型之一），和 `WhyPanelOpenedContentV1`/`SourceFeedbackContentV1`
    # （`gramtree.events.registry`）要求的字段对应，App 端 `intent_registry.dart`
    # 的 `_validateSourceFeedback` 是同一套校验。
    return (
        _require_non_empty_string(params, "component_id")
        and params.get("source_type") in _SOURCE_TYPES
    )


@dataclass(frozen=True)
class ActionSpec:
    intent: str
    validate_params: Callable[[Mapping[str, Any]], bool]


ITEMS: tuple[ActionSpec, ...] = (
    ActionSpec("open_page", _validate_open_page),
    ActionSpec("start_cooking", _validate_start_cooking),
    ActionSpec("open_record_card", _validate_open_record_card),
    ActionSpec("call_operation", _validate_call_operation),
    ActionSpec("save_to_taste", _accept_any_params),
    ActionSpec("apply_change", _accept_any_params),
    ActionSpec("skip_this_time", _validate_source_feedback),
    ActionSpec("dont_do_again", _validate_source_feedback),
)

BY_INTENT: dict[str, ActionSpec] = {item.intent: item for item in ITEMS}


def is_valid_action(intent: str, params: Mapping[str, Any]) -> bool:
    """意图已登记且参数通过该意图的格式校验才算合法。"""

    spec = BY_INTENT.get(intent)
    return spec is not None and spec.validate_params(params)
