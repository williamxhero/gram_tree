"""Cross-client golden cases for the deterministic personalization kernel."""

import json
from pathlib import Path
from typing import Any

from gramtree.recipes.personalization import PersonalizationInput, compile_rules
from gramtree.recipes.schemas import RecipeIngredient, RecipeSnapshot

_CASES = Path(__file__).parents[2] / "app" / "assets" / "personalization_cases.json"


def test_shared_personalization_cases() -> None:
    cases = json.loads(_CASES.read_text(encoding="utf-8"))["cases"]
    for case in cases:
        snapshot = RecipeSnapshot(
            servings=case["original_servings"],
            ingredients=[_ingredient(item) for item in case["ingredients"]],
            steps=[],
        )
        original = snapshot.model_copy(deep=True)
        output, _, _ = compile_rules(
            snapshot,
            PersonalizationInput(
                flavors=case["flavors"],
                profile_version=1,
                target_servings=case["target_servings"],
            ),
        )
        quantities = {item.id: item.quantity for item in output.ingredients}
        for item in case["ingredients"]:
            assert quantities[item["id"]] == item["expected"], case["name"]
        assert snapshot == original, case["name"]


def _ingredient(item: dict[str, Any]) -> RecipeIngredient:
    return RecipeIngredient.model_validate(
        {
            "id": item["id"],
            "display_name": item["display_name"],
            "quantity": item["quantity"],
            "unit": item["unit"],
            "group": item.get("group"),
            "scaling_mode": item["scaling_mode"],
            "functional": item["functional"],
            "flavor_contribution": item["contribution"],
        }
    )
