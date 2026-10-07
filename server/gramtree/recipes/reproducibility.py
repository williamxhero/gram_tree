"""Version-owned execution completeness; no publishing or verification decisions."""

import json
import re
from pathlib import Path
from typing import Literal

from gramtree.recipes.schemas import (
    RecipeReproducibilityResult,
    RecipeSnapshot,
    ReproducibilityPosition,
    ReproducibilityProblem,
)


def rules() -> dict:
    return json.loads(Path(__file__).with_name("reproducibility_rules.json").read_text("utf-8"))


def household_unit(unit: str) -> bool:
    policy = rules()
    return any(term in unit for term in policy["household_units"] + policy["quantity_terms"])


def ambiguous_unit(unit: str) -> bool:
    if unit.strip().casefold() in rules()["standard_units"]:
        return False
    # Unknown or household units need an explicit capacity/weight, never an assumption.
    return re.search(r"[0-9]+(?:[.][0-9]+)?\s*(?:ml|毫升|g|克)", unit, re.I) is None


def check(snapshot: RecipeSnapshot) -> RecipeReproducibilityResult:
    policy = rules()
    problems: list[ReproducibilityProblem] = []
    required: set[tuple[str, str, str]] = set()
    incomplete: set[tuple[str, str, str]] = set()

    def require(collection: str, item_id: str, field: str) -> None:
        required.add((collection, item_id, field))

    def problem(
        collection: Literal["ingredients", "steps", "snapshot"],
        item_id: str,
        field: str,
        message: str,
        original: str | None = None,
        *,
        kind: Literal["ambiguous", "missing"] = "missing",
        start: int | None = None,
        end: int | None = None,
    ) -> None:
        require(collection, item_id, field)
        incomplete.add((collection, item_id, field))
        offset = str(start) if start is not None else "field"
        problems.append(
            ReproducibilityProblem(
                id=f"{collection}:{item_id}:{field}:{kind}:{offset}",
                type=kind,
                status="unresolved",
                message=message,
                original=original,
                position=ReproducibilityPosition(
                    collection=collection, item_id=item_id, field=field, start=start, end=end
                ),
            )
        )

    def inspect_text(
        collection: Literal["ingredients", "steps"], item_id: str, field: str, text: str
    ) -> None:
        # Scan editable execution text only: ValueSource.original is historical evidence.
        terms = policy["quantity_terms"] + policy["time_terms"]
        for match in re.finditer(
            "|".join(re.escape(term) for term in sorted(terms, key=len, reverse=True)), text
        ):
            # A stated utensil capacity makes '一碗（300 ml）' concrete.
            if match.group() in ("一碗", "一勺") and re.search(
                r"[0-9]+(?:[.][0-9]+)?\s*(?:ml|毫升|g|克)", text[match.end() :], re.I
            ):
                continue
            problem(
                collection,
                item_id,
                field,
                "执行描述需要具体数值或判断标准",
                match.group(),
                kind="ambiguous",
                start=match.start(),
                end=match.end(),
            )
        if re.search(policy["cutting_action_pattern"], text) and not re.search(
            policy["cut_size_pattern"], text, re.I
        ):
            problem(collection, item_id, field, "切配需要具体尺寸", text, kind="ambiguous")

    for item in snapshot.ingredients:
        for field in policy["required_fields"]["ingredient"]:
            require("ingredients", item.id, field)
        if ambiguous_unit(item.unit) or item.quantity <= 0:
            problem(
                "ingredients",
                item.id,
                "quantity",
                "用量需要具体数量和标准单位或容器基准",
                f"{item.quantity:g} {item.unit}",
                kind="ambiguous",
            )
        if item.preparation:
            require("ingredients", item.id, "preparation")
            inspect_text("ingredients", item.id, "preparation", item.preparation)

    by_id = {item.id: item for item in snapshot.ingredients}
    for step in snapshot.steps:
        for field in policy["required_fields"]["step"]:
            require("steps", step.id, field)
        if not step.instruction.strip():
            problem("steps", step.id, "instruction", "步骤需要执行说明")
        inspect_text("steps", step.id, "instruction", step.instruction)
        execution = f"{step.action or ''} {step.instruction}"
        heating = any(term in execution for term in policy["heating_actions"])
        if heating:
            for field in policy["required_fields"]["heating"]:
                require("steps", step.id, field)
            if step.duration_seconds <= 0:
                problem("steps", step.id, "duration_seconds", "加热步骤需要具体时长")
            heat_text = f"{step.heat or ''} {step.instruction}"
            if not (
                (step.temperature_celsius is not None and step.temperature_celsius > 0)
                or re.search(policy["temperature_pattern"], heat_text, re.I)
                or any(term in heat_text for term in policy["heat_observations"])
            ):
                problem("steps", step.id, "heat", "火候需要温度或可观察的判断标准", step.heat)
            items = [
                by_id[key] for key in step.ingredient_ids if key in by_id
            ] or snapshot.ingredients
            needs_doneness = any(
                any(term in item.display_name for term in policy["needs_doneness_ingredients"])
                and not any(term in item.display_name for term in policy["ready_to_eat_terms"])
                for item in items
            )
            if needs_doneness:
                require("steps", step.id, "doneness")
                if not step.doneness or step.doneness.strip() in policy["vague_doneness"]:
                    problem("steps", step.id, "doneness", "需要可观察的熟透判断", step.doneness)
    if not snapshot.ingredients:
        problem("snapshot", "", "ingredients", "需要食材用量")
    if not snapshot.steps:
        problem("snapshot", "", "steps", "需要执行步骤")
    count = len(required)
    concrete = count - len(incomplete)
    return RecipeReproducibilityResult(
        rules_version=policy["version"],
        state="incomplete" if problems else "reproducible",
        remaining_count=len(problems),
        required_field_count=count,
        concrete_field_count=concrete,
        field_completeness=concrete / count if count else 0,
        problems=problems,
    )
