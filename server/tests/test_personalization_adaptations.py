"""SPEC-005.2 constraints and cached adaptations through HTTP and operator audit."""

import copy
import json
from pathlib import Path

import pytest

from gramtree.cli import main as operator_cli
from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import cli, recording
from tests.test_allergies import PATH as ALLERGIES
from tests.test_allergies import consent, save
from tests.test_allergies import sensitive_api as sensitive_api
from tests.test_family_members import PATH as FAMILY
from tests.test_family_members import member_body

CORPUS = json.loads(
    Path(__file__)
    .with_name("fixtures")
    .joinpath("ai/personalization_corpus.json")
    .read_text(encoding="utf-8")
)
CATALOGUE = {item["standard_name"]: item for item in CORPUS["catalogue"]}


@pytest.fixture
def personalization_recordings(monkeypatch, tmp_path: Path) -> Path:
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def personalization_api(
    personalization_recordings: Path, sensitive_api: Api, tmp_path: Path
) -> Api:
    catalogue = tmp_path / "catalogue"
    catalogue.mkdir()
    (catalogue / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "synthetic personalization acceptance"}),
        encoding="utf-8",
    )
    (catalogue / "ingredients.json").write_text(
        json.dumps(CORPUS["catalogue"], ensure_ascii=False), encoding="utf-8"
    )
    assert operator_cli(["ingredients", "import", str(catalogue)]) == 0
    return sensitive_api


def ingredient(name: str, item_id: str, quantity: float = 10, **changes) -> dict:
    return {
        "id": item_id,
        "ingredient_id": CATALOGUE[name]["id"],
        "display_name": name,
        "quantity": quantity,
        "unit": "g",
        "scaling_mode": "proportional",
        **changes,
    }


def recipe(items: list[dict], instruction: str = "拌匀后盛出") -> dict:
    return {
        "dish_name": "个性化测试菜",
        "snapshot": {
            "servings": 2,
            "ingredients": items,
            "steps": [
                {
                    "id": "cook",
                    "instruction": instruction,
                    "ingredient_ids": [item["id"] for item in items],
                }
            ],
        },
    }


def create(api: Api, headers: dict, body: dict) -> dict:
    response = api.client.post("/v1/recipes", headers=headers, json=body)
    assert response.status_code == 201, response.text
    return response.json()


def project(api: Api, headers: dict, detail: dict, **inputs) -> dict:
    response = api.client.post(
        f"/v1/recipes/{detail['id']}/personalized", headers=headers, json=inputs
    )
    assert response.status_code == 200, response.text
    return response.json()


def avoid(api: Api, headers: dict, *names: str) -> None:
    response = api.client.patch(
        "/v1/me/taste-profile",
        headers=headers,
        json={
            "ingredient_preferences": [
                {"ingredient_id": CATALOGUE[name]["id"], "preference": "avoided"} for name in names
            ]
        },
    )
    assert response.status_code == 200, response.text


def family_member(api: Api, headers: dict, **changes) -> dict:
    state = api.client.get(FAMILY, headers=headers)
    assert state.status_code == 200, state.text
    if state.json()["consent_id"] is None:
        consent(api, headers)
        state = api.client.get(FAMILY, headers=headers)
        assert state.status_code == 200, state.text
    response = api.client.post(
        FAMILY,
        headers=headers,
        json=member_body(
            state.json(),
            **{
                "nickname": "家人",
                "age_band": "adult",
                "flavors": {},
                "allergies": {"categories": [], "ingredient_ids": []},
                **changes,
            },
        ),
    )
    assert response.status_code == 201, response.text
    return response.json()


def record_replacement(directory: Path, detail: dict, name: str, output: dict) -> None:
    snapshot = detail["version"]["snapshot"]
    item = next(item for item in snapshot["ingredients"] if item["display_name"] == name)
    recording(
        directory,
        "personalize_replacement",
        {
            "ingredient": name,
            "usage": [
                step["instruction"]
                for step in snapshot["steps"]
                if item["id"] in step["ingredient_ids"]
            ],
        },
        output,
    )


def assert_original_preserved(api: Api, headers: dict, detail: dict) -> None:
    response = api.client.get(f"/v1/recipes/{detail['id']}", headers=headers)
    assert response.status_code == 200, response.text
    assert response.json()["version"]["snapshot"] == detail["version"]["snapshot"]
    assert response.json()["version"]["id"] == detail["version"]["id"]
    history = api.client.get(f"/v1/recipes/{detail['id']}/versions", headers=headers)
    assert history.status_code == 200, history.text
    assert len(history.json()["items"]) == 1


def test_explicit_cilantro_replacement_changes_display_and_execution_only(
    personalization_api: Api,
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-cilantro@example.com"))
    avoid(api, headers, "香菜")
    detail = create(
        api,
        headers,
        recipe(
            [ingredient("香菜", "herb", replacement={"display_name": "葱", "ratio": 0.5})],
            "最后加入香菜，拌匀后盛出",
        ),
    )
    result = project(api, headers, detail)
    herb = result["ingredients"][0]
    assert herb["original_name"] == "香菜"
    assert herb["display_name"] == "葱"
    assert herb["original_quantity"] == 10
    assert herb["display_quantity"] == 5
    assert herb["changed"] is True
    assert herb["rule"] == "substitution"
    assert herb["adaptation_factors"] == [0.5]
    assert "已替换：香菜 → 葱" in herb["reason"]
    assert result["snapshot"]["ingredients"][0]["ingredient_id"] == CATALOGUE["葱"]["id"]
    assert result["steps"][0]["instruction"] == "最后加入葱，拌匀后盛出"
    assert result["steps"][0]["original_instruction"] == "最后加入香菜，拌匀后盛出"
    assert result["safety"]["alerts"] == []
    assert result["blocked"] is False
    assert_original_preserved(api, headers, detail)


@pytest.mark.parametrize("referenced", [False, True])
@pytest.mark.parametrize("replacement", ["葱", {"display_name": "葱"}])
def test_safe_substitute_updates_steps_even_without_ingredient_references(
    personalization_api: Api, referenced: bool, replacement: str | dict
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-step-allergy@example.com"))
    consent(api, headers)
    state = api.client.get(ALLERGIES, headers=headers).json()
    assert save(api, headers, state, ["花生"]).status_code == 200
    body = recipe(
        [ingredient("花生", "peanut", replacement=replacement)], "最后加入花生拌匀"
    )
    if not referenced:
        body["snapshot"]["steps"][0]["ingredient_ids"] = []
    detail = create(api, headers, body)
    result = project(api, headers, detail)
    assert result["ingredients"][0]["display_name"] == "葱"
    assert result["steps"][0]["instruction"] == "最后加入葱拌匀"
    assert result["safety"]["alerts"] == []
    assert result["blocked"] is False
    assert_original_preserved(api, headers, detail)


def test_ai_draft_allergen_free_attributes_cannot_prove_safe_replacement(
    personalization_api: Api, tmp_path: Path
) -> None:
    catalogue = copy.deepcopy(CORPUS["catalogue"])
    for item in catalogue:
        if item["standard_name"] == "葱":
            item["attributes"]["allergens"]["status"] = "ai_draft"
    directory = tmp_path / "draft-catalogue"
    directory.mkdir()
    (directory / "manifest.json").write_text(
        json.dumps({"version": "1.0.1", "changelog": "draft allergen regression"}),
        encoding="utf-8",
    )
    (directory / "ingredients.json").write_text(
        json.dumps(catalogue, ensure_ascii=False), encoding="utf-8"
    )
    assert operator_cli(["ingredients", "import", str(directory)]) == 0
    api = personalization_api
    headers = bearer(api.login("personalization-draft-allergy@example.com"))
    consent(api, headers)
    state = api.client.get(ALLERGIES, headers=headers).json()
    assert save(api, headers, state, ["花生"]).status_code == 200
    detail = create(
        api, headers, recipe([ingredient("花生", "peanut", replacement="葱")])
    )
    result = project(api, headers, detail)
    assert result["ingredients"][0]["display_name"] == "花生"
    assert result["blocked"] is True
    assert any("没有明确安全替代" in notice for notice in result["notices"])
    assert_original_preserved(api, headers, detail)


def test_substitution_preserves_exact_ratio_for_offline_recompilation(
    personalization_api: Api,
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-rounding@example.com"))
    avoid(api, headers, "香菜")
    detail = create(
        api,
        headers,
        recipe(
            [ingredient("香菜", "herb", 0.03, replacement={"display_name": "葱", "ratio": 0.5})]
        ),
    )
    first = project(api, headers, detail)
    doubled = project(api, headers, detail, target_servings=4)
    assert first["ingredients"][0]["display_quantity"] == 0.02
    assert first["ingredients"][0]["adaptation_factors"] == [0.5]
    assert doubled["ingredients"][0]["display_quantity"] == 0.03
    assert_original_preserved(api, headers, detail)


def test_no_safe_substitute_retains_avoided_main_ingredient_and_notice(
    personalization_api: Api, personalization_recordings: Path
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-no-substitute@example.com"))
    avoid(api, headers, "豆腐")
    detail = create(api, headers, recipe([ingredient("豆腐", "main", 200, group="主料")]))
    record_replacement(personalization_recordings, detail, "豆腐", CORPUS["no_replacement"])
    result = project(api, headers, detail)
    assert len(result["ingredients"]) == 1
    assert result["ingredients"][0]["display_name"] == "豆腐"
    assert result["ingredients"][0]["display_quantity"] == 200
    assert result["ingredients"][0]["changed"] is False
    assert any("这道菜可能不适合你" in notice and "豆腐" in notice for notice in result["notices"])
    assert result["safety"]["alerts"][0]["kind"] == "avoidance"
    assert result["blocked"] is False
    assert_original_preserved(api, headers, detail)


@pytest.mark.parametrize("person", ["owner", "family"])
@pytest.mark.parametrize("replacement", [None, {"display_name": "未收录的替代品"}])
def test_allergies_require_explicit_confirmation_and_never_trust_unknown_substitute(
    personalization_api: Api,
    personalization_recordings: Path,
    person: str,
    replacement: dict | None,
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-allergy@example.com"))
    consent(api, headers)
    inputs = {}
    if person == "owner":
        state = api.client.get(ALLERGIES, headers=headers).json()
        response = save(api, headers, state, ["花生"])
        assert response.status_code == 200, response.text
        expected_person = "你"
    else:
        member = family_member(
            api, headers, nickname="小林", allergies={"categories": ["花生"], "ingredient_ids": []}
        )
        inputs["diner_member_ids"] = [member["id"]]
        expected_person = "小林"
    detail = create(api, headers, recipe([ingredient("花生", "peanut", replacement=replacement)]))
    record_replacement(personalization_recordings, detail, "花生", CORPUS["no_replacement"])
    result = project(api, headers, detail, **inputs)
    assert result["blocked"] is True
    assert result["ingredients"][0]["display_name"] == "花生"
    assert any(
        alert["person"] == expected_person
        and alert["kind"] == "allergy"
        and alert["target"] == "花生"
        for alert in result["safety"]["alerts"]
    )
    assert any("明确确认" in notice for notice in result["notices"])
    confirmed = project(api, headers, detail, confirm_allergy_risk=True, **inputs)
    assert confirmed["blocked"] is False
    assert confirmed["safety"]["alerts"] == result["safety"]["alerts"]
    assert confirmed["inputs"]["confirm_allergy_risk"] is True
    # Confirmation belongs to one request; opening again must still block.
    assert project(api, headers, detail, **inputs)["blocked"] is True
    assert_original_preserved(api, headers, detail)


def test_equipment_replay_is_marked_ai_and_repeat_request_spends_no_second_attempt(
    personalization_api: Api, personalization_recordings: Path
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-equipment@example.com"))
    detail = create(api, headers, copy.deepcopy(CORPUS["equipment_recipe"]))
    step = detail["version"]["snapshot"]["steps"][0]
    fields = (
        "id",
        "action",
        "instruction",
        "ingredient_ids",
        "duration_seconds",
        "heat",
        "temperature_celsius",
        "cookware",
        "doneness",
        "depends_on",
        "unattended",
    )
    recording(
        personalization_recordings,
        "personalize_equipment",
        {"equipment": ["wok"], "steps": [{key: step[key] for key in fields}]},
        CORPUS["equipment_rewrite"],
    )
    result = project(api, headers, detail, equipment=["wok"])
    assert result["fallback"] is None
    assert result["steps"][0]["source"] == "ai_estimated"
    assert result["steps"][0]["changed"] is True
    assert result["steps"][0]["cookware"] == "炒锅"
    assert (
        result["steps"][0]["instruction"] == CORPUS["equipment_rewrite"]["steps"][0]["instruction"]
    )
    assert result["snapshot"]["steps"][0]["duration_seconds"] == 600
    assert result["snapshot"]["steps"][0]["unattended"] is False
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    first_audit = cli("ai", "audit", "--user", user_id)
    assert [call["capability"] for call in first_audit["calls"]] == ["personalize_equipment"]
    # Make another provider attempt impossible; the accepted cached rewrite must survive.
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"ai_mode": "disabled"}
    )
    repeated = project(api, headers, detail, equipment=["wok"])
    assert repeated["steps"] == result["steps"]
    assert repeated["cache_key"] == result["cache_key"]
    assert repeated["fallback"] is None
    assert cli("ai", "audit", "--user", user_id)["calls"] == first_audit["calls"]
    assert_original_preserved(api, headers, detail)


def test_ai_unavailable_preserves_servings_flavor_and_functional_rules(
    personalization_api: Api,
) -> None:
    api = personalization_api
    api.client.app.state.settings = api.client.app.state.settings.model_copy(
        update={"ai_mode": "disabled"}
    )
    headers = bearer(api.login("personalization-fallback@example.com"))
    avoid(api, headers, "豆腐")
    profile = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 0.5, "sweet": 0.5}}
    )
    assert profile.status_code == 200, profile.text
    body = recipe(
        [
            ingredient("豆腐", "main", 200, group="主料"),
            ingredient("盐", "salt", 10, flavor_contribution={"salty": 3}),
            ingredient("糖", "sugar", 10, functional=True, flavor_contribution={"sweet": 3}),
        ]
    )
    body["snapshot"]["steps"][0]["cookware"] = "烤箱"
    detail = create(api, headers, body)
    result = project(api, headers, detail, target_servings=4, equipment=["wok"])
    values = {item["id"]: item for item in result["ingredients"]}
    assert values["main"]["display_name"] == "豆腐"
    assert values["main"]["display_quantity"] == 400
    assert values["salt"]["display_quantity"] == 14
    assert values["sugar"]["display_quantity"] == 20
    assert values["sugar"]["rule"] == "functional_protected"
    assert result["snapshot"]["servings"] == 4
    assert result["steps"][0]["source"] == "recipe"
    assert result["steps"][0]["cookware"] == "烤箱"
    assert result["fallback"] and "厨具适配暂缺" in result["fallback"]
    assert any("忌口替换暂缺" in notice for notice in result["notices"])
    assert_original_preserved(api, headers, detail)


@pytest.mark.parametrize("suggested", [False, True])
def test_food_safety_is_rerun_after_explicit_or_ai_replacement(
    personalization_api: Api, personalization_recordings: Path, suggested: bool
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-recheck@example.com"))
    avoid(api, headers, "豆腐")
    replacement = None if suggested else {"display_name": "鸡肉", "ratio": 1}
    detail = create(
        api,
        headers,
        recipe([ingredient("豆腐", "main", 200, replacement=replacement)], "翻炒两分钟"),
    )
    record_replacement(personalization_recordings, detail, "豆腐", CORPUS["suggested_replacement"])
    original = api.client.post(
        f"/v1/recipes/{detail['id']}/personalized?view=original", headers=headers, json={}
    )
    assert original.status_code == 200, original.text
    assert "poultry-cook-through" not in {
        finding["rule_id"] for finding in original.json()["food_safety"]["findings"]
    }
    result = project(api, headers, detail)
    assert result["ingredients"][0]["display_name"] == "鸡肉"
    assert result["ingredients"][0]["rule"] == ("ai_substitution" if suggested else "substitution")
    finding = next(
        f for f in result["food_safety"]["findings"] if f["rule_id"] == "poultry-cook-through"
    )
    assert finding["ingredient_ids"] == ["main"]
    assert finding["step_ids"] == ["cook"]
    assert finding["severity"] == "warning"
    assert_original_preserved(api, headers, detail)


def test_family_allergy_avoidance_union_and_flavor_compromise_are_applied(
    personalization_api: Api, personalization_recordings: Path
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-family-union@example.com"))
    avoid(api, headers, "香菜")
    profile = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 0.5, "spicy": 1.5}}
    )
    assert profile.status_code == 200, profile.text
    consent(api, headers)
    state = api.client.get(ALLERGIES, headers=headers).json()
    allergies = save(api, headers, state, ["花生"])
    assert allergies.status_code == 200, allergies.text
    member = family_member(
        api,
        headers,
        nickname="小周",
        flavors={"salty": 0.75, "spicy": 0},
        avoidances=[{"ingredient_id": CATALOGUE["辣椒"]["id"]}],
        allergies={"categories": ["大豆"], "ingredient_ids": []},
    )
    detail = create(
        api,
        headers,
        recipe(
            [
                ingredient("香菜", "herb"),
                ingredient("豆腐", "tofu", 200, group="主料"),
                ingredient("花生", "peanut"),
                ingredient("辣椒", "chili", flavor_contribution={"spicy": 3}),
            ]
        ),
    )
    for name in ("香菜", "豆腐", "花生", "辣椒"):
        record_replacement(personalization_recordings, detail, name, CORPUS["no_replacement"])
    result = project(api, headers, detail, diner_member_ids=[member["id"]])
    assert result["effective_flavors"]["spicy"] == 0
    assert result["effective_flavors"]["salty"] == 0.625
    assert {
        (alert["person"], alert["kind"], alert["target"]) for alert in result["safety"]["alerts"]
    } >= {
        ("你", "avoidance", "香菜"),
        ("你", "allergy", "花生"),
        ("小周", "avoidance", "辣椒"),
        ("小周", "allergy", "大豆"),
    }
    assert result["blocked"] is True
    owner_only = project(api, headers, detail)
    assert all(alert["person"] == "你" for alert in owner_only["safety"]["alerts"])
    assert owner_only["effective_flavors"]["spicy"] == 1.5
    assert owner_only["cache_key"] != result["cache_key"]
    assert_original_preserved(api, headers, detail)


def test_primary_diner_overrides_family_compromise(
    personalization_api: Api,
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-primary@example.com"))
    profile = api.client.patch(
        "/v1/me/taste-profile", headers=headers, json={"flavors": {"salty": 0.5, "spicy": 1.5}}
    )
    assert profile.status_code == 200, profile.text
    member = family_member(
        api,
        headers,
        nickname="主要食客",
        flavors={"salty": 0.75, "spicy": 0.5},
    )
    detail = create(
        api, headers, recipe([ingredient("辣椒", "chili", flavor_contribution={"spicy": 3})])
    )
    result = project(
        api, headers, detail, diner_member_ids=[member["id"]], primary_diner_id=member["id"]
    )
    assert result["effective_flavors"]["spicy"] == 0.5
    assert result["effective_flavors"]["salty"] == 0.75


def test_child_who_does_not_eat_spicy_gets_a_split_before_late_addition(
    personalization_api: Api,
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-child-split@example.com"))
    member = family_member(
        api,
        headers,
        nickname="小宝",
        age_band="3_to_6",
        flavors={"spicy": 0},
    )
    body = recipe([ingredient("辣椒", "chili", 10, flavor_contribution={"spicy": 3})])
    body["snapshot"]["steps"] = [
        {"id": "base", "instruction": "炒熟底料", "ingredient_ids": [], "depends_on": []},
        {
            "id": "spice",
            "instruction": "最后加入辣椒，拌匀后盛出",
            "ingredient_ids": ["chili"],
            "depends_on": ["base"],
        },
    ]
    detail = create(api, headers, body)
    result = project(api, headers, detail, diner_member_ids=[member["id"]])
    split = next(
        step for step in result["steps"] if step["id"].startswith("personalized-child-portion")
    )
    spice = next(step for step in result["steps"] if step["id"] == "spice")
    assert "先盛出儿童" in split["instruction"]
    assert "50%" in split["instruction"]
    assert spice["instruction"] == "最后加入辣椒，拌匀后盛出"
    assert split["source"] == "scenario_adjusted"
    snapshot_steps = {step["id"]: step for step in result["snapshot"]["steps"]}
    assert snapshot_steps[split["id"]]["depends_on"] == ["base"]
    assert snapshot_steps["spice"]["depends_on"] == [split["id"]]
    assert [step["id"] for step in result["steps"]] == ["base", split["id"], "spice"]
    assert spice["changed"] is True
    assert_original_preserved(api, headers, detail)
    chili = result["ingredients"][0]
    assert chili["display_quantity"] == 3.5
    assert chili["rule"] == "child_portion"
    assert chili["adaptation_factors"] == [0.5]
    assert "先盛儿童份" in chili["reason"]


def test_infant_diner_receives_food_safety_warning_and_blocks_start(
    personalization_api: Api,
) -> None:
    api = personalization_api
    headers = bearer(api.login("personalization-infant@example.com"))
    member = family_member(
        api,
        headers,
        nickname="宝宝",
        age_band="under_1",
        flavors={},
    )
    detail = create(
        api,
        headers,
        recipe([ingredient("蜂蜜", "honey", 5), ingredient("盐", "salt", 1)]),
    )
    result = project(api, headers, detail, diner_member_ids=[member["id"]])
    findings = {finding["rule_id"] for finding in result["food_safety"]["findings"]}
    assert {"infant_honey", "infant_salt"} <= findings
    assert result["blocked"] is True
    assert any("1 岁以下" in notice for notice in result["notices"])
    assert result["safety"]["status"] == "available"
