"""Owner-checked, minimized context for one-line recipe generation.

Sensitive values are decrypted only for local hard checks. They are never part of
model payloads, replay keys, or generation logs. The dependency is an opaque,
versioned receipt for cache/request invalidation, not model context.
"""

from __future__ import annotations

import hashlib
import json
import uuid
from contextlib import suppress
from dataclasses import dataclass, field
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.recipes import food_safety
from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.settings import Settings
from gramtree.taste_profiles import allergies, family
from gramtree.taste_profiles.models import FamilyMember, TasteProfile


@dataclass(frozen=True)
class AllergyConstraints:
    categories: frozenset[str] = frozenset()
    ingredient_ids: frozenset[uuid.UUID] = frozenset()
    avoided_categories: frozenset[str] = frozenset()
    avoided_ingredient_ids: frozenset[uuid.UUID] = frozenset()

    @property
    def active(self) -> bool:
        return bool(
            self.categories
            or self.ingredient_ids
            or self.avoided_categories
            or self.avoided_ingredient_ids
        )


@dataclass(frozen=True)
class AuthorizedContext:
    model_payload: dict[str, Any]
    dependency: dict[str, Any]
    restrictions: AllergyConstraints = field(default_factory=AllergyConstraints)
    sensitive_available: bool = True


def _digest_ids(values: list[uuid.UUID]) -> str:
    return hashlib.sha256(",".join(sorted(map(str, values))).encode()).hexdigest()[:24]


def _minimal_profile(profile: TasteProfile) -> dict[str, Any] | None:
    if not profile.flavors and not profile.ingredient_preferences and not profile.local_cuisines:
        return None
    flavors = {
        key: round(float(value["coefficient"]), 3)
        for key, value in sorted(profile.flavors.items())
        if isinstance(value, dict) and isinstance(value.get("coefficient"), (int, float))
    }
    preferences = []
    for item in profile.ingredient_preferences:
        if not isinstance(item, dict):
            continue
        # Names are needed for useful generation, but no profile history, confidence,
        # timestamps or owner identifiers cross the model boundary.
        target = item.get("name") or item.get("category")
        if isinstance(target, str) and item.get("preference") in ("liked", "disliked", "avoided"):
            preferences.append({"target": target, "preference": item["preference"]})
    cuisines = [
        item.get("cuisine")
        for item in profile.local_cuisines
        if isinstance(item, dict) and isinstance(item.get("cuisine"), str)
    ]
    result: dict[str, Any] = {"flavors": flavors, "preferences": preferences}
    if cuisines:
        result["cuisines"] = cuisines[:20]
    return result


def _minimal_constraints(profile: TasteProfile) -> dict[str, Any] | None:
    values = profile.cooking_constraints
    if not isinstance(values, dict) or not values:
        return None
    allowed = ("household_servings", "equipment", "meal_times", "meal_templates")
    result = {key: values[key] for key in allowed if key in values}
    return result or None


def _merge_sensitive(target: dict[str, set[Any]], value: dict[str, Any]) -> None:
    for item in value.get("categories", []):
        if isinstance(item, str):
            target["categories"].add(item)
    for item in value.get("ingredients", []):
        if isinstance(item, dict):
            raw = item.get("ingredient_id")
            with suppress(ValueError, TypeError, AttributeError):
                target["ingredient_ids"].add(uuid.UUID(str(raw)))


def _read_restrictions(
    session: Session, profile: TasteProfile, settings: Settings
) -> AllergyConstraints:
    values: dict[str, set[Any]] = {
        "categories": set(),
        "ingredient_ids": set(),
        "avoided_categories": set(),
        "avoided_ingredient_ids": set(),
    }
    _merge_sensitive(values, allergies.read_sensitive(session, profile, settings))
    members = session.scalars(select(FamilyMember).where(FamilyMember.owner_id == profile.owner_id))
    for member in members:
        family_data = family.read_member(profile, member, settings)
        _merge_sensitive(values, family_data.get("allergies", {}))
        for item in family_data.get("avoidances", []):
            if not isinstance(item, dict):
                continue
            raw_id = item.get("ingredient_id")
            if raw_id:
                with suppress(ValueError, TypeError, AttributeError):
                    values["avoided_ingredient_ids"].add(uuid.UUID(str(raw_id)))
            elif isinstance(item.get("category"), str):
                values["avoided_categories"].add(item["category"])
    return AllergyConstraints(
        categories=frozenset(values["categories"]),
        ingredient_ids=frozenset(values["ingredient_ids"]),
        avoided_categories=frozenset(values["avoided_categories"]),
        avoided_ingredient_ids=frozenset(values["avoided_ingredient_ids"]),
    )


def build(session: Session, owner: User, settings: Settings) -> AuthorizedContext:
    profile = session.scalar(select(TasteProfile).where(TasteProfile.owner_id == owner.id))
    if profile is None:
        return AuthorizedContext(
            model_payload={"profile": None, "family": None, "cookware_profile": None},
            dependency={"profile": None, "sensitive": None},
        )
    dependency: dict[str, Any] = {
        "profile": str(profile.id),
        "profile_version": profile.version,
        "sensitive_authorization_version": profile.sensitive_authorization_version,
        "sensitive_consent_id": str(profile.sensitive_consent_id)
        if profile.sensitive_consent_id
        else None,
    }
    family_ids = list(
        session.scalars(select(FamilyMember.id).where(FamilyMember.owner_id == owner.id))
    )
    if family_ids:
        dependency["family_members"] = _digest_ids(family_ids)
    restrictions = AllergyConstraints()
    if profile.sensitive_consent_id is not None:
        restrictions = _read_restrictions(session, profile, settings)
    dependency["restriction_digest"] = hashlib.sha256(
        json.dumps(
            {
                "categories": sorted(restrictions.categories),
                "ingredients": sorted(map(str, restrictions.ingredient_ids)),
                "avoid_categories": sorted(restrictions.avoided_categories),
                "avoid_ingredients": sorted(map(str, restrictions.avoided_ingredient_ids)),
            },
            sort_keys=True,
        ).encode()
    ).hexdigest()[:24]
    # Family profiles remain server-side. Existing sensitive consent authorizes
    # storage, not sharing with an external model, so family is intentionally None.
    return AuthorizedContext(
        model_payload={
            "profile": _minimal_profile(profile),
            "family": None,
            "cookware_profile": _minimal_constraints(profile),
        },
        dependency=dependency,
        restrictions=restrictions,
    )


def violates(session: Session, snapshot: RecipeSnapshot, constraints: AllergyConstraints) -> bool:
    if not constraints.active:
        return False
    safety = food_safety.check(session, snapshot)
    if constraints.categories.intersection(safety.allergens):
        return True
    for item in snapshot.ingredients:
        if item.ingredient_id in constraints.ingredient_ids:
            return True
        if item.ingredient_id in constraints.avoided_ingredient_ids:
            return True
        if item.ingredient_id is not None:
            from gramtree.ingredients.models import Ingredient

            ingredient = session.get(Ingredient, item.ingredient_id)
            if ingredient and ingredient.category in constraints.avoided_categories:
                return True
    return False
