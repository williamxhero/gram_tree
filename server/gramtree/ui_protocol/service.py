"""组合模块：按页面类型和 App 声明的已登记组件清单，产出一份页面描述。

#77 只有"默认组合"——内容和标准布局一致，每个组件理由都是"默认"。按场景选择内容的
规则在 SPEC-009.2（#34）加；这里的 `COMPOSERS` 是以后新增页面类型时注册组合函数的地方。

#84 起，组合函数额外接受 `experiment`（要写进页面描述的实验标识）、`detail_overrides`
（实验要改成什么详略档位，组件类型 -> 详略）、`exclude_components`（实验要去掉哪些
组件类型）——`router.compose()` 按 `gramtree.ui_protocol.experiments` 算好了传进来。
这个模块本身不知道、也不需要知道"实验"是什么，只是"有的话就用、没有就按原来的默认值
来"；实验分组、详略变体、组件增减的对照表在 `experiments.py` 里，"去掉必显组件的变体
不生效"这条约束也不是靠这里的代码挡住的——挡的是组合结果产出之后 `router.compose()`
仍然会跑的那道 #79 必显校验，见 `experiments.py` 顶部的选型说明。

#83 起，组合函数还接受 `session`，用来读这份组合"依赖"的内容版本（见下面
`dependency_versions()`）——这些版本值既写进响应的 `PageDescription.cache.
depends_on`（协议字段，App 端用来判断离线缓存是否还能用，见 SPEC-009.1 票 7），
也是 `router.compose()` 算组合缓存 key 的一部分。
"""

import hashlib
import json
from collections.abc import Callable, Collection, Mapping
from uuid import uuid4

from sqlalchemy.orm import Session

from gramtree.core.time import utcnow
from gramtree.recipes.schemas import RecipeDerived, RecipePersonalSafety, RecipeSafetyResult
from gramtree.runtime_config import service as runtime_config_service
from gramtree.ui_protocol import experiments
from gramtree.ui_protocol.protocol import (
    ActionDescriptor,
    CacheInfo,
    ComponentDescriptor,
    ComponentReason,
    DetailLevel,
    ExperimentInfo,
    FallbackInfo,
    FallbackReasonCode,
    PageDescription,
    SkipAdjustmentResult,
    SourceBasis,
    SourcedValue,
)

PROTOCOL_VERSION = "1.0"

# SPEC-009.1 #82：source_demo 是仅测试用的示例组件，验证"来源标记 -> 为什么面板 ->
# 反馈"这条链路；本子 SPEC 还没有真实的换算内容（真实换算是 SPEC-005.3 的事），这里
# 固定一个组件实例 ID 和固定的"调整前/调整后"两组值，够用来驱动整条链路的测试就够了。
SOURCE_DEMO_COMPONENT_ID = "c3"
_SOURCE_DEMO_ADJUSTED_VALUE = "3 g"
_SOURCE_DEMO_ORIGINAL_VALUE = "5 g"


def _source_demo_component(overrides: Mapping[str, DetailLevel]) -> ComponentDescriptor:
    return ComponentDescriptor(
        type="source_demo",
        id=SOURCE_DEMO_COMPONENT_ID,
        detail=overrides.get("source_demo", "standard"),
        data={
            "conclusion": f"建议用盐 {_SOURCE_DEMO_ADJUSTED_VALUE}",
            "source": {
                "source_type": "taste_adjusted",
                "value": _SOURCE_DEMO_ADJUSTED_VALUE,
                "original_value": _SOURCE_DEMO_ORIGINAL_VALUE,
                "basis": {
                    "reason_code": "taste_profile_salt_down",
                    "text": "你最近几次做菜都调低了盐量",
                    "citation": "口味档案更新于 2026-09-20",
                },
            },
        },
        actions=[],
        reason=ComponentReason(
            code="source_demo",
            text="仅用于测试来源标记链路的示例组件，不是真实换算",
        ),
        required=False,
    )


def skip_source_demo_adjustment(component_id: str) -> SkipAdjustmentResult | None:
    """ "这次不用"（SPEC-009.1 #82）：去掉 source_demo 示例组件的换算调整，返回退回
    原值后的结果；只影响这次查看（调用方不落库、不写缓存），不写口味档案——本子 SPEC
    范围内还没有真正的口味档案概念，这个函数本身也确实没有调用任何写档案的代码路径。
    只认识这一个测试用组件 ID；其它 component_id 返回 None，由路由层转成 404。"""
    if component_id != SOURCE_DEMO_COMPONENT_ID:
        return None
    return SkipAdjustmentResult(
        component_id=component_id,
        source=SourcedValue(
            source_type="author_filled",
            value=_SOURCE_DEMO_ORIGINAL_VALUE,
            basis=SourceBasis(
                reason_code="skip_adjustment",
                text="已去掉按你的口味换算的调整，显示菜谱原文用量",
            ),
        ),
    )


# 组合缓存机制验证用的测试依赖（票 7，#83）：不对应任何真实业务数据，见
# runtime_config.registry 里这个配置项的登记说明。
TEST_DEPENDENCY_VERSION_CONFIG_KEY = "ui.cache.test_dependency_version"


def _today_dependency_versions(session: Session) -> dict[str, str]:
    """ "今天"页这次组合依赖的内容版本，算 `CacheInfo.depends_on` 和组合缓存 key
    用的是同一份值（`compose_today()` 和 `dependency_versions()` 都调这个函数），
    不会出现两处算法不同步的问题。

    - `plan`：#77 起就有的占位版本，还没有接真实数据，恒为 `"v0"`。
    - `test_dependency`：这张票（#83）加的测试专用维度，读自
      `ui.cache.test_dependency_version` 配置项——`runtime_config` 改完立刻生效
      （不用重启、不用发版），测试改这个值就能验证"依赖版本变了 -> 缓存 key 变了
      -> 拿到新的组合结果"这条链路，见 `test_ui_composition_cache.py`。
    - `experiment_config`：今天页的组合结果会因为
      `gramtree.ui_protocol.experiments` 的实验配置而不同（详略、要不要带
      `experiment` 字段），实验配置本身也是"影响组合结果的一项依赖"，所以把它的
      内容摘要也算进版本——不这样做的话，命中缓存会跳过 `experiments.
      assign_today_experiment()`，管理员改了实验配置（开关实验、调整分组）后，
      用户短时间内还会看到缓存里旧版本的组合结果，"改配置立刻生效"这条约束
      （SPEC-009.1 #84）就会被缓存破坏。取的是配置值的 sha256 摘要而不是原始
      JSON，避免配置值本身过长或包含缓存 key 不允许出现的字符。
    """
    test_dependency = runtime_config_service.get(session, TEST_DEPENDENCY_VERSION_CONFIG_KEY)
    experiment_config = runtime_config_service.get(session, experiments.TODAY_EXPERIMENT_CONFIG_KEY)
    experiment_config_digest = hashlib.sha256(
        json.dumps(experiment_config, sort_keys=True, default=str).encode()
    ).hexdigest()[:16]
    return {
        "plan": "v0",
        "test_dependency": str(test_dependency),
        "experiment_config": experiment_config_digest,
    }


# 页面类型 -> 算这次组合依赖版本的函数。目前只有"今天"页登记；新页面类型接入真实
# 依赖时照这个样子加一个解析函数（没有登记的页面类型 `dependency_versions()`
# 返回空字典，组合结果仍然可以缓存，只是没有任何依赖维度）。
DEPENDENCY_RESOLVERS: dict[str, Callable[[Session], dict[str, str]]] = {
    "today": _today_dependency_versions,
}


def dependency_versions(page_type: str, session: Session) -> dict[str, str]:
    """在真正跑组合之前，先算出这次要用的依赖版本——`router.compose()` 用这份
    "轻量版"结果去查组合缓存，只有没命中才会调用完整的 `compose()`。这里只读
    版本号（配置项、以后的数据版本字段），不做任何组合逻辑，开销远小于真正的组合
    （尤其是以后接入 AI 推荐这类开销更大的依赖之后）。
    """
    resolver = DEPENDENCY_RESOLVERS.get(page_type)
    return dict(resolver(session)) if resolver else {}


def compose_recipe_safety(
    page_type: str,
    supported_components: set[str],
    *,
    session: Session,
    safety_context: tuple[RecipeSafetyResult, RecipeDerived] | None,
    personal_safety: RecipePersonalSafety | None = None,
    **_: object,
) -> PageDescription:
    """Compose mandatory safety sections from one owner-authorized saved version."""
    safety_result = safety_context[0] if safety_context is not None else None
    derived = safety_context[1] if safety_context is not None else None

    if safety_result is None:
        food_data = {
            "status": "unknown",
            "conclusion": "暂时无法确认食品安全信息。",
            "basis": "请确认食材处理和熟透程度；当前没有可用的保存版本检查结果。",
            "result": None,
        }
        allergen_data = {
            "status": "unknown",
            "conclusion": "暂时无法确认过敏原信息。",
            "basis": "请核对菜谱中的全部食材和替代品。",
            "result": None,
        }
    else:
        raw_result = safety_result.model_dump(mode="json")
        findings = [
            {
                "rule_id": item["rule_id"],
                "severity": item["severity"],
                "message": item["message"],
                "basis": item["basis"],
                "step_ids": item.get("step_ids", []),
                "ingredient_ids": item.get("ingredient_ids", []),
                "threshold_celsius": item.get("threshold_celsius"),
                "rest_minutes": item.get("rest_minutes"),
            }
            for item in raw_result.get("findings", [])
        ]
        rules_version = raw_result.get("rules_version", "unknown")
        checked_at = raw_result.get("checked_at", utcnow().isoformat())
        result = {
            "rules_version": rules_version,
            "checked_at": checked_at,
            "high_risk": bool(raw_result.get("high_risk", False)),
            "findings": findings,
        }
        food_conclusion = (
            "存在高风险食品安全提示"
            if result["high_risk"]
            else findings[0]["message"]
            if findings
            else "未发现特定的食品安全提醒；仍需按步骤确认熟透"
        )
        rule_version = raw_result.get("rules_version")
        food_data = {
            "status": "available",
            "conclusion": food_conclusion,
            "basis": f"按食品安全规则 {rule_version} 检查。"
            if rule_version
            else "按当前食品安全规则检查。",
            "result": result,
        }
        legacy_data = derived.model_dump(mode="json") if derived is not None else {}
        allergen_result = {
            "rules_version": rules_version,
            "checked_at": checked_at,
            "allergens": raw_result.get("allergens") or legacy_data.get("allergens") or [],
            "allergens_incomplete": bool(
                raw_result.get(
                    "allergens_incomplete", legacy_data.get("allergens_incomplete", False)
                )
            ),
            "replacement_allergens": raw_result.get("replacement_allergens") or [],
        }
        allergen_names = allergen_result["allergens"]
        allergen_conclusion = (
            "含有：" + "、".join(allergen_names)
            if allergen_names
            else "未从已收录信息中识别出过敏原"
        )
        if allergen_result["allergens_incomplete"]:
            allergen_conclusion += "；过敏原信息可能不完整"
        allergen_data = {
            "status": "available",
            "conclusion": allergen_conclusion,
            "basis": "根据此版本食材及替代品对应的标准食材信息推导。",
            "result": allergen_result,
        }
        if personal_safety is not None:
            allergen_data["personal_safety"] = personal_safety.model_dump(mode="json")

    candidates = [
        ComponentDescriptor(
            type="food_safety",
            id="recipe-food-safety",
            detail="standard",
            data=food_data,
            reason=ComponentReason(code="recipe_safety", text="依据所选保存版本的安全检查结果"),
            required=True,
        ),
        ComponentDescriptor(
            type="allergen_notice",
            id="recipe-allergen-notice",
            detail="standard",
            data=allergen_data,
            reason=ComponentReason(code="recipe_safety", text="依据所选保存版本的食材信息"),
            required=True,
        ),
    ]
    return PageDescription(
        protocol=PROTOCOL_VERSION,
        page_type=page_type,
        composition_id=uuid4(),
        generated_at=utcnow(),
        cache=CacheInfo(depends_on={}, ttl_s=0),
        experiment=None,
        components=[item for item in candidates if item.type in supported_components],
    )


def compose_today(
    supported_components: set[str],
    *,
    session: Session,
    experiment: ExperimentInfo | None = None,
    detail_overrides: Mapping[str, DetailLevel] | None = None,
    exclude_components: Collection[str] | None = None,
) -> PageDescription:
    overrides = detail_overrides or {}
    excluded = frozenset(exclude_components or ())
    candidates = [
        ComponentDescriptor(
            type="hint_bar",
            id="c1",
            detail=overrides.get("hint_bar", "brief"),
            data={"conclusion": "先添加一道你常做的菜"},
            actions=[ActionDescriptor(intent="open_page", params={"page": "create"})],
            reason=ComponentReason(code="default", text="默认组合"),
            required=False,
        ),
        ComponentDescriptor(
            type="empty_state",
            id="c2",
            detail=overrides.get("empty_state", "standard"),
            data={
                "conclusion": "今天还没有安排",
                "basis": {"text": "这里会显示今天要做的菜"},
                "action_label": "添加第一道菜谱",
            },
            actions=[ActionDescriptor(intent="open_page", params={"page": "create"})],
            reason=ComponentReason(code="default", text="默认组合"),
            required=False,
        ),
        _source_demo_component(overrides),
    ]
    selected = [c for c in candidates if c.type in supported_components and c.type not in excluded]
    return PageDescription(
        protocol=PROTOCOL_VERSION,
        page_type="today",
        composition_id=uuid4(),
        generated_at=utcnow(),
        cache=CacheInfo(depends_on=_today_dependency_versions(session), ttl_s=600),
        experiment=experiment,
        components=selected,
    )


COMPOSERS: dict[str, Callable[..., PageDescription]] = {
    "today": compose_today,
    "recipe_detail": lambda supported_components, **kwargs: compose_recipe_safety(
        "recipe_detail", supported_components, **kwargs
    ),
    "recipe_editor": lambda supported_components, **kwargs: compose_recipe_safety(
        "recipe_editor", supported_components, **kwargs
    ),
}


def compose(
    page_type: str,
    supported_components: set[str],
    *,
    session: Session,
    experiment: ExperimentInfo | None = None,
    detail_overrides: Mapping[str, DetailLevel] | None = None,
    exclude_components: Collection[str] | None = None,
    safety_context: tuple[RecipeSafetyResult, RecipeDerived] | None = None,
    personal_safety: RecipePersonalSafety | None = None,
) -> PageDescription:
    composer = COMPOSERS[page_type]
    if page_type in {"recipe_detail", "recipe_editor"}:
        return composer(
            supported_components,
            session=session,
            safety_context=safety_context,
            personal_safety=personal_safety,
        )
    return composer(
        supported_components,
        session=session,
        experiment=experiment,
        detail_overrides=detail_overrides,
        exclude_components=exclude_components,
    )


def _fallback_safety_components() -> list[ComponentDescriptor]:
    """Fixed safety skeleton used even when dynamic composition is rejected."""
    return [
        ComponentDescriptor(
            type="food_safety",
            id="recipe-food-safety",
            detail="standard",
            data={
                "status": "unknown",
                "conclusion": "暂时无法确认食品安全信息。",
                "basis": "请确认食材处理和熟透程度；安全提醒不能关闭。",
                "result": None,
            },
            reason=ComponentReason(code="fallback", text="标准安全布局，安全提醒不能关闭"),
            required=True,
        ),
        ComponentDescriptor(
            type="allergen_notice",
            id="recipe-allergen-notice",
            detail="standard",
            data={
                "status": "unknown",
                "conclusion": "暂时无法确认过敏原信息。",
                "basis": "请核对菜谱中的全部食材和替代品；过敏原信息可能不完整。",
                "result": None,
            },
            reason=ComponentReason(code="fallback", text="标准安全布局，过敏原提示不能关闭"),
            required=True,
        ),
    ]


def build_fallback_description(page_type: str, reason_code: FallbackReasonCode) -> PageDescription:
    """Build the standard layout after protocol/composition failure.

    Recipe pages retain both mandatory safety descriptors in the fallback body;
    the App also has the same fixed cards in its page-level standard layout.
    """
    return PageDescription(
        protocol=PROTOCOL_VERSION,
        page_type=page_type,
        composition_id=uuid4(),
        generated_at=utcnow(),
        cache=CacheInfo(depends_on={}, ttl_s=0),
        experiment=None,
        fallback=FallbackInfo(reason_code=reason_code),
        components=_fallback_safety_components()
        if page_type in {"recipe_detail", "recipe_editor"}
        else [],
    )
