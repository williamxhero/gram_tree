"""判断一份页面描述该不该整页退回标准布局，以及退回原因（SPEC-009.1 #79）。

同一套判断逻辑用在两个地方：

- `router.compose()`：组合模块产出结果之后、返回给 App 之前的最后一道检查——不合格就
  不下发这份描述，改成 `service.build_fallback_description()` 产出的兜底描述。
- 服务端测试：直接对 `samples/invalid/` 里两端共用的样例跑一遍，确认判定的原因和
  App 端（`app/lib/ui_protocol/composition_provider.dart`）算出来的一样（见
  `docs/adr/0005-界面描述协议共享契约.md`）。

判断顺序特意和 App 端保持一致，两边对同一份样例的判定才会一样：
    大版本认不认识 → 协议信封结构是否合法（含动作格式）→ 组件类型有没有登记过 →
    组件的 data 格式合不合法 → 组件的动作是不是已登记意图、参数格式对不对 →
    必显组件齐不齐全。

`illegal_action` 分两层判断（SPEC-009.1 #81 补齐第二层），和 App 端
`composition_provider.dart` 的 `fetchComposition` 保持一致：先是 Schema 校验错误
落在某个组件的 `actions` 字段上（比如 `intent` 缺失，信封结构本身不合法）；结构合法
之后再检查每个动作的 `intent` 是不是 `gramtree.ui_protocol.actions` 里登记过的意图名、
`params` 符不符合这个意图的参数格式——未登记的意图名、已登记但参数格式不对（含
`open_page` 想跳到一个没登记过的页面，任意网址也在这一层被拒绝）都算 `illegal_action`。
"""

from typing import Any, cast

from gramtree.ui_protocol import actions as actions_registry
from gramtree.ui_protocol import components as components_registry
from gramtree.ui_protocol import page_types, schema_validation
from gramtree.ui_protocol.protocol import FallbackReasonCode


def classify_invalid_description(dumped: dict[str, Any]) -> FallbackReasonCode | None:
    """`dumped` 是一份页面描述的原始 dict——`PageDescription.model_dump(mode="json")`
    的结果，或者直接从 `samples/invalid/` 读到的 JSON（不一定能解析成 `PageDescription`
    模型，比如缺字段的样例）。合法返回 `None`；不合法返回对应的 `FallbackReasonCode`。
    """
    protocol = dumped.get("protocol")
    if not isinstance(protocol, str):
        return "invalid_data"
    major_dir = schema_validation.resolve_schema_major_dir(protocol)
    if major_dir is None:
        return "unknown_major"

    try:
        schema_validation.validate_page_description(major_dir, dumped)
    except schema_validation.SchemaValidationFailed as exc:
        return "illegal_action" if _is_action_path(exc.path) else "invalid_data"

    components = dumped.get("components") or []
    for component in components:
        component_type = component.get("type") if isinstance(component, dict) else None
        if not isinstance(component_type, str) or not components_registry.is_registered(
            component_type
        ):
            return "unknown_component"
        data_raw = component.get("data")
        data = cast("dict[str, Any]", data_raw) if isinstance(data_raw, dict) else {}
        try:
            schema_validation.validate_component_data(major_dir, component_type, data)
        except schema_validation.SchemaValidationFailed:
            return "invalid_data"

        for action in component.get("actions") or []:
            intent = action.get("intent") if isinstance(action, dict) else None
            params_raw = action.get("params") if isinstance(action, dict) else None
            params = cast("dict[str, Any]", params_raw) if isinstance(params_raw, dict) else {}
            if not isinstance(intent, str) or not actions_registry.is_valid_action(intent, params):
                return "illegal_action"

    page_type = dumped.get("page_type")
    spec = page_types.BY_PAGE_TYPE.get(page_type) if isinstance(page_type, str) else None
    if spec is not None and spec.required_component_types:
        present_required_types = {
            component.get("type")
            for component in components
            if isinstance(component, dict) and component.get("required") is True
        }
        for required_type in spec.required_component_types:
            if required_type not in present_required_types:
                return "missing_required"

    return None


def _is_action_path(path: str) -> bool:
    return "actions" in path.split("/")
