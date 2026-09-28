"""界面组合接口：按 App 声明的协议版本和已登记组件清单，下发这次要渲染的页面描述。

#77 只有"今天"一种页面类型的默认组合。#79 起：组合模块产出的结果如果不合格（协议大
版本不认识 / 未登记组件 / 数据不合格 / 缺必显组件），或者组合模块本身报错，都不下发
这份结果，改成用 service.build_fallback_description() 产出的标准布局兜底描述（同一个
响应形状，fallback 字段非空），仍然是同一个接口、200 响应，不新开路由、不改成 500——
"等待超过时限"由 App 端自己判断（组合请求本身没问题，只是 App 等不及了），不会经过
这个函数，两边各自记的兜底原因见 docs/adr/0005-界面描述协议共享契约.md 和
gramtree.ui_protocol.validation。

#84 起："今天"页会按 `gramtree.ui_protocol.experiments` 里那个测试用实验，把
`auth.user.id` 稳定分到一个组，把组要用的详略覆盖表传给 `service.compose`；实验
产出的组合结果和其他组合结果走的是同一条校验/兜底链路——变体如果配出了缺必显组件的
结果，一样会被 `validation.classify_invalid_description` 拦下，整页退回标准布局，
不会因为"这是实验"就绕过去。

#83 起：按用户 + 页面类型 + 场景 + 依赖版本缓存组合结果（见 `gramtree.ui_protocol.
cache` 模块顶部的设计说明），命中就直接返回上次的描述，不重新组合、不重新写
"组合展示"事件；没命中才走下面这条完整流程，算完之后把结果存进缓存。
"""

import logging

from fastapi import APIRouter
from pydantic import BaseModel, Field

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError
from gramtree.deps import RedisDep, SessionDep
from gramtree.ui_protocol import cache, composition_events, experiments, service, validation
from gramtree.ui_protocol.protocol import (
    PageDescription,
    SkipAdjustmentRequest,
    SkipAdjustmentResult,
)

logger = logging.getLogger("gramtree.ui_protocol")

router = APIRouter(prefix="/ui", tags=["ui-protocol"])

# "今天"页目前没有场景差异（按场景选择内容是 SPEC-009.2 #34 的事），组合缓存的
# "场景"维度先用这一个占位值；场景机制本身（不同场景不共享缓存）由
# gramtree.ui_protocol.cache 的单元测试用假场景值验证，不需要等真实场景接上就能
# 测（见票 7，#83）。
DEFAULT_SCENARIO = "default"


class ComposeRequest(BaseModel):
    page_type: str = Field(description="要哪个页面类型的组合，例如 today")
    protocol_version: str = Field(description="App 自己实现的协议版本，例如 1.0")
    supported_components: list[str] = Field(
        default_factory=list,
        description="App 已登记、认识的组件类型清单；服务端只会下发这里面的类型",
    )


@router.post(
    "/compositions",
    response_model=PageDescription,
    responses=ERROR_RESPONSES,
    summary="按 App 声明的协议版本和组件清单，下发一份页面描述（需要登录）",
)
def compose(
    body: ComposeRequest, auth: CurrentAuth, session: SessionDep, redis: RedisDep
) -> PageDescription:
    # 目前只有"今天"页有实验（按场景组合是 SPEC-009.2 #34 起才用到，#84 的测试用
    # 实验也只在这一个页面类型上验证），其他页面类型不分组、不带实验标识。每次组合
    # 都要在经验层记一条"组合展示"事件（票 2，#78），兜底时也一样要记（票 3，#79），
    # 记的是"是否兜底、兜底原因"，不是"这次请求本身失败了"。
    if body.page_type not in service.COMPOSERS:
        raise ApiError(404, "unknown_page_type", "没有这个页面类型", body.page_type)

    # 票 7（#83）：按用户 + 页面类型 + 场景 + 依赖版本查组合缓存（设计说明见
    # gramtree.ui_protocol.cache 模块顶部的文档）。`service.dependency_versions()`
    # 是"轻量版"——只读这次组合依赖哪些内容版本，不真的跑组合，查缓存不需要先付出
    # 一次完整组合的开销。
    depends_on = service.dependency_versions(body.page_type, session)
    key = cache.cache_key(auth.user.id, body.page_type, DEFAULT_SCENARIO, depends_on)
    cached = cache.get(redis, key)
    if cached is not None:
        # 命中缓存：不是"重新组合"，直接把上次算出来的那份描述（同一个
        # composition_id）再发一遍。不重新写"组合展示"事件——那条事件记的是"服务端
        # 刚刚决定了下发什么"，命中缓存时服务端什么决定都没做，只是把上次的决定又
        # 发了一遍，写第二条事件会让"组合展示"事件的次数和"用户实际看到过几次不同
        # 的组合结果"脱钩，污染依赖这条事件计数的分析（比如后续子 SPEC 要统计的
        # "展示次数"）。也不重新跑 experiments.assign_today_experiment()：分组结果
        # 本来就该稳定（stable_bucket），缓存住的描述已经带着上次分组时算出的
        # experiment 字段。
        return cached

    try:
        assignment = (
            experiments.assign_today_experiment(session, auth.user.id)
            if body.page_type == "today"
            else experiments.NO_EXPERIMENT
        )
        description = service.compose(
            body.page_type,
            set(body.supported_components),
            session=session,
            experiment=assignment.experiment,
            detail_overrides=assignment.detail_overrides,
            exclude_components=assignment.dropped_components,
        )
    except Exception:
        # 组合模块本身报错、或者实验分组时出了问题：不让这个错误往上冒（这个接口出
        # 任何问题都不能卡住做饭），记录下来方便排查，返回标准布局兜底
        # （SPEC-009.1 #79 的"服务端报错"）。
        logger.exception("组合页面 %s 时服务端报错，整页退回标准布局", body.page_type)
        description = service.build_fallback_description(body.page_type, "server_error")
    else:
        reason = validation.classify_invalid_description(description.model_dump(mode="json"))
        if reason is not None:
            description = service.build_fallback_description(body.page_type, reason)

    composition_events.record_composition_shown(session, redis, auth.user.id, description)
    # 兜底描述（ttl_s=0）不会真的被写进去，见 cache.set_() 的说明——下次请求还是会
    # 重新走一遍完整流程，不会一直下发同一份兜底结果。
    cache.set_(redis, key, description)
    return description


@router.post(
    "/compositions/skip-adjustment",
    response_model=SkipAdjustmentResult,
    responses=ERROR_RESPONSES,
    summary='"这次不用"：返回去掉这条来源调整后的结果，只影响这次查看，不写口味档案（需要登录）',
)
def skip_adjustment(body: SkipAdjustmentRequest, auth: CurrentAuth) -> SkipAdjustmentResult:
    # SPEC-009.1 #82：App 端"为什么"面板里点"这次不用"时调用（走票 5 的意图派发，
    # 意图处理器直接调这个接口，不另写处理路径）。这是一次独立于组合缓存/组合展示
    # 事件之外的轻量重算——不查、不写组合缓存，不记"组合展示"事件（没有产生新的一份
    # 页面组合决定，只是把某个组件里的一条调整去掉重算），也不落库、不改任何"口味
    # 档案"（本子 SPEC 范围内还没有真正的口味档案概念，`service.
    # skip_source_demo_adjustment` 本身也确实没有调用任何写档案的代码路径）——这正是
    # "只影响这次查看"的含义。本子 SPEC 只有 source_demo 这一个测试用组件接了这条
    # 链路，其它 component_id 一律 404。
    result = service.skip_source_demo_adjustment(body.component_id)
    if result is None:
        raise ApiError(
            404,
            "unknown_component",
            "没有这个组件实例的来源调整可以去掉",
            body.component_id,
        )
    return result
