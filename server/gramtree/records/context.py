"""Server-derived, non-identifying context frozen on cooking records."""

import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.settings import Settings
from gramtree.taste_profiles import family, service
from gramtree.taste_profiles.models import FamilyMember


def flavor_level(coefficient: Any) -> str:
    try:
        value = float(coefficient)
    except (TypeError, ValueError):
        return "standard"
    if value <= 0.65:
        return "much_less"
    if value <= 0.9:
        return "less"
    if value < 1.1:
        return "standard"
    if value < 1.35:
        return "more"
    return "much_more"


def build(
    session: Session,
    owner: uuid.UUID,
    co_diner_ids: list[uuid.UUID],
    settings: Settings,
) -> tuple[dict[str, Any], list[uuid.UUID]]:
    profile = service.locked_profile(session, owner, service.scale_for(session))
    rows = {
        row.id: row
        for row in session.scalars(select(FamilyMember).where(FamilyMember.owner_id == owner))
    }
    if co_diner_ids:
        if profile.sensitive_consent_id is None:
            raise ValueError("sensitive_consent_required")
        if len(set(co_diner_ids)) != len(co_diner_ids) or any(
            item not in rows for item in co_diner_ids
        ):
            raise ValueError("invalid_co_diners")
    children = False
    for item in co_diner_ids:
        value = family.read_member(profile, rows[item], settings)
        children = children or value.get("age_band") in {
            "under_1",
            "1_to_3",
            "3_to_6",
            "6_to_12",
            "12_to_18",
        }
    flavors = {
        key: {
            "level": flavor_level(value.get("coefficient")),
            "confidence": value.get("confidence", "low"),
        }
        for key, value in profile.flavors.items()
        if isinstance(value, dict)
    }
    return {
        "flavors": flavors,
        "avoidance_count": sum(
            1
            for item in profile.ingredient_preferences
            if isinstance(item, dict) and item.get("preference") == "avoided"
        ),
        "child_diner": children,
    }, list(co_diner_ids)
