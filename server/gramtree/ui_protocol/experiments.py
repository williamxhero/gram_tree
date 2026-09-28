"""SPEC-009.1 票 8（#84）：组合实验分组——不发新版就能给不同用户试不同的组合。

选型说明（实验配置存在哪）：票面给了两个方向，这里选 (a)，理由：

    (a) 扩展 `runtime_config` 的 `ValueType` 增加一种 "json"，把整个实验定义
        （分组名、比例、变体）存成一个配置项的值。
    (b) 给实验配置单独开一张表/一个新模块，不复用 `ConfigItem` 的标量假设。

选 (a)：`runtime_config.models.ConfigValue.value` 这一列本来就是 JSONB（见
`gramtree/runtime_config/models.py`），数据库层完全不用改；`ConfigItem`/
`registry.ITEMS`/`service.get`/`service.set_value`/`gramtree config set` 这套"一个
key 对应一个值、改了立刻生效、留历史"的读写入口已经现成，只是把值从标量换成一个
dict，不需要新建表、新的 CRUD、新的 CLI 子命令，也不需要给"实验"发明一套独立的权限
和审计（`ConfigChange` 已经记了谁在什么时候把值从什么改成什么）。代价是
`runtime_config` 层本身不校验这个 dict 的内部形状（分组比例加起来是不是 1、变体名
是不是登记过），这层校验放在这个模块（`ExperimentDefinition`），读的时候校验，配置
被改成不合法形状时当成"实验关闭"处理（见 `load_today_experiment`），不会因为一个
实验配置写错就让整个页面失效。

本票的范围（票面原话）："本子 SPEC 用一个测试用实验在'今天'页上验证，不做效果统计
（SPEC-010.3）"——所以这里没有为"以后可能有更多实验、更多页面"做通用调度框架，只有
一个具体的 `today` 页实验（`TODAY_EXPERIMENT_NAME`）；以后要在别的页面加实验，照这个
模块的样子再加一个配置项 + 一段分组逻辑就够了，不提前抽象。

约束（票面原话）："实验只能改组件的组合和详略，不能改动固定骨架和必显内容；配置里
试图去掉必显组件的变体不生效"——这条不是靠这个模块的代码拦的：这个模块只产出"详略
覆盖表"喂给 `service.compose_today`，如果某个变体真的配出了"缺必显组件"的结果，拦
它的是 `gramtree.ui_protocol.validation.classify_invalid_description`（#79 已经做好、
`router.compose()` 每次都会跑一遍的那道检查），不合格就整页退回标准布局，和"组合模块
本身产出了非法结果"走的是同一条兜底路径，不为实验单开一条。
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass, field
from typing import Any

from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from gramtree.runtime_config import service as runtime_config_service
from gramtree.ui_protocol.protocol import DetailLevel, ExperimentInfo

# 今天页测试用的实验：验证"配置能开关实验、用户按比例稳定分组、页面描述和展示事件
# 带实验标识、变体不能绕过必显校验"这整条链路，不做效果统计（那是 SPEC-010.3 的事）。
TODAY_EXPERIMENT_NAME = "today_composition_detail"
TODAY_EXPERIMENT_CONFIG_KEY = "ui.experiment.today_composition"

# 变体名 -> 组件类型 -> 详略覆盖。没在这里列出的组件类型、没在这里列出的变体名，
# 详略程度就是 `service.compose_today` 自己的默认值（等价于没有实验）。
# "default"/"more_detail" 两个变体只改 hint_bar/empty_state 的详略档位
# （brief/standard/detailed 是 #80 定的三档），不新增、不去掉任何组件，也不碰
# 这两个类型之外的任何东西——这就是"实验只能改组合和详略"这条约束在这个测试用实验
# 里的具体样子。
TODAY_VARIANT_DETAILS: dict[str, dict[str, DetailLevel]] = {
    "default": {},
    "more_detail": {"hint_bar": "standard", "empty_state": "standard"},
}

# 变体名 -> 这个变体要从组合结果里去掉哪些组件类型（"改组件的组合"里"组合"的部分）。
# 生产用的两个变体（"default"/"more_detail"）都不去掉任何组件；这张表留着是因为
# "实验能不能改变组件构成"本身要有地方落，而不是只能改详略。测试用
# `monkeypatch.setitem` 往这张表里临时塞一个会去掉必显组件的变体，验证
# "配置里试图去掉必显组件的变体不生效"这条约束——不是靠这里的代码挡住的，是配出的
# 结果照样要过 `validation.classify_invalid_description` 的必显校验，过不了就整页
# 退回标准布局（见 router.compose()）。
TODAY_VARIANT_DROPPED_COMPONENTS: dict[str, frozenset[str]] = {
    "default": frozenset(),
    "more_detail": frozenset(),
}


@dataclass(frozen=True)
class TodayExperimentAssignment:
    """一次组合请求，"今天"页实验给它算出来的结果：要不要带实验标识、要怎么改
    `service.compose_today` 的详略和组件构成。没分到任何组（实验关闭）时三个字段
    分别是 `None`、空字典、空集合——组合结果和完全没有这个实验时一样。
    """

    experiment: ExperimentInfo | None
    detail_overrides: dict[str, DetailLevel] = field(default_factory=dict)
    dropped_components: frozenset[str] = frozenset()


NO_EXPERIMENT = TodayExperimentAssignment(experiment=None)


class ExperimentGroup(BaseModel):
    name: str = Field(min_length=1)
    ratio: float = Field(gt=0, le=1)
    variant: str = Field(min_length=1)


class ExperimentDefinition(BaseModel):
    """一个实验的定义——`ui.experiment.today_composition` 这个配置项的值按这个形状
    校验。`enabled=False` 或 `groups` 为空都等价于"这个实验不生效"。
    """

    enabled: bool = False
    groups: tuple[ExperimentGroup, ...] = ()

    @field_validator("groups")
    @classmethod
    def _groups_are_sane(cls, groups: tuple[ExperimentGroup, ...]) -> tuple[ExperimentGroup, ...]:
        if not groups:
            return groups
        names = [g.name for g in groups]
        if len(names) != len(set(names)):
            raise ValueError("分组名不能重复")
        total = sum(g.ratio for g in groups)
        if abs(total - 1.0) > 1e-9:
            raise ValueError(f"分组比例之和必须是 1，收到 {total}")
        return groups


def stable_bucket(user_id: uuid.UUID, experiment_name: str) -> float:
    """把"用户 ID + 实验名"映射到 `[0, 1)` 区间的一个确定性的数：同一个输入，不管
    是这次请求还是下次请求、这个进程还是另一个进程，算出来的都一样——所以不能用
    Python 内置的 `hash()`（按进程加了随机盐，同一用户在不同请求里会落到不同的桶，
    没法"稳定分组"）。用 sha256 摘要的前 15 个十六进制位（60 bit）换算成浮点数，
    分辨率远超这里需要的分桶粒度。
    """
    digest = hashlib.sha256(f"{user_id}:{experiment_name}".encode()).hexdigest()
    return int(digest[:15], 16) / float(16**15)


def _pick_group(definition: ExperimentDefinition, bucket: float) -> ExperimentGroup | None:
    if not definition.enabled or not definition.groups:
        return None
    cumulative = 0.0
    for group in definition.groups:
        cumulative += group.ratio
        if bucket < cumulative:
            return group
    # 浮点误差兜底：比例之和已经在 ExperimentDefinition 里校验过等于 1，正常不会走到
    # 这里，走到了就归给最后一组。
    return definition.groups[-1]


def load_today_experiment(session: Session) -> ExperimentDefinition:
    raw: Any = runtime_config_service.get(session, TODAY_EXPERIMENT_CONFIG_KEY)
    try:
        return ExperimentDefinition.model_validate(raw)
    except Exception:
        # 配置被改成了不合法的形状（比例加起来不是 1、分组名重复、类型不对……）：
        # 当成"实验关闭"处理，不能因为一个实验配置写错就让"今天"页整个失效——真正
        # 想开实验的人会看到 `gramtree config set` 报错（不合法值 set 不进去），能
        # 走到这里，说明数据库里已经存了一个不合法的值，这条是双保险。
        return ExperimentDefinition(enabled=False, groups=())


def assign_today_experiment(session: Session, user_id: uuid.UUID) -> TodayExperimentAssignment:
    """算出这次组合要带的实验标识、详略覆盖表、要去掉的组件类型。实验关闭、或者定义
    读不出来时返回 `NO_EXPERIMENT`——组合结果和完全没有这个实验时一样。按用户稳定
    分组：同一个 `user_id` 只要配置没变，`stable_bucket` 每次算出来的桶位置一样，
    落在同一个分组里。
    """
    definition = load_today_experiment(session)
    bucket = stable_bucket(user_id, TODAY_EXPERIMENT_NAME)
    group = _pick_group(definition, bucket)
    if group is None:
        return NO_EXPERIMENT
    return TodayExperimentAssignment(
        experiment=ExperimentInfo(experiment=TODAY_EXPERIMENT_NAME, variant=group.variant),
        detail_overrides=TODAY_VARIANT_DETAILS.get(group.variant, {}),
        dropped_components=TODAY_VARIANT_DROPPED_COMPONENTS.get(group.variant, frozenset()),
    )
