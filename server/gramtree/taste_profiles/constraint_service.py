from pydantic import ValidationError
from sqlalchemy.orm import Session

from gramtree.core.errors import ApiError
from gramtree.runtime_config import service as config
from gramtree.taste_profiles.constraint_schemas import (
    DISH_TYPES,
    CookingConstraints,
    CookingConstraintsOut,
    CookingEquipmentVocabulary,
)
from gramtree.taste_profiles.models import TasteProfile
from gramtree.taste_profiles.service import FieldChange, record_changes


def constraints_out(session: Session, profile: TasteProfile) -> CookingConstraintsOut:
    try:
        vocabulary = CookingEquipmentVocabulary.model_validate(
            config.get(session, "taste.equipment")
        )
    except ValidationError as exc:
        raise ApiError(503, "equipment_config_invalid", "厨具词表暂不可用，请稍后重试") from exc
    return CookingConstraintsOut(
        profile_version=profile.version,
        constraints=CookingConstraints.model_validate(profile.cooking_constraints),
        equipment_vocabulary=vocabulary.items,
        dish_types=list(DISH_TYPES),
        servings_min=int(config.get(session, "recipe.servings_min")),
        servings_max=int(config.get(session, "recipe.servings_max")),
    )


def replace_constraints(session: Session, profile: TasteProfile, body: CookingConstraints) -> None:
    current = constraints_out(session, profile)
    if body.household_servings is not None and not (
        current.servings_min <= body.household_servings <= current.servings_max
    ):
        raise ApiError(422, "invalid_request", "家庭人数超出份数换算范围")
    if not set(body.equipment) <= {item.id for item in current.equipment_vocabulary}:
        raise ApiError(422, "invalid_request", "请从厨具词表中选择厨具")
    # Preserve the user's equipment order; normalize meal slots for stable reads.
    values = body.model_dump(mode="json")
    for field in ("meal_times", "meal_templates"):
        values[field] = sorted(values[field], key=lambda value: (value["day_type"], value["meal"]))
    changes = record_changes(
        session,
        profile,
        [FieldChange("cooking_constraints", current.constraints.model_dump(mode="json"), values)],
    )
    if changes:
        profile.cooking_constraints = values
