"""组合模块：按页面类型和 App 声明的已登记组件清单，产出一份页面描述。

#77 只有“默认组合”——内容和标准布局一致，每个组件理由都是“默认”。按场景选择内容的
规则在 SPEC-009.2（#34）加；这里的 `COMPOSERS` 是以后新增页面类型时注册组合函数的地方。
"""

from collections.abc import Callable
from uuid import uuid4

from gramtree.core.time import utcnow
from gramtree.ui_protocol.protocol import (
    ActionDescriptor,
    CacheInfo,
    ComponentDescriptor,
    ComponentReason,
    FallbackInfo,
    FallbackReasonCode,
    PageDescription,
)

PROTOCOL_VERSION = "1.0"


def compose_today(supported_components: set[str]) -> PageDescription:
    candidates = [
        ComponentDescriptor(
            type="hint_bar",
            id="c1",
            detail="brief",
            data={"conclusion": "先添加一道你常做的菜"},
            actions=[ActionDescriptor(intent="open_page", params={"page": "create"})],
            reason=ComponentReason(code="default", text="默认组合"),
            required=False,
        ),
        ComponentDescriptor(
            type="empty_state",
            id="c2",
            detail="standard",
            data={
                "conclusion": "今天还没有安排",
                "basis": {"text": "这里会显示今天要做的菜"},
                "action_label": "添加第一道菜谱",
            },
            actions=[ActionDescriptor(intent="open_page", params={"page": "create"})],
            reason=ComponentReason(code="default", text="默认组合"),
            required=False,
        ),
    ]
    selected = [c for c in candidates if c.type in supported_components]
    return PageDescription(
        protocol=PROTOCOL_VERSION,
        page_type="today",
        composition_id=uuid4(),
        generated_at=utcnow(),
        cache=CacheInfo(depends_on={"plan": "v0"}, ttl_s=600),
        experiment=None,
        components=selected,
    )


COMPOSERS: dict[str, Callable[[set[str]], PageDescription]] = {
    "today": compose_today,
}


def compose(page_type: str, supported_components: set[str]) -> PageDescription:
    return COMPOSERS[page_type](supported_components)


def build_fallback_description(page_type: str, reason_code: FallbackReasonCode) -> PageDescription:
    """出任何问题（协议大版本不认识、未登记组件、数据不合格、缺必显组件、服务端报错、
    超时）时整页改用标准布局，服务端下发的就是这份占位描述：`components` 为空数组，
    `fallback.reason_code` 说明原因（SPEC-009.1 #79）。App 收到 `fallback` 非空的描述
    时不渲染 `components`（反正是空的），直接显示写在 App 里的标准布局，两边看起来
    一样，不会因为服务端"没内容"和"出问题"两种情况显示不同的东西。"""
    return PageDescription(
        protocol=PROTOCOL_VERSION,
        page_type=page_type,
        composition_id=uuid4(),
        generated_at=utcnow(),
        cache=CacheInfo(depends_on={}, ttl_s=0),
        experiment=None,
        fallback=FallbackInfo(reason_code=reason_code),
        components=[],
    )
