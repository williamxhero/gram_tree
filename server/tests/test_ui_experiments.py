"""SPEC-009.1 票 8（#84）：组合实验分组——按用户稳定分组，不发新版就能试不同的组合。

选型和范围的说明在 `gramtree/ui_protocol/experiments.py` 顶部，这里只测外部行为：
接口返回的页面描述、经验层的"组合展示"事件、命令行改配置立刻生效。
"""

import json
import uuid

import pytest
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.events.models import Event
from gramtree.runtime_config import service as runtime_config_service
from gramtree.ui_protocol import experiments, page_types
from tests.accounts_support import Api
from tests.test_ui_protocol import _compose

TWO_GROUPS = [
    {"name": "control", "ratio": 0.5, "variant": "default"},
    {"name": "more_detail", "ratio": 0.5, "variant": "more_detail"},
]


def _set_experiment_config(
    engine: Engine, groups: list[dict[str, object]], *, enabled: bool = True
) -> None:
    definition = {"enabled": enabled, "groups": groups}
    with Session(engine) as session:
        runtime_config_service.set_value(
            session,
            experiments.TODAY_EXPERIMENT_CONFIG_KEY,
            json.dumps(definition),
            "test",
            "SPEC-009.1 #84 测试",
        )


def _latest_composition_shown_event(engine: Engine) -> Event:
    with Session(engine) as session:
        event = (
            session.query(Event)
            .filter(Event.event_type == "ui.composition_shown")
            .order_by(Event.received_at.desc())
            .first()
        )
        assert event is not None
        session.expunge(event)
        return event


# —— 分桶函数本身的性质：确定性、落在 [0, 1)、大量样本下大致均匀 ——


def test_stable_bucket_is_deterministic_for_the_same_user_and_experiment() -> None:
    user_id = uuid.uuid4()
    first = experiments.stable_bucket(user_id, "some_experiment")
    second = experiments.stable_bucket(user_id, "some_experiment")
    assert first == second
    assert 0.0 <= first < 1.0


def test_stable_bucket_differs_across_experiments_for_the_same_user() -> None:
    user_id = uuid.uuid4()
    a = experiments.stable_bucket(user_id, "experiment_a")
    b = experiments.stable_bucket(user_id, "experiment_b")
    assert a != b


def test_stable_bucket_distribution_is_roughly_uniform() -> None:
    buckets = [experiments.stable_bucket(uuid.uuid4(), "uniformity_check") for _ in range(4000)]
    quartile_counts = [0, 0, 0, 0]
    for b in buckets:
        quartile_counts[min(int(b * 4), 3)] += 1
    # 不要求精确均匀（不做成脆弱的统计检验），只要求没有严重偏斜：4000 个样本落进
    # 4 个桶，理论上每桶 1000，允许 [700, 1300] 的误差。
    for count in quartile_counts:
        assert 700 <= count <= 1300, quartile_counts


# —— 实验关闭时（默认）完全不影响组合结果 ——


def test_experiment_disabled_by_default_leaves_composition_unaffected(api: Api) -> None:
    tokens = api.login("no-experiment-user@example.com")
    body = _compose(api, tokens).json()
    assert body["experiment"] is None


# —— 同一用户多次请求分组稳定；不同用户按比例分到不同组 ——


def test_same_user_gets_the_same_variant_across_multiple_requests(api: Api, engine: Engine) -> None:
    _set_experiment_config(engine, TWO_GROUPS)
    tokens = api.login("stable-user@example.com")
    variants = {_compose(api, tokens).json()["experiment"]["variant"] for _ in range(5)}
    assert len(variants) == 1


def test_different_users_are_spread_across_both_variants(api: Api, engine: Engine) -> None:
    _set_experiment_config(engine, TWO_GROUPS)
    # 20 次登录都来自 TestClient 同一个"IP"，超过验证码每日发送次数上限（默认 10）
    # 会被按 IP 限流拒发——这条限流和这张票要测的东西无关，调大它只是为了让测试能在
    # 一个用例里登录足够多不同用户。
    with Session(engine) as session:
        runtime_config_service.set_value(
            session, "auth.email_code_daily_limit", "1000", "test", "SPEC-009.1 #84 测试"
        )
    variants: set[str] = set()
    for i in range(20):
        tokens = api.login(f"spread-user-{i}@example.com")
        variants.add(_compose(api, tokens).json()["experiment"]["variant"])
    # 20 个不同用户、50/50 两组，两组都出现的概率极高（都落进同一组的概率是
    # 0.5**20，不会真的发生），不逐一比对具体人数，避免测试像统计检验一样脆弱。
    assert variants == {"default", "more_detail"}


# —— 描述和"组合展示"事件都带实验标识 ——


def test_description_and_composition_shown_event_carry_the_same_experiment_identifier(
    api: Api, engine: Engine
) -> None:
    _set_experiment_config(engine, TWO_GROUPS)
    tokens = api.login("carries-experiment@example.com")
    body = _compose(api, tokens).json()

    assert body["experiment"]["experiment"] == experiments.TODAY_EXPERIMENT_NAME
    assert body["experiment"]["variant"] in {"default", "more_detail"}

    event = _latest_composition_shown_event(engine)
    assert event.content["experiment"] == body["experiment"]


# —— 实验只改组件的详略，产生真实可观察的差异 ——


def test_more_detail_variant_raises_hint_bar_detail_level(api: Api, engine: Engine) -> None:
    _set_experiment_config(engine, [{"name": "all", "ratio": 1.0, "variant": "more_detail"}])
    tokens = api.login("more-detail-user@example.com")
    body = _compose(api, tokens).json()

    assert body["experiment"]["variant"] == "more_detail"
    hint_bar = next(c for c in body["components"] if c["type"] == "hint_bar")
    assert hint_bar["detail"] == "standard"  # 默认是 brief，这个变体改成 standard


def test_default_variant_matches_the_non_experiment_composition(api: Api, engine: Engine) -> None:
    _set_experiment_config(engine, [{"name": "all", "ratio": 1.0, "variant": "default"}])
    tokens = api.login("control-variant-user@example.com")
    body = _compose(api, tokens).json()

    assert body["experiment"]["variant"] == "default"
    hint_bar = next(c for c in body["components"] if c["type"] == "hint_bar")
    assert hint_bar["detail"] == "brief"


# —— 实验可通过配置项开关和调整，不需要发版 ——


def test_experiment_can_be_turned_off_via_config_without_a_release(
    api: Api, engine: Engine
) -> None:
    _set_experiment_config(engine, TWO_GROUPS, enabled=True)
    tokens = api.login("toggle-user@example.com")
    on_body = _compose(api, tokens).json()
    assert on_body["experiment"] is not None

    _set_experiment_config(engine, TWO_GROUPS, enabled=False)
    off_body = _compose(api, tokens).json()
    assert off_body["experiment"] is None


def test_invalid_experiment_config_shape_is_treated_as_disabled(api: Api, engine: Engine) -> None:
    # runtime_config 的 "json" 类型配置项不做深层校验（形状由取用方自己校验，见
    # experiments.py 顶部的选型说明），所以这个比例加起来不是 1 的值能被 set 进去；
    # 读的时候 ExperimentDefinition 校验不通过，当成"实验关闭"处理，不会让"今天"页
    # 出问题。
    _set_experiment_config(
        engine,
        [
            {"name": "a", "ratio": 0.3, "variant": "default"},
            {"name": "b", "ratio": 0.3, "variant": "more_detail"},
        ],
    )
    tokens = api.login("invalid-config-user@example.com")
    body = _compose(api, tokens).json()
    assert body["experiment"] is None


# —— 去掉必显组件的实验变体不会被下发 ——


def test_experiment_variant_that_drops_a_required_component_falls_back_to_standard_layout(
    api: Api, engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    # "今天"页现在没有必显组件（#79 的机制本身也是这么测的）：临时给它注册一个，
    # 再临时给实验加一个会去掉这个组件的变体，验证"配置里试图去掉必显组件的变体不
    # 生效"——挡住它的是 #79 那套 classify_invalid_description 必显校验，不是实验
    # 模块自己的代码。
    monkeypatch.setitem(
        page_types.BY_PAGE_TYPE,
        "today",
        page_types.PageTypeSpec("today", required_component_types=("hint_bar",)),
    )
    monkeypatch.setitem(
        experiments.TODAY_VARIANT_DROPPED_COMPONENTS,
        "no_hint_bar",
        frozenset({"hint_bar"}),
    )
    _set_experiment_config(engine, [{"name": "drop", "ratio": 1.0, "variant": "no_hint_bar"}])

    tokens = api.login("drops-required-user@example.com")
    resp = _compose(api, tokens)
    assert resp.status_code == 200, resp.text
    body = resp.json()

    assert body["components"] == []
    assert body["fallback"] == {"reason_code": "missing_required"}
    # 兜底描述不下发实验产出的（不合格的）组合结果，也就不带实验标识。
    assert body["experiment"] is None

    event = _latest_composition_shown_event(engine)
    assert event.content["is_fallback"] is True
    assert event.content["fallback_reason"] == "missing_required"
