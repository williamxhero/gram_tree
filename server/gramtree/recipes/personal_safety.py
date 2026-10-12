"""Transient recipe checks against the viewer's authorized constraints."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from sqlalchemy.orm import Session

from gramtree.ingredients.attributes import IngredientAttributes
from gramtree.ingredients.models import Ingredient, IngredientAttribute
from gramtree.recipes.schemas import (
    RecipeIngredient,
    RecipePersonalSafety,
    RecipePersonalSafetyAlert,
    RecipeSnapshot,
)
from gramtree.settings import Settings
from gramtree.taste_profiles import authorized_constraints


@dataclass(frozen=True)
class _Target:
    label: str
    ingredient_id: str | None
    category: str | None
    allergens: frozenset[str]
    unknown: bool
    replacement: bool
    recipe_ingredient_id: str


def _target(
    session: Session,
    item: RecipeIngredient,
    *,
    display_name: str,
    ingredient_id: Any,
    replacement: bool,
) -> _Target:
    if ingredient_id is None:
        return _Target(
            label=display_name,
            ingredient_id=None,
            category=None,
            allergens=frozenset(),
            unknown=True,
            replacement=replacement,
            recipe_ingredient_id=item.id,
        )
    ingredient = session.get(Ingredient, ingredient_id)
    if ingredient is None:
        return _Target(
            label=display_name,
            ingredient_id=str(ingredient_id),
            category=None,
            allergens=frozenset(),
            unknown=True,
            replacement=replacement,
            recipe_ingredient_id=item.id,
        )
    attrs = IngredientAttributes.from_stored(
        {
            row.field: (row.value, row.source, row.status)
            for row in session.query(IngredientAttribute).filter_by(ingredient_id=ingredient.id)
        }
    )
    return _Target(
        label=display_name,
        ingredient_id=str(ingredient.id),
        category=ingredient.category,
        allergens=frozenset(attrs.allergens.value if attrs.allergens is not None else ()),
        unknown=attrs.allergens is None,
        replacement=replacement,
        recipe_ingredient_id=item.id,
    )


def _targets(session: Session, item: RecipeIngredient) -> tuple[_Target, ...]:
    result = [
        _target(
            session,
            item,
            display_name=item.display_name,
            ingredient_id=item.ingredient_id,
            replacement=False,
        )
    ]
    replacement = item.replacement
    if replacement is None:
        return tuple(result)
    if isinstance(replacement, str):
        result.append(
            _target(
                session,
                item,
                display_name=replacement,
                ingredient_id=None,
                replacement=True,
            )
        )
    else:
        result.append(
            _target(
                session,
                item,
                display_name=replacement.display_name,
                ingredient_id=replacement.ingredient_id,
                replacement=True,
            )
        )
    return tuple(result)


def _allergy_values(value: dict[str, Any]) -> tuple[set[str], set[str]]:
    categories = {str(item) for item in value.get("categories") or ()}
    ingredients = {
        str(item.get("ingredient_id"))
        for item in value.get("ingredients") or ()
        if isinstance(item, dict) and item.get("ingredient_id")
    }
    return categories, ingredients


def _avoidance_values(value: tuple[dict[str, Any], ...]) -> tuple[set[str], set[str]]:
    categories: set[str] = set()
    ingredients: set[str] = set()
    for item in value:
        if item.get("category"):
            categories.add(str(item["category"]))
        if item.get("ingredient_id"):
            ingredients.add(str(item["ingredient_id"]))
    return categories, ingredients


def _matches(
    target: _Target,
    *,
    allergy_categories: set[str],
    allergy_ingredients: set[str],
    avoidance_categories: set[str],
    avoidance_ingredients: set[str],
) -> tuple[bool, bool]:
    allergy = bool(
        target.ingredient_id in allergy_ingredients if target.ingredient_id is not None else False
    ) or bool(target.allergens.intersection(allergy_categories))
    avoidance = bool(
        target.ingredient_id in avoidance_ingredients if target.ingredient_id is not None else False
    ) or bool(target.category and target.category in avoidance_categories)
    return allergy, avoidance


def check(
    session: Session,
    snapshot: RecipeSnapshot,
    owner_id: Any,
    settings: Settings,
) -> RecipePersonalSafety:
    """Cross-check only the current authorized state for this owner.

    This function returns no private values for a viewer without the sensitive
    grant.  It also treats missing standard allergen data as incomplete rather
    than claiming that an ingredient is safe.
    """

    constraints = authorized_constraints.read(session, owner_id, settings)
    if not constraints.sensitive_authorized:
        # Owner avoidances are ordinary profile data and can still produce the
        # light warning; no allergy/family data is read or inferred here.
        people = (("你", constraints.owner_allergies, constraints.owner_avoidances),)
        status = "not_authorized"
    else:
        people = [("你", constraints.owner_allergies, constraints.owner_avoidances)]
        people.extend(
            (member.nickname, member.allergies, member.avoidances) for member in constraints.family
        )
        status = "available"

    alerts: list[RecipePersonalSafetyAlert] = []
    unknown: set[str] = set()
    seen: set[tuple[str, str, str, str, bool]] = set()
    for item in snapshot.ingredients:
        for target in _targets(session, item):
            if target.unknown:
                unknown.add(target.label)
            for person, allergy_value, avoidances in people:
                allergy_categories, allergy_ingredients = _allergy_values(allergy_value)
                avoidance_categories, avoidance_ingredients = _avoidance_values(avoidances)
                allergy, avoidance = _matches(
                    target,
                    allergy_categories=allergy_categories,
                    allergy_ingredients=allergy_ingredients,
                    avoidance_categories=avoidance_categories,
                    avoidance_ingredients=avoidance_ingredients,
                )
                if allergy:
                    targets = []
                    if target.ingredient_id in allergy_ingredients:
                        targets.append(target.label)
                    targets.extend(sorted(target.allergens.intersection(allergy_categories)))
                    for matched in dict.fromkeys(targets):
                        key = (person, "allergy", matched, target.label, target.replacement)
                        if key not in seen:
                            seen.add(key)
                            alerts.append(
                                RecipePersonalSafetyAlert(
                                    person=person,
                                    kind="allergy",
                                    target=matched,
                                    ingredient=target.label,
                                    replacement=target.replacement,
                                )
                            )
                if avoidance:
                    matched = (
                        target.label
                        if target.ingredient_id in avoidance_ingredients
                        else target.category or target.label
                    )
                    key = (person, "avoidance", matched, target.label, target.replacement)
                    if key not in seen:
                        seen.add(key)
                        alerts.append(
                            RecipePersonalSafetyAlert(
                                person=person,
                                kind="avoidance",
                                target=matched,
                                ingredient=target.label,
                                replacement=target.replacement,
                            )
                        )

    return RecipePersonalSafety(
        status=status,
        alerts=alerts,
        unknown_ingredients=sorted(unknown),
        incomplete=bool(unknown),
    )
