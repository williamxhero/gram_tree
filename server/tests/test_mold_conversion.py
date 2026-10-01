"""Mold conversion and immutable base molds through public HTTP only."""

import json
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input

CASES = json.loads(
    (Path(__file__).parents[2] / "app" / "assets" / "mold_conversion_cases.json").read_text(
        encoding="utf-8"
    )
)


def test_author_saves_base_mold_and_converts_without_mutating_snapshot(api: Api) -> None:
    headers = bearer(api.login("mold-author@example.com"))
    body = recipe_input("模具蛋糕")
    body["snapshot"]["base_mold"] = {"shape": "round", "unit": "in", "diameter": 6}
    body["snapshot"]["ingredients"] = [
        {"id": "flour", "display_name": "面粉", "quantity": 100, "unit": "g"},
        {"id": "egg", "display_name": "鸡蛋", "quantity": 3, "unit": "个", "scaling_mode": "round"},
    ]
    body["snapshot"]["steps"] = [
        {
            "id": "bake",
            "instruction": "烤至成熟",
            "duration_seconds": 1800,
            "temperature_celsius": 170,
            "doneness": "竹签插入不粘",
        },
    ]
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    saved = response.json()
    result = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": {"shape": "round", "unit": "in", "diameter": 8}},
        headers=headers,
    )
    assert result.status_code == 200, result.text
    conversion = result.json()["conversion"]
    assert conversion["area_ratio"] == 1.78
    assert conversion["ingredients"][0]["display_quantity"] == 177.78
    assert conversion["ingredients"][0]["rule"] == "mold_ratio"
    assert conversion["ingredients"][1]["display_quantity"] == 5
    assert conversion["ingredients"][1]["rule"] == "round"
    assert conversion["steps"][0]["duration_seconds"] == 1800
    assert conversion["steps"][0]["temperature_celsius"] == 170
    assert "成熟判断" in conversion["steps"][0]["time_advisory"]
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json() == saved


@pytest.mark.parametrize("case", CASES, ids=[case["name"] for case in CASES])
def test_mold_conversion_matches_shared_fixture(api: Api, case: dict) -> None:
    headers = bearer(api.login(f"mold-fixture-{case['name']}@example.com"))
    source = case["input"]
    body = recipe_input(f"模具-{case['name']}")
    body["snapshot"].update(
        {
            "base_mold": source["original_mold"],
            "ingredients": source["ingredients"],
            "steps": source["steps"],
        }
    )
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    saved = created.json()
    response = api.client.post(
        f"/v1/recipes/{saved['id']}/mold",
        json={"target_mold": source["target_mold"]},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    actual = response.json()["conversion"]
    expected = case["expected"]
    assert actual["area_ratio"] == expected["area_ratio"]
    assert [
        {
            "id": item["id"],
            "original_quantity": item["original_quantity"],
            "display_quantity": item["display_quantity"],
            "unit": item["unit"],
            "rule": item["rule"],
        }
        for item in actual["ingredients"]
    ] == expected["ingredients"]
    if expected["step"] is None:
        assert actual["steps"] == []
    else:
        step = actual["steps"][0]
        assert step["duration_seconds"] == expected["step"]["duration_seconds"]
        assert step["temperature_celsius"] == expected["step"]["temperature_celsius"]
        assert bool(step["time_advisory"]) is expected["step"]["has_time_advisory"]
        assert step["doneness_warning"] is expected["step"]["doneness_warning"]


def test_mold_doneness_advice_only_applies_to_baking_steps() -> None:
    from gramtree.recipes.mold_conversion import MoldInput, MoldStepInput, convert_mold

    result = convert_mold(
        original_mold=MoldInput(shape="round", unit="cm", diameter=15),
        target_mold=MoldInput(shape="round", unit="cm", diameter=18),
        ingredients=[],
        steps=[
            MoldStepInput(
                id="rest",
                instruction="静置面团",
                duration_seconds=600,
                action="静置",
                cookware="案板",
            ),
            MoldStepInput(
                id="bake",
                instruction="烤至成熟",
                duration_seconds=1800,
                temperature_celsius=170,
                cookware="烤箱",
            ),
        ],
    )

    assert result.steps[0].doneness_warning is False
    assert result.steps[0].time_advisory is None
    assert result.steps[1].doneness_warning is True
    assert result.steps[1].time_advisory
    assert [warning.code for warning in result.warnings] == ["doneness_check"]
