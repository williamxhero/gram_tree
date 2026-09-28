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
"""

import logging

from fastapi import APIRouter
from pydantic import BaseModel, Field

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError
from gramtree.deps import RedisDep, SessionDep
from gramtree.ui_protocol import composition_events, experiments, service, validation
from gramtree.ui_protocol.protocol import PageDescription

logger = logging.getLogger("gramtree.ui_protocol")

router = APIRouter(prefix="/ui", tags=["ui-protocol"])


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

    try:
        assignment = (
            experiments.assign_today_experiment(session, auth.user.id)
            if body.page_type == "today"
            else experiments.NO_EXPERIMENT
        )
        description = service.compose(
            body.page_type,
            set(body.supported_components),
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
    return description
