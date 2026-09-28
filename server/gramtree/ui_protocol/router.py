"""界面组合接口：按 App 声明的协议版本和已登记组件清单，下发这次要渲染的页面描述。

#77 只有“今天”一种页面类型的默认组合，且只在这里做“组合结果必须合法”的兜底（500）；
#79 起扩展成“协议大版本不认识 / 未登记组件 / 数据不合格 / 缺必显组件 / 服务端报错 /
超时”都整页改用标准布局，仍然是同一个接口，不新开路由。
"""

from fastapi import APIRouter
from pydantic import BaseModel, Field

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError
from gramtree.ui_protocol import schema_validation, service
from gramtree.ui_protocol.protocol import PageDescription

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
def compose(body: ComposeRequest, auth: CurrentAuth) -> PageDescription:
    del auth  # 目前默认组合不区分用户；按场景组合（SPEC-009.2 #34）起才用到
    if body.page_type not in service.COMPOSERS:
        raise ApiError(404, "unknown_page_type", "没有这个页面类型", body.page_type)

    description = service.compose(body.page_type, set(body.supported_components))
    _validate_before_returning(description)
    return description


def _validate_before_returning(description: PageDescription) -> None:
    """服务端输出前按 Schema 校验一次（#18 的硬性要求）。校验不过说明组合模块自己
    产出的结果和协议契约不一致，属于服务端 bug，不下发。"""
    protocol_major = description.protocol
    dumped = description.model_dump(mode="json")
    try:
        schema_validation.validate_page_description(protocol_major, dumped)
        for component in dumped["components"]:
            schema_validation.validate_component_data(
                protocol_major, component["type"], component["data"]
            )
    except schema_validation.SchemaValidationFailed as exc:
        raise ApiError(
            500, "composition_invalid", "组合结果不符合协议", f"{exc.path}: {exc.message}"
        ) from exc
