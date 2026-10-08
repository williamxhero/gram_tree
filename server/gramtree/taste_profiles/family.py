"""Owner-locked family reads/mutations; never expose this data to ordinary projections."""

import base64
import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.errors import ApiError, NotFound
from gramtree.core.ids import new_id
from gramtree.ingredients.attributes import GB_ALLERGENS
from gramtree.ingredients.router import _resolve as resolve_ingredient
from gramtree.settings import Settings
from gramtree.taste_profiles import allergies, service
from gramtree.taste_profiles.family_schemas import FamilyMemberOut, FamilyMemberWrite
from gramtree.taste_profiles.models import FamilyMember, TasteProfile
from gramtree.taste_profiles.schemas import IngredientPreference, TasteScale

FAMILY_FIELD = "family_members"


def member_field(member_id: uuid.UUID) -> str:
    return f"{FAMILY_FIELD}.{member_id}"


def owned_member(session: Session, owner_id: uuid.UUID, member_id: uuid.UUID) -> FamilyMember:
    row = session.scalar(
        select(FamilyMember).where(FamilyMember.id == member_id, FamilyMember.owner_id == owner_id)
    )
    if row is None:
        raise NotFound()
    return row


def read_member(profile: TasteProfile, row: FamilyMember, settings: Settings) -> dict[str, Any]:
    allergies.require_grant(profile)
    return allergies.decrypt(settings, profile.owner_id, f"member:{row.id}:current", row.ciphertext)


def member_out(profile: TasteProfile, row: FamilyMember, settings: Settings) -> FamilyMemberOut:
    return FamilyMemberOut(id=row.id, **read_member(profile, row, settings))


def write_member(
    session: Session,
    profile: TasteProfile,
    settings: Settings,
    scale: TasteScale,
    body: FamilyMemberWrite,
    row: FamilyMember | None = None,
) -> FamilyMember:
    allergies.require_grant(profile)
    if (
        body.consent_id != profile.sensitive_consent_id
        or body.authorization_version != profile.sensitive_authorization_version
    ):
        raise ApiError(409, "sensitive_authorization_changed", "授权已变化，请重新打开家庭设置")
    if any(
        not (key == "spicy" and value == 0) and not scale.minimum <= value <= scale.maximum
        for key, value in body.flavors.items()
    ):
        raise ApiError(422, "invalid_request", "口味设置超出允许范围")
    preferences = []
    for value in body.avoidances:
        if value.ingredient_id is not None:
            ingredient = resolve_ingredient(session, value.ingredient_id)
            if ingredient is None or ingredient.id != value.ingredient_id:
                raise ApiError(422, "invalid_request", "请重新搜索选择标准食材")
        preferences.append(IngredientPreference(**value.model_dump(), preference="avoided"))
    avoidances = [
        {key: value for key, value in item.items() if key != "preference"}
        for item in service.normalize_preferences(session, preferences)
    ]
    if any(category not in GB_ALLERGENS for category in body.allergies.categories):
        raise ApiError(422, "invalid_request", "请选择已登记的过敏原类别")
    ingredients = {}
    for ingredient_id in body.allergies.ingredient_ids:
        ingredient = resolve_ingredient(session, ingredient_id)
        if ingredient is None or ingredient.id != ingredient_id:
            raise ApiError(422, "invalid_request", "请重新搜索选择标准食材")
        ingredients[str(ingredient.id)] = {
            "ingredient_id": str(ingredient.id),
            "name": ingredient.standard_name,
        }
    new = {
        "nickname": body.nickname,
        "age_band": body.age_band,
        "flavors": {key: value for key, value in body.flavors.items() if value != scale.default},
        "avoidances": avoidances,
        "allergies": {
            "categories": sorted(set(body.allergies.categories)),
            "ingredients": [ingredients[key] for key in sorted(ingredients)],
        },
        "source": "manual",
    }
    old = read_member(profile, row, settings) if row else {}
    if old == new and row is not None:
        return row
    member_id = row.id if row else new_id()
    # Encrypt all three payloads before mutating either current state or version.
    ciphertext = allergies.encrypt(settings, profile.owner_id, f"member:{member_id}:current", new)
    change_id = new_id()
    encrypted_old = {
        "encrypted": base64.b64encode(
            allergies.encrypt(settings, profile.owner_id, f"change:{change_id}:old", old)
        ).decode()
    }
    encrypted_new = {
        "encrypted": base64.b64encode(
            allergies.encrypt(settings, profile.owner_id, f"change:{change_id}:new", new)
        ).decode()
    }
    service.record_changes(
        session,
        profile,
        [service.FieldChange(member_field(member_id), encrypted_old, encrypted_new, id=change_id)],
    )
    if row is None:
        row = FamilyMember(id=member_id, owner_id=profile.owner_id, ciphertext=ciphertext)
        session.add(row)
    else:
        row.ciphertext = ciphertext
    return row
