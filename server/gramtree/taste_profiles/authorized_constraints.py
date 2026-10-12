"""The private, owner-authorized constraint read boundary.

Recipe personalization may inspect this short-lived value only after resolving the
owner and checking the current sensitive-information grant.  Callers must not
serialize, cache, or persist the returned names or allergy values.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.settings import Settings
from gramtree.taste_profiles import allergies, family, service
from gramtree.taste_profiles.models import FamilyMember


@dataclass(frozen=True)
class AuthorizedFamilyConstraints:
    nickname: str
    allergies: dict[str, Any]
    avoidances: tuple[dict[str, Any], ...]


@dataclass(frozen=True)
class AuthorizedConstraints:
    """Transient constraints for one owner; never put this in an API snapshot."""

    owner_allergies: dict[str, Any]
    owner_avoidances: tuple[dict[str, Any], ...]
    family: tuple[AuthorizedFamilyConstraints, ...]
    sensitive_authorized: bool


def read(
    session: Session,
    owner_id: uuid.UUID,
    settings: Settings,
) -> AuthorizedConstraints:
    """Read current constraints while holding the owner/profile lock.

    Ordinary owner avoidances remain usable without sensitive consent.  Allergies
    and family rows are read only when the current server-authorized grant exists;
    a withdrawn grant therefore cannot leave a stale family nickname or allergy
    in a recipe response.  Decryption failures deliberately propagate instead of
    weakening this boundary to plaintext or stale data.
    """

    profile = service.locked_profile(session, owner_id, service.scale_for(session))
    owner_avoidances = tuple(
        item for item in profile.ingredient_preferences if item.get("preference") == "avoided"
    )
    if profile.sensitive_consent_id is None:
        return AuthorizedConstraints(
            owner_allergies=dict(allergies.EMPTY),
            owner_avoidances=owner_avoidances,
            family=(),
            sensitive_authorized=False,
        )

    owner_allergies = allergies.read_sensitive(session, profile, settings)
    rows = session.scalars(
        select(FamilyMember)
        .where(FamilyMember.owner_id == owner_id)
        .order_by(FamilyMember.created_at, FamilyMember.id)
    )
    members = tuple(
        AuthorizedFamilyConstraints(
            nickname=str(value["nickname"]),
            allergies=dict(value.get("allergies") or allergies.EMPTY),
            avoidances=tuple(value.get("avoidances") or ()),
        )
        for row in rows
        for value in (family.read_member(profile, row, settings),)
    )
    return AuthorizedConstraints(
        owner_allergies=owner_allergies,
        owner_avoidances=owner_avoidances,
        family=members,
        sensitive_authorized=True,
    )
