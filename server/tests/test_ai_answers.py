"""Version questions through HTTP, using synthetic recordings and operator audit."""

import copy
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import cli, configure, recording
from tests.test_recipes import recipe_input

QUESTION = "鸡肉为什么要炒熟？"
ANSWER = {
    "state": "answered",
    "kitchen_scope": True,
    "confidence": 0.9,
    "conclusion": "这版鸡肉只写表面变白，不能据此判断中心熟透。",
    "explanation": "鸡肉需检查中心温度达到 74°C，锅温和表面颜色不能代替中心温度。",
    "details": "这是解释，不会替你修改步骤；需要改动时请使用表单并确认保存。",
}


def payload(detail: dict, question: str = QUESTION) -> dict:
    snapshot = detail["version"]["snapshot"]
    return {
        "stage": "recipe_question",
        "question": question,
        "context": {
            "dish_name": detail["dish"]["name"],
            "servings": snapshot["servings"],
            "ingredients": [
                {k: item[k] for k in ("id", "display_name", "quantity", "unit", "preparation")}
                for item in snapshot["ingredients"]
            ],
            "steps": [
                {
                    k: step[k]
                    for k in (
                        "id",
                        "action",
                        "instruction",
                        "ingredient_ids",
                        "duration_seconds",
                        "heat",
                        "temperature_celsius",
                        "cookware",
                        "doneness",
                    )
                }
                for step in snapshot["steps"]
            ],
        },
        "basis": "general_experience",
        "evidence": None,
        "policy_version": "recipe-answer-v1",
    }


@pytest.fixture
def replay_answers(monkeypatch, tmp_path: Path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


def ask(api: Api, headers: dict, detail: dict, question: str = QUESTION):
    return api.client.post(
        f"/v1/ai/recipes/{detail['id']}/versions/{detail['version']['id']}/answer",
        headers=headers,
        json={"question": question},
    )


def create(api: Api, email: str = "answer@example.com"):
    headers = bearer(api.login(email))
    response = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert response.status_code == 201, response.text
    return headers, response.json()


def test_general_experience_answer_preserves_version_and_shows_required_risks(
    replay_answers: Path, api: Api
):
    headers, detail = create(api)
    recording(replay_answers, "explain", payload(detail), ANSWER)
    before = api.client.get(f"/v1/recipes/{detail['id']}", headers=headers).json()
    response = ask(api, headers, detail)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["state"] == "answered"
    assert result["basis"] == "general_experience"
    assert result["source"] == "ai_estimated"
    assert result["basis_text"] == "这是一般经验，还没有足够记录验证"
    assert result["conclusion"] == ANSWER["conclusion"]
    assert result["version_id"] == detail["version"]["id"]
    assert any(f["rule_id"] == "poultry-cook-through" for f in result["safety"]["findings"])
    assert api.client.get(f"/v1/recipes/{detail['id']}", headers=headers).json() == before
    history = api.client.get(f"/v1/recipes/{detail['id']}/versions", headers=headers).json()
    assert len(history["items"]) == 1
    user = api.client.get("/v1/me", headers=headers).json()
    audit = cli("ai", "audit", "--user", user["id"])
    assert [c["capability"] for c in audit["calls"]] == ["explain"]
    assert all(QUESTION not in str(event) for event in audit["events"])


def test_safe_answer_can_explicitly_negate_an_unsafe_core_temperature(
    replay_answers: Path, api: Api
):
    headers, detail = create(api)
    model = {
        **ANSWER,
        "explanation": "不要在中心温度达到50°C时停火。应继续加热直到中心温度达到74°C。",
    }
    recording(replay_answers, "explain", payload(detail), model)
    result = ask(api, headers, detail).json()
    assert result["state"] == "answered"
    assert result["explanation"] == model["explanation"]
    assert any(f["rule_id"] == "poultry-cook-through" for f in result["safety"]["findings"])


@pytest.mark.parametrize("context_field", ["dish_aliases", "change_note"])
def test_answer_preserves_saved_version_safety_context(
    replay_answers: Path, api: Api, context_field: str
):
    headers = bearer(api.login("answer-context@example.com"))
    body = recipe_input()
    body[context_field] = ["河豚汤"] if context_field == "dish_aliases" else "河豚汤"
    saved = api.client.post("/v1/recipes", headers=headers, json=body)
    assert saved.status_code == 201, saved.text
    detail = saved.json()
    assert detail["version"]["safety"]["high_risk"] is True
    recording(replay_answers, "explain", payload(detail), ANSWER)
    for question in [QUESTION, "如何做野生菌"]:
        result = ask(api, headers, detail, question).json()
        assert result["safety"]["high_risk"] is True
        assert "high-risk-pufferfish" in {f["rule_id"] for f in result["safety"]["findings"]}


def test_answer_carries_warning_from_model_suggested_raw_seafood(replay_answers: Path, api: Api):
    headers, detail = create(api)
    model = {**ANSWER, "details": "可以搭配生腌虾食用。"}
    recording(replay_answers, "explain", payload(detail), model)
    result = ask(api, headers, detail).json()
    assert result["state"] == "answered"
    assert {f["rule_id"] for f in result["safety"]["findings"]} >= {
        "poultry-cook-through",
        "raw-seafood",
    }


@pytest.mark.parametrize(
    "model, state, error",
    [
        ({**ANSWER, "confidence": 0.2}, "uncertain", None),
        ({**ANSWER, "state": "uncertain"}, "uncertain", None),
        ({**ANSWER, "state": "cannot_answer"}, "cannot_answer", "no_reliable_answer"),
        ({**ANSWER, "kitchen_scope": False}, "cannot_answer", "outside_scope"),
        (
            {**ANSWER, "conclusion": "平台 100 人做过，成功率 99%，已验证"},
            "cannot_answer",
            "unsafe_output",
        ),
        ({**ANSWER, "conclusion": "这道菜降血糖"}, "cannot_answer", "unsafe_output"),
        ({**ANSWER, "conclusion": "鸡肉半熟即可食用"}, "cannot_answer", "unsafe_output"),
        (
            {**ANSWER, "conclusion": "鸡肉中心温度达到 50°C 即可食用"},
            "cannot_answer",
            "unsafe_output",
        ),
        ({**ANSWER, "conclusion": "试试野生菌汤"}, "cannot_answer", "unsafe_output"),
        ({}, "unavailable", "invalid_output"),
    ],
)
def test_unreliable_or_unsafe_model_text_is_not_presented_as_a_conclusion(
    replay_answers: Path, api: Api, model: dict, state: str, error: str | None
):
    headers, detail = create(api)
    recording(replay_answers, "explain", payload(detail), model)
    response = ask(api, headers, detail)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["state"] == state
    assert result["error"] == error
    assert result["basis"] == "general_experience"
    assert result["conclusion"] != model.get("conclusion")
    assert any(f["rule_id"] == "poultry-cook-through" for f in result["safety"]["findings"])


@pytest.mark.parametrize("reason", ["daily_quota", "monthly_budget", "model_unavailable"])
def test_answer_degradation_keeps_non_ai_operations_available(
    replay_answers: Path, api: Api, reason: str
):
    headers, detail = create(api)
    if reason == "daily_quota":
        configure("ai.policies", {"explain": {"daily_limit": 0}})
    elif reason == "monthly_budget":
        configure("ai.monthly_budget", 0)
    # Missing recording represents provider failure, including timeout, in replay.
    result = ask(api, headers, detail).json()
    assert result["state"] == "unavailable"
    assert result["error"] == reason
    assert result["capability"] == "explain"
    assert result["question"] == QUESTION
    assert result["version_id"] == detail["version"]["id"]
    assert result["status"]["available"] is False
    assert api.client.get(f"/v1/recipes/{detail['id']}", headers=headers).status_code == 200
    assert (
        api.client.get(
            f"/v1/recipes/{detail['id']}/servings?target_servings=4", headers=headers
        ).status_code
        == 200
    )
    edited = detail["version"]["snapshot"]
    edited["ingredients"][0]["quantity"] = 320
    saved = api.client.post(
        f"/v1/recipes/{detail['id']}/versions",
        headers=headers,
        json={"snapshot": edited, "change_note": "手动改用量"},
    )
    assert saved.status_code == 201, saved.text
    assert saved.json()["version"]["snapshot"]["ingredients"][0]["quantity"] == 320


def test_answer_permission_membership_and_input_validation_precede_model_calls(api: Api):
    headers, detail = create(api)
    other_headers, other = create(api, "answer-other@example.com")
    assert ask(api, other_headers, detail).status_code == 404
    assert ask(api, {}, detail).status_code == 401
    mixed = {**detail, "version": other["version"]}
    assert ask(api, headers, mixed).status_code == 404
    assert ask(api, headers, detail, "   ").status_code == 422
    assert ask(api, headers, detail, "x" * 1001).status_code == 422
    assert ask(api, headers, detail).json()["state"] == "unavailable"
    user = api.client.get("/v1/me", headers=headers).json()
    assert cli("ai", "audit", "--user", user["id"])["calls"] == []


@pytest.mark.parametrize("question", ["如何做河豚", "野生菌怎么煮", "吃这个能降血糖吗"])
def test_high_risk_or_health_requests_are_refused_without_model_calls(
    replay_answers: Path, api: Api, question: str
):
    headers, detail = create(api)
    recording(replay_answers, "explain", payload(detail, question), ANSWER)
    result = ask(api, headers, detail, question).json()
    assert result["state"] == "cannot_answer"
    assert result["error"] == "unsafe_question"
    assert any(f["rule_id"] == "poultry-cook-through" for f in result["safety"]["findings"])
    user = api.client.get("/v1/me", headers=headers).json()
    assert cli("ai", "audit", "--user", user["id"])["calls"] == []


def test_answer_uses_requested_immutable_version_and_excludes_private_non_cooking_fields(
    replay_answers: Path, api: Api
):
    headers, old = create(api)
    snapshot = copy.deepcopy(old["version"]["snapshot"])
    snapshot["ingredients"][0]["quantity"] = 400
    snapshot["design_rationale"] = "PRIVATE-RATIONALE-SENTINEL"
    snapshot["description"] = "PRIVATE-DESCRIPTION-SENTINEL"
    newer = api.client.post(
        f"/v1/recipes/{old['id']}/versions",
        headers=headers,
        json={"snapshot": snapshot, "change_note": "PRIVATE-CHANGE-SENTINEL"},
    ).json()
    recording(replay_answers, "explain", payload(newer), ANSWER)
    assert ask(api, headers, newer).json()["state"] == "answered"
    # Recording of current version must not answer an older immutable version.
    assert ask(api, headers, old).json()["state"] == "unavailable"
    recording(replay_answers, "explain", payload(old), ANSWER)
    assert ask(api, headers, old).json()["state"] == "answered"
    current = api.client.get(f"/v1/recipes/{old['id']}", headers=headers).json()
    assert current["version"]["id"] == newer["version"]["id"]
    assert current["version"]["snapshot"]["design_rationale"] == "PRIVATE-RATIONALE-SENTINEL"
    # Phase-two gate stays off; request text is never added to experience events.
    config = api.client.get("/v1/client-config").json()
    assert config["features"]["cooking_qa"] is False
