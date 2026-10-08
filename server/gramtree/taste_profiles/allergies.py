"""The sole authorized sensitive read/delete boundary.

No ordinary profile, export or AI projection includes this data. Callers hold the
stable owner lock (locked_profile); no plaintext is persisted, cached or logged.
Future consumers must use read_sensitive and erase_sensitive, not direct tables.
"""
import base64
import json
import os
import uuid
from datetime import datetime
from typing import Any

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from gramtree.accounts.models import Consent
from gramtree.core.errors import ApiError
from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.events.models import Event
from gramtree.events.service import record_taste_profile_changed
from gramtree.ingredients.attributes import GB_ALLERGENS
from gramtree.ingredients.router import _resolve as resolve_ingredient
from gramtree.settings import Settings
from gramtree.taste_profiles.models import OwnerAllergies, TasteProfile, TasteProfileChange

CONSENT_VERSION = "allergies-v1"
EMPTY: dict[str, Any] = {"categories": [], "ingredients": []}


def require_grant(profile: TasteProfile) -> None:
    if profile.sensitive_consent_id is None:
        raise ApiError(403, "sensitive_consent_required", "请先单独同意收集过敏信息")


def erase_sensitive(session: Session, owner_id: uuid.UUID) -> None:
    """Erase current, all identifiable history and metadata, without a decrypt key.

    Single transactional extension point for future sensitive dependent copies.
    Authorization invalidation/versioning belongs to the locked calling transaction.
    """
    changes = select(TasteProfileChange.id).where(
        TasteProfileChange.owner_id == owner_id, TasteProfileChange.field == "allergies"
    )
    session.execute(delete(Event).where(Event.user_id == owner_id, Event.id.in_(changes)))
    session.execute(delete(TasteProfileChange).where(
        TasteProfileChange.owner_id == owner_id, TasteProfileChange.field == "allergies"
    ))
    session.execute(delete(OwnerAllergies).where(OwnerAllergies.owner_id == owner_id))


def refresh_authorization(session: Session, profile: TasteProfile, now: datetime) -> None:
    records = list(session.scalars(select(Consent).where(
        Consent.user_id == profile.owner_id, Consent.kind == "sensitive_personal_info"
    )))
    withdrawals = [r for r in records if r.action == "withdraw"]
    # Server receipt is a revocation barrier: late offline grants dated before it
    # cannot revive consent. Same-time withdrawal always wins. Future grants are
    # stored for compatibility but permanently ineligible (not activated by time).
    barrier = max((max(r.occurred_at, r.received_at) for r in withdrawals), default=None)
    grants = [r for r in records if (
        r.action == "agree" and r.version == CONSENT_VERSION
        and r.occurred_at <= r.received_at and r.occurred_at <= now
        and (barrier is None or r.occurred_at > barrier)
    )]
    latest = max(grants, key=lambda r: (r.occurred_at, r.received_at, str(r.id)), default=None)
    grant_id = latest.id if latest else None
    if grant_id != profile.sensitive_consent_id:
        if grant_id is None:
            erase_sensitive(session, profile.owner_id)
        profile.sensitive_consent_id = grant_id
        profile.sensitive_authorization_version += 1
        profile.version += 1
        profile.updated_at = now


def _cipher(settings: Settings) -> AESGCM:
    try:
        secret = settings.sensitive_data_key
        if secret is None:
            raise ValueError()
        key = base64.b64decode(secret.get_secret_value(), altchars=b"-_", validate=True)
        if len(key) != 32:
            raise ValueError()
        return AESGCM(key)
    except (ValueError, TypeError):
        raise ApiError(503, "sensitive_key_unavailable", "私密信息暂不可用，请稍后重试") from None


def _aad(owner_id: uuid.UUID, slot: str) -> bytes:
    return f"gramtree:sensitive:v1:{owner_id}:{slot}".encode()


def encrypt(settings: Settings, owner_id: uuid.UUID, slot: str, value: dict) -> bytes:
    nonce = os.urandom(12)
    return nonce + _cipher(settings).encrypt(
        nonce, json.dumps(value, ensure_ascii=False, sort_keys=True).encode(), _aad(owner_id, slot)
    )


def decrypt(settings: Settings, owner_id: uuid.UUID, slot: str, ciphertext: bytes) -> dict[str, Any]:
    try:
        raw = _cipher(settings).decrypt(ciphertext[:12], ciphertext[12:], _aad(owner_id, slot))
        return json.loads(raw)
    except (InvalidTag, ValueError, TypeError):
        raise ApiError(503, "sensitive_key_unavailable", "私密信息暂不可用，请稍后重试") from None


def read_sensitive(session: Session, profile: TasteProfile, settings: Settings) -> dict[str, Any]:
    require_grant(profile)
    _cipher(settings)  # fail closed even for first save/empty state
    row = session.get(OwnerAllergies, profile.owner_id)
    return decrypt(settings, profile.owner_id, "current", row.ciphertext) if row else EMPTY


def mutate_sensitive(session: Session, profile: TasteProfile, settings: Settings, *,
                     consent_id: uuid.UUID, authorization_version: int,
                     categories: list[str], ingredient_ids: list[uuid.UUID]) -> None:
    require_grant(profile)
    if (consent_id != profile.sensitive_consent_id
            or authorization_version != profile.sensitive_authorization_version):
        raise ApiError(409, "sensitive_authorization_changed", "授权已变化，请重新打开过敏设置")
    old = read_sensitive(session, profile, settings)
    if any(category not in GB_ALLERGENS for category in categories):
        raise ApiError(422, "invalid_request", "请选择已登记的过敏原类别")
    ingredients = {}
    for ingredient_id in ingredient_ids:
        ingredient = resolve_ingredient(session, ingredient_id)
        # Unlike ordinary preference alias resolution, require the actual canonical ID.
        if ingredient is None or ingredient.id != ingredient_id:
            raise ApiError(422, "invalid_request", "请重新搜索选择标准食材")
        ingredients[str(ingredient.id)] = {"ingredient_id": str(ingredient.id), "name": ingredient.standard_name}
    new = {"categories": sorted(set(categories)), "ingredients": [ingredients[k] for k in sorted(ingredients)]}
    if old == new:
        return
    change_id = new_id()
    current_ciphertext = encrypt(settings, profile.owner_id, "current", new)
    old_ciphertext = encrypt(settings, profile.owner_id, f"change:{change_id}:old", old)
    new_ciphertext = encrypt(settings, profile.owner_id, f"change:{change_id}:new", new)
    profile.version += 1
    profile.updated_at = utcnow()
    row = session.get(OwnerAllergies, profile.owner_id)
    if row is None:
        session.add(OwnerAllergies(owner_id=profile.owner_id, ciphertext=current_ciphertext))
    else:
        row.ciphertext = current_ciphertext
    session.add(TasteProfileChange(
        id=change_id, profile_id=profile.id, owner_id=profile.owner_id,
        version=profile.version, field="allergies",
        old_value={"encrypted": base64.b64encode(old_ciphertext).decode()},
        new_value={"encrypted": base64.b64encode(new_ciphertext).decode()},
        source="manual", reason="你手动修改", status="active", created_at=profile.updated_at,
    ))
    record_taste_profile_changed(session, profile.owner_id, change_id, now=profile.updated_at)


def change_values(settings: Settings, owner_id: uuid.UUID, row: TasteProfileChange) -> dict[str, Any]:
    return {
        "old_value": decrypt(settings, owner_id, f"change:{row.id}:old", base64.b64decode(row.old_value["encrypted"])),
        "new_value": decrypt(settings, owner_id, f"change:{row.id}:new", base64.b64decode(row.new_value["encrypted"])),
    }
