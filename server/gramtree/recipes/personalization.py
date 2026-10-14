"""Deterministic, read-only personalization compiler for recipe snapshots."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Literal

from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.recipes.serving_conversion import (
    ServingConversion,
    ServingIngredientInput,
    ServingStepInput,
    convert_servings,
)

FlavorKey = Literal["salty", "sweet", "sour", "spicy", "numbing", "umami", "oily"]
FLAVOR_KEYS: tuple[FlavorKey, ...] = (
    "salty",
    "sweet",
    "sour",
    "spicy",
    "numbing",
    "umami",
    "oily",
)

# A single recipe adjustment cannot make a profile erase or double a recipe.
DEFAULT_ADJUSTMENT_LIMIT = 0.30


@dataclass(frozen=True)
class PersonalizationInput:
    flavors: dict[str, float]
    profile_version: int
    target_servings: int | None = None
    min_servings: int = 1
    max_servings: int = 20
    adjustment_limit: float = DEFAULT_ADJUSTMENT_LIMIT


def _serving_conversion(
    snapshot: RecipeSnapshot, request: PersonalizationInput
) -> ServingConversion | None:
    if request.target_servings is None or request.target_servings == snapshot.servings:
        return None
    return convert_servings(
        original_servings=snapshot.servings,
        target_servings=request.target_servings,
        min_servings=request.min_servings,
        max_servings=request.max_servings,
        ingredients=[
            ServingIngredientInput(
                id=item.id,
                display_name=item.display_name,
                quantity=item.quantity,
                unit=item.unit,
                scaling_mode=item.scaling_mode or "proportional",
            )
            for item in snapshot.ingredients
        ],
        steps=[
            ServingStepInput(
                id=step.id,
                instruction=step.instruction,
                ingredient_ids=tuple(step.ingredient_ids),
                duration_seconds=step.duration_seconds,
                temperature_celsius=step.temperature_celsius,
                heat=step.heat,
                unattended=step.unattended,
                depends_on=tuple(step.depends_on),
            )
            for step in snapshot.steps
        ],
        total_time_seconds=snapshot.total_time_seconds,
        active_time_seconds=snapshot.active_time_seconds,
    )


def _flavor_factor(item: Any, flavors: dict[str, float]) -> tuple[float, str] | None:
    contribution = item.flavor_contribution
    if contribution is None or item.functional or item.group == "主料":
        return None
    weighted: list[float] = []
    reasons: list[str] = []
    for key in FLAVOR_KEYS:
        contribution_value = getattr(contribution, key)
        if contribution_value is None or contribution_value == 0:
            continue
        coefficient = flavors.get(key, 1.0)
        weighted.append(1 + contribution_value / 3 * (coefficient - 1))
        reasons.append(key)
    if not weighted:
        return None
    factor = sum(weighted) / len(weighted)
    return factor, "、".join(reasons)


def _bounded_factor(factor: float, limit: float) -> float:
    return max(1 - limit, min(1 + limit, factor))


def cache_key(
    recipe_version_id: str,
    request: PersonalizationInput,
    *,
    equipment: tuple[str, ...] = (),
    diners: tuple[str, ...] = (),
    primary_diner: str | None = None,
    target_mold: dict[str, Any] | None = None,
    authorization_version: int = 0,
    catalogue_version: str = "",
    view: str = "personalized",
) -> str:
    payload = {
        "version": recipe_version_id,
        "profile": request.profile_version,
        "flavors": request.flavors,
        "servings": request.target_servings,
        "equipment": sorted(equipment),
        "diners": sorted(diners),
        "primary_diner": primary_diner,
        "mold": target_mold,
        "authorization": authorization_version,
        "catalogue": catalogue_version,
        "view": view,
        "rules": "personalization-v1",
        "adjustment_limit": request.adjustment_limit,
        "min_servings": request.min_servings,
        "max_servings": request.max_servings,
    }
    encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def compile_rules(
    snapshot: RecipeSnapshot, request: PersonalizationInput
) -> tuple[RecipeSnapshot, list[dict[str, Any]], list[str]]:
    """Apply steps 1-3 without mutating ``snapshot``.

    The returned snapshot is a display-only copy. Each changed ingredient has a
    machine-readable reason, original/display values, and the rule that produced it.
    """
    conversion = _serving_conversion(snapshot, request)
    converted = {item.id: item for item in conversion.ingredients} if conversion else {}
    result = snapshot.model_copy(deep=True)
    changes: list[dict[str, Any]] = []
    notices: list[str] = []
    for item in result.ingredients:
        original = next(source for source in snapshot.ingredients if source.id == item.id)
        serving_item = converted.get(item.id)
        display_quantity = serving_item.display_quantity if serving_item else original.quantity
        display_unit = serving_item.unit if serving_item else original.unit
        factor_result = _flavor_factor(original, request.flavors)
        factor = 1.0
        reason = "份数换算" if serving_item else ""
        rule = "servings" if serving_item else "unchanged"
        if original.functional:
            notices.append(f"{original.display_name}受功能性用料保护，未按口味缩放")
            rule = "functional_protected"
            reason = "功能性用料保护"
        elif factor_result is not None:
            factor, axes = factor_result
            factor = _bounded_factor(factor, request.adjustment_limit)
            display_quantity = float(
                (Decimal(str(display_quantity)) * Decimal(str(factor))).quantize(
                    Decimal("0.01"), rounding=ROUND_HALF_UP
                )
            )
            reason = (reason + "；" if reason else "") + f"味型滤镜（{axes}）"
            rule = "taste_filter"
        if display_quantity != original.quantity or display_unit != original.unit:
            item.quantity = display_quantity
            item.unit = display_unit
            if original.base_quantity is not None and original.quantity:
                item.base_quantity = float(
                    (
                        Decimal(str(original.base_quantity))
                        * Decimal(str(display_quantity))
                        / Decimal(str(original.quantity))
                    ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
                )
            changes.append(
                {
                    "ingredient_id": item.id,
                    "display_name": item.display_name,
                    "original_quantity": original.quantity,
                    "display_quantity": item.quantity,
                    "original_unit": original.unit,
                    "display_unit": item.unit,
                    "factor": factor,
                    "rule": rule,
                    "reason": reason or "份数换算",
                }
            )
        elif factor_result is not None or original.functional:
            # Explain a protected or capped rule even if the rounded value is equal.
            changes.append(
                {
                    "ingredient_id": item.id,
                    "display_name": item.display_name,
                    "original_quantity": original.quantity,
                    "display_quantity": original.quantity,
                    "original_unit": original.unit,
                    "display_unit": original.unit,
                    "factor": factor,
                    "rule": rule,
                    "reason": reason,
                }
            )
    if request.target_servings is not None:
        result.servings = request.target_servings
    return result, changes, notices
