"""SPEC-009.1 票 1（#77）：页面描述协议 1.0，“今天”空态页走通默认组合。"""

import uuid

from fastapi.testclient import TestClient
from httpx import Response

from gramtree.ui_protocol import schema_validation
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
