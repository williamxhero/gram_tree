"""Private profile mutations: serialize by owner; values/history share one transaction.

Callers own commit. Later profile slices reuse locked_profile and record_changes;
never commit between changing current values and recording their shared version.
"""

import uuid
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.errors import AccountUnavailable
from gramtree.accounts.models import User, UserStatus
from gramtree.core.errors import ApiError
from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.events.service import record_taste_profile_changed
from gramtree.ingredients.importer import CATEGORIES
from gramtree.ingredients.router import _resolve as resolve_ingredient
from gramtree.runtime_config import service as config
from gramtree.taste_profiles.models import TasteProfile, TasteProfileChange
from gramtree.taste_profiles.schemas import (
    FLAVOR_KEYS,
    FlavorKey,
    IngredientPreference,
    IngredientPreferenceOut,
    LocalCuisineOut,
    TasteFlavorOut,
    TasteProfileOut,
    TasteScale,
)


def scale_for(session: Session) -> TasteScale:
    try:
        return TasteScale.model_validate(config.get(session, "taste.scale"))
    except ValidationError as exc:
        raise ApiError(503, "taste_config_invalid", "口味档位配置暂不可用，请稍后重试") from exc


def defaults(scale: TasteScale) -> dict[str, Any]:
    return {key: {"coefficient": scale.default, "confidence": "low"} for key in FLAVOR_KEYS}


def lock_owner(session: Session, owner_id: uuid.UUID) -> None:
    owner_status = session.scalar(select(User.status).where(User.id == owner_id).with_for_update())
    # Auth was checked before acquiring this lock; deletion may have won the race.
    if owner_status != UserStatus.active:
        raise AccountUnavailable()


def locked_profile(session: Session, owner_id: uuid.UUID, scale: TasteScale) -> TasteProfile:
    # SELECT FOR UPDATE on an absent profile cannot serialize first reads.
    lock_owner(session, owner_id)
    profile = session.scalar(
        select(TasteProfile)
        .where(TasteProfile.owner_id == owner_id)
        .execution_options(populate_existing=True)
    )
    if profile is None:
        profile = TasteProfile(
            owner_id=owner_id, flavors=defaults(scale), version=1, local_cuisines=[]
        )
        session.add(profile)
        session.flush()
    return profile


@dataclass(frozen=True)
class FieldChange:
    field: str
    old_value: dict[str, Any]
    new_value: dict[str, Any]
    id: uuid.UUID | None = None


def record_changes(
    session: Session,
    profile: TasteProfile,
    changes: list[FieldChange],
    *,
    reason: str = "你手动修改",
    source: str = "manual",
) -> list[TasteProfileChange]:
    actual = [change for change in changes if change.old_value != change.new_value]
    if not actual:
        return []
    profile.version += 1
    profile.updated_at = utcnow()
    rows = [
        TasteProfileChange(
            id=change.id or new_id(),
            profile_id=profile.id,
            owner_id=profile.owner_id,
            version=profile.version,
            field=change.field,
            old_value=change.old_value,
            new_value=change.new_value,
            reason=reason,
            source=source,
            created_at=profile.updated_at,
        )
        for change in actual
    ]
    session.add_all(rows)
    session.flush()
    for row in rows:
        record_taste_profile_changed(session, profile.owner_id, row.id, now=row.created_at)
    return rows


def mutate_profile(
    session: Session,
    profile: TasteProfile,
    values: Mapping[FlavorKey, float],
    scale: TasteScale,
    *,
    ingredient_preferences: list[IngredientPreference] | None = None,
    reset: bool = False,
) -> list[TasteProfileChange]:
    if any(not scale.minimum <= value <= scale.maximum for value in values.values()):
        raise ApiError(422, "invalid_request", "口味设置超出允许范围")
    flavors = dict(profile.flavors)
    changes = []
    for key, value in values.items():
        new = {"coefficient": value, "confidence": "low" if reset else "high"}
        changes.append(FieldChange(f"flavors.{key}", flavors[key], new))
        flavors[key] = new
    items = profile.ingredient_preferences
    if ingredient_preferences is not None:
        items = normalize_preferences(session, ingredient_preferences)
        changes.append(
            FieldChange(
                "ingredient_preferences",
                {"items": profile.ingredient_preferences},
                {"items": items},
            )
        )
    # Validate every submitted field before recording one shared mutation version.
    rows = record_changes(session, profile, changes)
    if rows:
        profile.flavors = flavors
        profile.ingredient_preferences = items
    return rows


def normalize_preferences(
    session: Session, values: list[IngredientPreference]
) -> list[dict[str, Any]]:
    by_target: dict[str, dict[str, Any]] = {}
    for value in values:
        if value.ingredient_id is not None:
            ingredient = resolve_ingredient(session, value.ingredient_id)
            if ingredient is None:
                raise ApiError(422, "invalid_ingredient_reference", "食材不存在，请重新搜索选择")
            item = IngredientPreferenceOut(
                ingredient_id=ingredient.id,
                preference=value.preference,
                name=ingredient.standard_name,
            )
        else:
            if value.category not in CATEGORIES:
                raise ApiError(422, "invalid_ingredient_category", "食材分类无效，请重新选择")
            item = IngredientPreferenceOut(
                category=value.category, preference=value.preference, name=value.category
            )
        key = (
            f"ingredient:{item.ingredient_id}"
            if item.ingredient_id
            else f"category:{item.category}"
        )
        if key in by_target and by_target[key]["preference"] != item.preference:
            raise ApiError(422, "conflicting_ingredient_preference", "同一食材或分类只能有一种偏好")
        by_target[key] = item.model_dump(mode="json")
    # Preferences are a set of explicit targets, not an ordered list. Reordering
    # or repeated identical selections must not create a new profile version.
    return [by_target[key] for key in sorted(by_target)]


def profile_out(profile: TasteProfile, scale: TasteScale) -> TasteProfileOut:
    flavors = {}
    for key, value in profile.flavors.items():
        level = min(range(5), key=lambda i: abs(scale.levels[i].coefficient - value["coefficient"]))
        high = value["confidence"] == "high"
        flavors[key] = TasteFlavorOut(
            **value,
            confidence_text="把握高：你手动设置" if high else "把握低：暂用标准，还不了解你的口味",
            level=level,
            label=scale.levels[level].label,
        )
    return TasteProfileOut(
        id=profile.id,
        version=profile.version,
        flavors=flavors,
        scale=scale,
        local_cuisines=[LocalCuisineOut.model_validate(row) for row in profile.local_cuisines],
        ingredient_preferences=[
            IngredientPreferenceOut.model_validate(row) for row in profile.ingredient_preferences
        ],
        ingredient_categories=list(CATEGORIES),
    )
