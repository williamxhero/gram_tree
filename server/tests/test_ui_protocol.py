"""SPEC-009.1 票 1（#77）：页面描述协议 1.0，“今天”空态页走通默认组合。

票 2（#78）：每次组合都写一条“组合展示”事件，见文件末尾 `# —— 票 2 ——`。
"""

import uuid

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.events.models import Event
from gramtree.events.registry import BY_KEY, is_registered
from gramtree.ui_protocol import actions as actions_registry
from gramtree.ui_protocol import page_types, schema_validation, service, validation
from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape

ALL_COMPONENTS = ["hint_bar", "empty_state"]


def _compose(api: Api, tokens: dict, **overrides: object) -> Response:
    body = {
        "page_type": "today",
        "protocol_version": "1.0",
        "supported_components": ALL_COMPONENTS,
    }
    body.update(overrides)
    return api.client.post("/v1/ui/compositions", json=body, headers=bearer(tokens))


def test_compose_without_login_returns_401(client: TestClient) -> None:
    resp = client.post(
        "/v1/ui/compositions",
        json={"page_type": "today", "protocol_version": "1.0", "supported_components": []},
    )
    assert_error_shape(resp, 401, "unauthorized")


def test_compose_unknown_page_type_returns_404(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = _compose(api, tokens, page_type="no_such_page")
    error = assert_error_shape(resp, 404, "unknown_page_type")
    assert error["message"]


def test_today_default_composition_matches_shared_sample(api: Api) -> None:
    tokens = api.login("cook@example.com")
    resp = _compose(api, tokens)
    assert resp.status_code == 200, resp.text
    body = resp.json()

    sample = schema_validation.load_sample("valid", "today_default.json")
    assert body["protocol"] == sample["protocol"]
    assert body["page_type"] == sample["page_type"]
    assert body["cache"] == sample["cache"]
    assert body["experiment"] == sample["experiment"]
    assert body["components"] == sample["components"]
    # composition_id/generated_at 每次都不同，只校验形状
    assert uuid.UUID(body["composition_id"]).version == 4


def test_composition_id_is_new_every_call(api: Api) -> None:
    tokens = api.login("cook@example.com")
    first = _compose(api, tokens).json()["composition_id"]
    second = _compose(api, tokens).json()["composition_id"]
    assert first != second


def test_every_component_has_a_reason(api: Api) -> None:
    tokens = api.login("cook@example.com")
    body = _compose(api, tokens).json()
    assert body["components"], "默认组合至少应该有组件"
    for component in body["components"]:
        assert component["reason"]["code"]
        assert component["reason"]["text"]


def test_unsupported_component_is_not_sent(api: Api) -> None:
    tokens = api.login("cook@example.com")
    body = _compose(api, tokens, supported_components=["hint_bar"]).json()
    types = {c["type"] for c in body["components"]}
    assert types == {"hint_bar"}


def test_response_validates_against_shared_schema(api: Api) -> None:
    tokens = api.login("cook@example.com")
    body = _compose(api, tokens).json()
    # 不抛异常即通过：服务端接口已经在返回前校验过一次，这里是回归测试自己再校验一遍
    schema_validation.validate_page_description(body["protocol"], body)
    for component in body["components"]:
        schema_validation.validate_component_data(
            body["protocol"], component["type"], component["data"]
        )


def test_shared_valid_sample_passes_schema_validation() -> None:
    sample = schema_validation.load_sample("valid", "today_default.json")
    schema_validation.validate_page_description(sample["protocol"], sample)
    for component in sample["components"]:
        schema_validation.validate_component_data(
            sample["protocol"], component["type"], component["data"]
        )


# —— 票 2（#78）：每次组合写一条“组合展示”事件 ——


def _composition_events(engine: Engine) -> list[Event]:
    with Session(engine) as session:
        rows = (
            session.query(Event)
            .filter(Event.event_type == "ui.composition_shown")
            .order_by(Event.received_at)
            .all()
        )
        session.expunge_all()
        return rows


def test_every_composition_writes_a_composition_shown_event(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    body = _compose(api, tokens).json()

    events = _composition_events(engine)
    assert len(events) == 1
    event = events[0]
    assert event.type_version == 1
    assert event.correlation == {"ui_composition_id": body["composition_id"]}

    content = event.content
    assert content["page_type"] == body["page_type"]
    assert content["is_fallback"] is False
    assert content["fallback_reason"] is None
    assert content["experiment"] is None
    assert content["components"] == [
        {
            "type": c["type"],
            "detail": c["detail"],
            "reason_code": c["reason"]["code"],
            "reason_text": c["reason"]["text"],
        }
        for c in body["components"]
    ]

    # content 的形状也要符合登记表里登记的 v1 schema（这条事件走的是
    # events.service.upload，不经过 events.router.upload_events 的逐字段
    # 校验，这里补一道回归测试，防止手写的 content 字典和登记的 schema 走偏）。
    spec = BY_KEY[("ui.composition_shown", 1)]
    assert spec.content_schema is not None
    spec.content_schema.model_validate(content)


def test_each_composition_call_writes_its_own_event_with_matching_id(
    api: Api, engine: Engine
) -> None:
    tokens = api.login("cook@example.com")
    first = _compose(api, tokens).json()
    second = _compose(api, tokens).json()
    assert first["composition_id"] != second["composition_id"]

    events = _composition_events(engine)
    assert len(events) == 2
    ids = {e.correlation["ui_composition_id"] for e in events}
    assert ids == {first["composition_id"], second["composition_id"]}


def test_composition_shown_event_belongs_to_the_logged_in_user(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    me = api.client.get("/v1/me", headers=bearer(tokens)).json()
    _compose(api, tokens)

    events = _composition_events(engine)
    assert str(events[0].user_id) == me["id"]


# —— 票 2（#78）：四种界面事件登记表 ——


def test_ui_event_types_are_registered_v1() -> None:
    for event_type in (
        "ui.composition_shown",
        "ui.component_action",
        "ui.why_panel_opened",
        "ui.source_feedback",
    ):
        assert is_registered(event_type, 1), event_type
        spec = BY_KEY[(event_type, 1)]
        assert spec.content_schema is not None
        assert spec.correlation_fields == ("ui_composition_id",)


def test_component_action_event_rejects_missing_fields(api: Api) -> None:
    tokens = api.login("cook@example.com")
    event = {
        "id": str(uuid.uuid4()),
        "event_type": "ui.component_action",
        "type_version": 1,
        "device_id": "device-1",
        "device_time": "2026-09-28T10:00:00+08:00",
        "app_version": "1.0.0",
        "correlation": {"ui_composition_id": str(uuid.uuid4())},
        "content": {"component_id": "c1"},  # 缺 intent
    }
    resp = api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    assert resp.status_code == 200
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "invalid_content"


def test_why_panel_opened_event_rejects_missing_fields(api: Api) -> None:
    tokens = api.login("cook@example.com")
    event = {
        "id": str(uuid.uuid4()),
        "event_type": "ui.why_panel_opened",
        "type_version": 1,
        "device_id": "device-1",
        "device_time": "2026-09-28T10:00:00+08:00",
        "app_version": "1.0.0",
        "correlation": {"ui_composition_id": str(uuid.uuid4())},
        "content": {"component_id": "c1"},  # 缺 source_type
    }
    resp = api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "invalid_content"


def test_source_feedback_event_accepts_valid_content_and_rejects_bad_feedback(
    api: Api, engine: Engine
) -> None:
    tokens = api.login("cook@example.com")
    composition_id = str(uuid.uuid4())
    good = {
        "id": str(uuid.uuid4()),
        "event_type": "ui.source_feedback",
        "type_version": 1,
        "device_id": "device-1",
        "device_time": "2026-09-28T10:00:00+08:00",
        "app_version": "1.0.0",
        "correlation": {"ui_composition_id": composition_id},
        "content": {
            "component_id": "c1",
            "source_type": "taste_adjusted",
            "feedback": "never_again",
        },
    }
    resp = api.client.post("/v1/events/upload", json={"events": [good]}, headers=bearer(tokens))
    assert resp.json()["results"][0]["status"] == "accepted"

    with Session(engine) as session:
        row = session.get(Event, uuid.UUID(good["id"]))
        assert row is not None
        assert row.content["feedback"] == "never_again"

    bad = {**good, "id": str(uuid.uuid4()), "content": {**good["content"], "feedback": "later"}}
    resp = api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))
    result = resp.json()["results"][0]
    assert result["status"] == "rejected"
    assert result["reason"]["code"] == "invalid_content"


# —— 票 3（#79）：标准布局兜底、超时和必显内容 ——

# 样例文件名 -> 期望的兜底原因代码。missing_required_component.json 不在这里：它本身
# 是 Schema 合法的描述，是不是不合法要看当时的页面类型规格是否要求必显组件（见
# app/assets/contracts/ui_protocol/README.md），单独测试。
INVALID_SAMPLE_REASONS = {
    "unknown_component.json": "unknown_component",
    "missing_field.json": "invalid_data",
    "illegal_action.json": "illegal_action",
    # SPEC-009.1 #81：意图是不是已登记、参数格式对不对，两边都判定成不合法。
    "unregistered_intent.json": "illegal_action",
    "invalid_action_params.json": "illegal_action",
    "arbitrary_url_action.json": "illegal_action",
    "unknown_major.json": "unknown_major",
}


def test_resolve_schema_major_dir() -> None:
    assert schema_validation.resolve_schema_major_dir("1.0") == "1.0"
    # 小版本兼容：同一大版本的更高小版本号映射到同一个起点目录
    assert schema_validation.resolve_schema_major_dir("1.7") == "1.0"
    # 没有对应目录的大版本、格式不对的版本号都视为“不认识的大版本”
    assert schema_validation.resolve_schema_major_dir("9.9") is None
    assert schema_validation.resolve_schema_major_dir("not-a-version") is None


def test_shared_invalid_samples_are_classified_with_expected_reason() -> None:
    for filename, expected_reason in INVALID_SAMPLE_REASONS.items():
        sample = schema_validation.load_sample("invalid", filename)
        assert validation.classify_invalid_description(sample) == expected_reason, filename


def test_shared_valid_sample_is_not_classified_as_invalid() -> None:
    sample = schema_validation.load_sample("valid", "today_default.json")
    assert validation.classify_invalid_description(sample) is None


def test_envelope_tolerates_unknown_field_within_same_major_version() -> None:
    """小版本兼容：同一大版本下出现 App 不认识的新字段时照常校验通过，不算失败。"""
    sample = schema_validation.load_sample("valid", "today_default.json")
    forward_compatible = {**sample, "protocol": "1.7", "future_field": "new-in-1.7"}
    major_dir = schema_validation.resolve_schema_major_dir(forward_compatible["protocol"])
    assert major_dir == "1.0"
    schema_validation.validate_page_description(major_dir, forward_compatible)
    assert validation.classify_invalid_description(forward_compatible) is None


def test_missing_required_component_sample_is_valid_when_nothing_requires_it() -> None:
    """`missing_required_component.json` 本身 Schema 合法；`today` 目前没有必显组件
    要求时它不算不合法——机制本身在下一个测试里用临时注册验证。"""
    sample = schema_validation.load_sample("invalid", "missing_required_component.json")
    assert validation.classify_invalid_description(sample) is None


def test_missing_required_component_detected_once_a_page_type_requires_it(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    sample = schema_validation.load_sample("invalid", "missing_required_component.json")
    monkeypatch.setitem(
        page_types.BY_PAGE_TYPE,
        "today",
        page_types.PageTypeSpec("today", required_component_types=("hint_bar",)),
    )
    assert validation.classify_invalid_description(sample) == "missing_required"


def test_compose_falls_back_to_standard_layout_when_composer_raises(
    api: Api, engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    tokens = api.login("cook@example.com")

    def boom(supported_components: set[str]) -> None:
        raise RuntimeError("组合模块炸了")

    monkeypatch.setitem(service.COMPOSERS, "today", boom)

    resp = _compose(api, tokens)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["components"] == []
    assert body["fallback"] == {"reason_code": "server_error"}

    events = _composition_events(engine)
    assert len(events) == 1
    assert events[0].content["is_fallback"] is True
    assert events[0].content["fallback_reason"] == "server_error"
    assert events[0].content["components"] == []


def test_compose_falls_back_to_standard_layout_when_a_required_component_is_missing(
    api: Api, engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """组合结果不合格（这里是缺必显组件）时不下发，改为返回可识别的兜底响应，并留下
    可查的记录（SPEC-009.1 #79）。`today` 默认组合里两个组件都不是必显组件
    （`required: false`），所以只要临时给 `today` 注册一个必显组件类型，默认组合
    就一定会缺它。"""
    tokens = api.login("cook@example.com")
    monkeypatch.setitem(
        page_types.BY_PAGE_TYPE,
        "today",
        page_types.PageTypeSpec("today", required_component_types=("hint_bar",)),
    )

    resp = _compose(api, tokens)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["components"] == []
    assert body["fallback"] == {"reason_code": "missing_required"}

    events = _composition_events(engine)
    assert len(events) == 1
    assert events[0].content["is_fallback"] is True
    assert events[0].content["fallback_reason"] == "missing_required"


def test_compose_default_result_is_not_flagged_as_fallback(api: Api, engine: Engine) -> None:
    tokens = api.login("cook@example.com")
    body = _compose(api, tokens).json()
    assert body.get("fallback") is None

    events = _composition_events(engine)
    assert events[0].content["is_fallback"] is False
    assert events[0].content["fallback_reason"] is None


# —— 票 5（#81）：动作即意图 ——


def test_action_registry_rejects_unregistered_intent() -> None:
    assert actions_registry.is_valid_action("delete_everything", {}) is False


def test_action_registry_open_page_only_accepts_registered_pages() -> None:
    assert actions_registry.is_valid_action("open_page", {"page": "create"}) is True
    assert actions_registry.is_valid_action("open_page", {}) is False
    assert (
        actions_registry.is_valid_action("open_page", {"page": "https://evil.example.com/steal"})
        is False
    )


def test_action_registry_validates_params_per_intent() -> None:
    assert actions_registry.is_valid_action("start_cooking", {"recipe_version_id": "rv-1"}) is True
    assert actions_registry.is_valid_action("start_cooking", {}) is False
    assert (
        actions_registry.is_valid_action("open_record_card", {"cooking_record_id": "cr-1"}) is True
    )
    assert actions_registry.is_valid_action("open_record_card", {}) is False
    assert actions_registry.is_valid_action("call_operation", {"operation": "op-1"}) is True
    assert actions_registry.is_valid_action("call_operation", {}) is False


def test_action_registry_defers_param_shape_for_not_yet_implemented_intents() -> None:
    """存进口味/应用改动/这次不用/以后别这样：这张票只登记名字，参数格式留给实现
    处理器的子 SPEC 收紧，这里先只要求已登记。"""
    for intent in (
        "save_to_taste",
        "apply_change",
        "skip_this_time",
        "dont_do_again",
    ):
        assert actions_registry.is_valid_action(intent, {"anything": 1}) is True
