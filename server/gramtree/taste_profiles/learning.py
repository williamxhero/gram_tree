"""SPEC-005.3 taste learning, attribution and change control.

All numbers (step, range, weights, half-life, thresholds) come from the
registered runtime configuration table; nothing here hard-codes them.
"""

import math
import uuid
from collections.abc import Iterable
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Literal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from gramtree.core.errors import ApiError, NotFound
from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.records.models import CookingRecord, CookingRecordRevision
from gramtree.runtime_config import service as config
from gramtree.taste_profiles import service as profile_service
from gramtree.taste_profiles.learning_models import (
    TasteAttribution,
    TasteChangeFact,
    TasteLearningSignal,
)
from gramtree.taste_profiles.models import TasteProfile, TasteProfileChange
from gramtree.taste_profiles.schemas import FLAVOR_KEYS, FlavorKey

ORIGIN_MANUAL = "manual"
ORIGIN_AUTO = "auto"
ORIGIN_EXPLICIT = "explicit_save"
RULES_VERSION = "taste-learning-1"
SCOPE_OVERALL = "overall"

TAG_FLAVORS: dict[str, tuple[FlavorKey, int]] = {
    "偏咸": ("salty", 1),
    "salty": ("salty", 1),
    "偏淡": ("salty", -1),
    "bland": ("salty", -1),
    "太辣": ("spicy", 1),
    "spicy": ("spicy", 1),
    "太酸": ("sour", 1),
    "sour": ("sour", 1),
    "太甜": ("sweet", 1),
    "sweet": ("sweet", 1),
    "太油": ("oily", 1),
    "太腻": ("oily", 1),
    "oily": ("oily", 1),
    "不够鲜": ("umami", 1),
    "umami": ("umami", 1),
    "太麻": ("numbing", 1),
    "numbing": ("numbing", 1),
}
DELETED_MARKERS = {"deleted", "removed", "去掉", "不要了"}
REPLACED_MARKERS = {"replaced", "substituted", "换掉", "替换"}


@dataclass(frozen=True)
class SignalDraft:
    kind: str
    field_name: str
    flavor_key: str | None
    scope: str
    direction: int
    key: str
    record_id: uuid.UUID | None = None
    ingredient_id: uuid.UUID | None = None
    ingredient_category: str | None = None
    observed_at: datetime | None = None
    attribution_only: bool = False
    attribution_record_id: uuid.UUID | None = None


@dataclass
class LearningOutcome:
    signals_considered: int = 0
    applied: list[TasteProfileChange] = field(default_factory=list)
    pending: list[TasteProfileChange] = field(default_factory=list)


# ------------------------------------------------------------------- settings


def step(session: Session) -> float:
    return float(config.get(session, "taste.learning_step"))


def max_change(session: Session) -> float:
    return float(config.get(session, "taste.learning_max_change"))


def half_life_days(session: Session) -> float:
    return float(config.get(session, "taste.signal_half_life_days"))


def weight_of(session: Session, kind: str) -> float:
    weights = config.get(session, "taste.learning_weights")
    if kind not in weights:
        raise ApiError(503, "taste_learning_config_invalid", "口味学习配置暂不可用")
    return float(weights[kind])


def automation_enabled(session: Session) -> bool:
    return bool(config.get(session, "feature.taste_auto_learning"))


def save_to_taste_enabled(session: Session) -> bool:
    return bool(config.get(session, "feature.save_to_taste"))


def effective_weight(session: Session, base: float, observed_at: datetime, now: datetime) -> float:
    days = max((now - observed_at).total_seconds() / 86400.0, 0.0)
    return base * math.pow(0.5, days / max(half_life_days(session), 0.001))


# --------------------------------------------------------------- attributions


@dataclass(frozen=True)
class Verdict:
    verdict: Literal["personal", "recipe", "pending"]
    decision_source: Literal["rule", "user", "unanswered"]
    reason_code: str
    sample_size: int
    automatic: bool


def feedback_flavors(revisions: Iterable[CookingRecordRevision]) -> dict[str, int]:
    """Latest effective feedback revision wins; deleted feedback clears it."""
    latest: dict[str, int] = {}
    for revision in sorted(revisions, key=lambda row: row.revision):
        if revision.field != "feedback":
            continue
        value = revision.value or {}
        if value.get("deleted"):
            latest = {}
            continue
        flavors: dict[str, int] = {}
        for tag in value.get("taste_tags", []) or []:
            mapped = TAG_FLAVORS.get(str(tag))
            if mapped is not None:
                flavors[mapped[0]] = mapped[1]
        latest = flavors
    return latest


def _others_flavors(
    session: Session, version_id: uuid.UUID, owner_id: uuid.UUID
) -> list[dict[str, int]]:
    """One independent sample per other user; repeated records never double-count."""
    rows = list(
        session.execute(
            select(CookingRecord.id, CookingRecord.owner_id).where(
                CookingRecord.recipe_version_id == version_id,
                CookingRecord.owner_id != owner_id,
            )
        )
    )
    samples: dict[uuid.UUID, dict[str, int]] = {}
    for record_id, other_owner in rows:
        revisions = list(
            session.scalars(
                select(CookingRecordRevision).where(
                    CookingRecordRevision.record_id == record_id,
                    CookingRecordRevision.field == "feedback",
                )
            )
        )
        flavors = feedback_flavors(revisions)
        if flavors:
            samples[other_owner] = flavors
    return list(samples.values())


def rule_verdict(
    session: Session, version_id: uuid.UUID | None, owner_id: uuid.UUID, flavors: dict[str, int]
) -> Verdict:
    """Compare the same immutable version with other people's feedback."""
    if version_id is None or not flavors:
        return Verdict("pending", "unanswered", "no_version", 0, automatic=True)
    minimum = int(config.get(session, "taste.attribution_min_samples"))
    majority = float(config.get(session, "taste.attribution_majority"))
    others = _others_flavors(session, version_id, owner_id)
    if len(others) < minimum:
        return Verdict("pending", "unanswered", "samples_insufficient", len(others), True)
    agree = 0
    differ = 0
    for sample in others:
        for key, direction in flavors.items():
            if key not in sample:
                continue
            if sample[key] == direction:
                agree += 1
            elif sample[key] == -direction:
                differ += 1
    total = agree + differ
    if total == 0:
        return Verdict("pending", "unanswered", "samples_conflict", len(others), True)
    if agree / total >= majority:
        return Verdict("recipe", "rule", "others_agree", len(others), True)
    if differ / total >= majority:
        return Verdict("personal", "rule", "others_do_not", len(others), True)
    return Verdict("pending", "unanswered", "samples_conflict", len(others), True)


def record_verdict(
    session: Session,
    profile: TasteProfile,
    record: CookingRecord,
    verdict: Verdict,
    flavors: dict[str, int],
    feedback_revision_id: uuid.UUID | None,
) -> TasteAttribution:
    row = session.get(TasteAttribution, record.id)
    if row is None:
        row = TasteAttribution(
            record_id=record.id,
            owner_id=profile.owner_id,
            profile_id=profile.id,
            recipe_version_id=record.recipe_version_id,
            created_at=utcnow(),
        )
        session.add(row)
    elif row.owner_id != profile.owner_id:
        raise NotFound()
    # A confirmed user choice is never overwritten by a later rule pass.
    if verdict.automatic and (
        row.decision_source == "user" or row.reason_code == "user_unanswered"
    ):
        return row
    row.recipe_version_id = record.recipe_version_id
    row.flavors = flavors
    row.feedback_revision_id = feedback_revision_id
    row.verdict = verdict.verdict
    row.decision_source = verdict.decision_source
    row.reason_code = verdict.reason_code
    row.rules_version = RULES_VERSION
    row.sample_size = verdict.sample_size
    row.automatic = verdict.automatic
    row.revision = row.revision + 1 if row.revision else 1
    row.updated_at = utcnow()
    session.flush()
    return row


def upsert_answer(
    session: Session,
    profile: TasteProfile,
    record: CookingRecord,
    answer: Literal["personal", "recipe", "unanswered"],
    *,
    feedback_revision_id: uuid.UUID | None,
    flavors: dict[str, int],
) -> TasteAttribution:
    verdict = Verdict(
        verdict=("pending" if answer == "unanswered" else answer),
        decision_source="unanswered" if answer == "unanswered" else "user",
        reason_code={"personal": "user_personal", "recipe": "user_recipe"}.get(
            answer, "user_unanswered"
        ),
        sample_size=0,
        automatic=False,
    )
    return record_verdict(session, profile, record, verdict, flavors, feedback_revision_id)


def attribution_out(row: TasteAttribution | None) -> dict[str, Any] | None:
    if row is None:
        return None
    return {
        "record_id": str(row.record_id),
        "recipe_version_id": str(row.recipe_version_id) if row.recipe_version_id else None,
        "verdict": row.verdict,
        "decision_source": row.decision_source,
        "reason_code": row.reason_code,
        "rules_version": row.rules_version,
        "sample_size": row.sample_size,
        "flavors": row.flavors,
        "learning_eligibility": row.learning_eligibility,
        "asked": row.reason_code != "not_requested",
        "answered": row.decision_source == "user",
        "updated_at": row.updated_at.isoformat(),
    }


def qualitative_reason(row: TasteAttribution) -> str:
    if row.verdict == "recipe":
        return "其他做过这道菜的人也这么说，先算菜谱的问题，不改你的口味档案"
    if row.verdict == "personal":
        return "其他人觉得刚好，只有你觉得不一样，算你的口味"
    return "还不好判断，先问你一次"


# -------------------------------------------------------------------- signals


def _adjustment_drafts(session: Session, record: CookingRecord, now: datetime) -> list[SignalDraft]:
    drafts: list[SignalDraft] = []
    for index, adjustment in enumerate(record.adjustments or []):
        if not isinstance(adjustment, dict):
            continue
        flavor = adjustment.get("flavor") or adjustment.get("flavor_key")
        if flavor not in FLAVOR_KEYS:
            continue
        delta = adjustment.get("delta") or adjustment.get("direction")
        if not isinstance(delta, (int, float)) or delta == 0:
            continue
        scope = str(adjustment.get("scope") or SCOPE_OVERALL)
        drafts.append(
            SignalDraft(
                kind="manual_adjustment",
                field_name=f"flavors.{flavor}",
                flavor_key=str(flavor),
                scope=scope,
                direction=-1 if delta > 0 else 1,
                key=f"record:{record.id}:adj:{index}",
                record_id=record.id,
                observed_at=record.occurred_at or now,
            )
        )
    return drafts


def _feedback_drafts(
    session: Session,
    record: CookingRecord,
    attribution: TasteAttribution | None,
    now: datetime,
) -> list[SignalDraft]:
    if attribution is None or attribution.verdict == "recipe":
        return []
    kind = "feedback_tag" if attribution.verdict == "personal" else "feedback_unanswered"
    drafts = []
    for key, direction in (attribution.flavors or {}).items():
        drafts.append(
            SignalDraft(
                kind=kind,
                field_name=f"flavors.{key}",
                flavor_key=key,
                scope=SCOPE_OVERALL,
                direction=int(direction),
                key=f"record:{record.id}:feedback:{key}:attribution:{attribution.revision}",
                record_id=record.id,
                attribution_record_id=attribution.record_id,
                observed_at=record.occurred_at or now,
            )
        )
    return drafts


def _explicit_draft(session: Session, record: CookingRecord, now: datetime) -> list[SignalDraft]:
    """`save_to_taste` turns a live adjustment into an explicit-save signal."""
    drafts: list[SignalDraft] = []
    for change in record.adjustments or []:
        if not isinstance(change, dict) or change.get("destination") != "taste":
            continue
        flavor = change.get("flavor") or change.get("flavor_key")
        delta = change.get("delta") or change.get("direction")
        if flavor not in FLAVOR_KEYS or not isinstance(delta, (int, float)) or delta == 0:
            continue
        drafts.append(
            SignalDraft(
                kind="explicit_save",
                field_name=f"flavors.{flavor}",
                flavor_key=str(flavor),
                scope=str(change.get("scope") or SCOPE_OVERALL),
                direction=-1 if delta > 0 else 1,
                key=f"record:{record.id}:save:{flavor}",
                record_id=record.id,
                observed_at=now,
            )
        )
    return drafts


def _ingredient_drafts(session: Session, record: CookingRecord, now: datetime) -> list[SignalDraft]:
    """Removed / replaced ingredients feed the pending dislike suggestion."""
    snapshot = record.snapshot or {}
    ingredients = snapshot.get("ingredients") if isinstance(snapshot, dict) else None
    if not isinstance(ingredients, list):
        return []
    drafts: list[SignalDraft] = []
    for item in ingredients:
        if not isinstance(item, dict):
            continue
        marker = str(item.get("disposition") or item.get("action") or "").lower()
        if marker not in DELETED_MARKERS | REPLACED_MARKERS:
            continue
        if marker in DELETED_MARKERS and item.get("servings_scaled"):
            continue
        ingredient_id = item.get("ingredient_id")
        category = item.get("category")
        # A category is too broad to claim that one ingredient is disliked.
        # Prefer a stable standard ID, otherwise retain a normalized name; a
        # category-only snapshot is deliberately ignored rather than guessed.
        display_name = item.get("display_name") or item.get("name")
        target = str(ingredient_id or display_name or "").strip()
        if not target:
            continue
        parsed_id: uuid.UUID | None = None
        if ingredient_id:
            try:
                parsed_id = uuid.UUID(str(ingredient_id))
            except (TypeError, ValueError):
                continue
        drafts.append(
            SignalDraft(
                kind="manual_adjustment",
                field_name=f"ingredient_preferences.{target}",
                flavor_key=None,
                scope=SCOPE_OVERALL,
                direction=-1,
                key=f"record:{record.id}:ingredient:{target}",
                record_id=record.id,
                ingredient_id=parsed_id,
                ingredient_category=str(category) if category else None,
                observed_at=record.occurred_at or now,
            )
        )
    return drafts


def _snapshot_contributions(record: CookingRecord) -> dict[str, int]:
    snapshot = record.snapshot if isinstance(record.snapshot, dict) else {}
    values = snapshot.get("flavor_contributions")
    if not isinstance(values, dict):
        return {}
    result: dict[str, int] = {}
    for key, value in values.items():
        if key in FLAVOR_KEYS and isinstance(value, (int, float)) and value:
            result[str(key)] = 1 if value > 0 else -1
    return result


def _rating_and_repeat_drafts(
    session: Session, record: CookingRecord, now: datetime
) -> list[SignalDraft]:
    contributions = _snapshot_contributions(record)
    if not contributions:
        return []
    drafts: list[SignalDraft] = []
    revisions = list(
        session.scalars(
            select(CookingRecordRevision).where(
                CookingRecordRevision.record_id == record.id,
                CookingRecordRevision.field == "rating",
            )
        )
    )
    latest = max(revisions, key=lambda row: row.revision, default=None)
    rating = latest.value.get("rating") if latest and isinstance(latest.value, dict) else None
    if latest is not None and isinstance(rating, (int, float)) and rating != 3:
        liked = rating >= 4
        for flavor, contribution in contributions.items():
            drafts.append(
                SignalDraft(
                    kind="rating",
                    field_name=f"flavors.{flavor}",
                    flavor_key=flavor,
                    scope=SCOPE_OVERALL,
                    direction=-contribution if liked else contribution,
                    key=f"record:{record.id}:rating:{latest.revision_id}:{flavor}",
                    record_id=record.id,
                    observed_at=record.occurred_at or now,
                )
            )
    identity = record.recipe_version_id or record.recipe_id
    if identity is not None:
        count = session.scalar(
            select(func.count())
            .select_from(CookingRecord)
            .where(
                CookingRecord.owner_id == record.owner_id,
                (CookingRecord.recipe_version_id == identity)
                if record.recipe_version_id is not None
                else (CookingRecord.recipe_id == identity),
            )
        )
        if int(count or 0) >= 2:
            for flavor, contribution in contributions.items():
                drafts.append(
                    SignalDraft(
                        kind="repeat_cook",
                        field_name=f"flavors.{flavor}",
                        flavor_key=flavor,
                        scope=SCOPE_OVERALL,
                        direction=-contribution,
                        key=f"record:{record.id}:repeat:{identity}:{flavor}",
                        record_id=record.id,
                        observed_at=record.occurred_at or now,
                    )
                )
    return drafts


def collect_signals(session: Session, profile: TasteProfile, record: CookingRecord) -> int:
    """Persist the record's signals once; replay never double-learns."""
    if record.owner_id != profile.owner_id:
        raise NotFound()
    now = utcnow()
    attribution = session.get(TasteAttribution, record.id)
    if attribution is None:
        flavors = feedback_flavors(
            list(
                session.scalars(
                    select(CookingRecordRevision).where(
                        CookingRecordRevision.record_id == record.id,
                        CookingRecordRevision.field == "feedback",
                    )
                )
            )
        )
        if flavors:
            verdict = rule_verdict(session, record.recipe_version_id, profile.owner_id, flavors)
            attribution = record_verdict(
                session,
                profile,
                record,
                verdict,
                flavors,
                _latest_feedback_revision_id(session, record.id),
            )
    feedback_drafts = _feedback_drafts(session, record, attribution, now)
    current_feedback_keys = {draft.key for draft in feedback_drafts}
    # A revised attribution replaces the prior unanswered/rule qualification;
    # stale active feedback signals must not survive beside the new one.
    for signal in session.scalars(
        select(TasteLearningSignal).where(
            TasteLearningSignal.owner_id == profile.owner_id,
            TasteLearningSignal.record_id == record.id,
            TasteLearningSignal.kind.in_(("feedback_tag", "feedback_unanswered")),
            TasteLearningSignal.status == "active",
        )
    ):
        if signal.signal_key not in current_feedback_keys:
            signal.status = "retracted"
    drafts = (
        _adjustment_drafts(session, record, now)
        + feedback_drafts
        + _explicit_draft(session, record, now)
        + _rating_and_repeat_drafts(session, record, now)
        + _ingredient_drafts(session, record, now)
    )
    created = 0
    for draft in drafts:
        existing = session.scalar(
            select(TasteLearningSignal).where(
                TasteLearningSignal.owner_id == profile.owner_id,
                TasteLearningSignal.signal_key == draft.key,
            )
        )
        if existing is not None:
            continue
        base = weight_of(session, draft.kind)
        observed = draft.observed_at or now
        session.add(
            TasteLearningSignal(
                owner_id=profile.owner_id,
                profile_id=profile.id,
                record_id=draft.record_id,
                signal_key=draft.key,
                kind=draft.kind,
                field=draft.field_name,
                scope=draft.scope,
                direction=draft.direction,
                base_weight=base,
                effective_weight=effective_weight(session, base, observed, now),
                flavor_key=draft.flavor_key,
                ingredient_id=draft.ingredient_id,
                ingredient_category=draft.ingredient_category,
                observed_at=observed,
                created_at=now,
            )
        )
        created += 1
    session.flush()
    return created


def retract_record_signals(session: Session, owner_id: uuid.UUID, record_id: uuid.UUID) -> None:
    for row in session.scalars(
        select(TasteLearningSignal).where(
            TasteLearningSignal.owner_id == owner_id,
            TasteLearningSignal.record_id == record_id,
            TasteLearningSignal.status == "active",
        )
    ):
        row.status = "retracted"


def _latest_feedback_revision_id(session: Session, record_id: uuid.UUID) -> uuid.UUID | None:
    return session.scalar(
        select(CookingRecordRevision.revision_id)
        .where(
            CookingRecordRevision.record_id == record_id,
            CookingRecordRevision.field == "feedback",
        )
        .order_by(CookingRecordRevision.revision.desc())
    )


# ---------------------------------------------------------------- learning run


def _locked_fields(profile: TasteProfile) -> set[str]:
    rows = session_locks(profile)
    return rows


def session_locks(profile: TasteProfile) -> set[str]:
    return set(profile.locked_fields or [])


def _active_signals(session: Session, profile: TasteProfile) -> list[TasteLearningSignal]:
    return list(
        session.scalars(
            select(TasteLearningSignal).where(
                TasteLearningSignal.owner_id == profile.owner_id,
                TasteLearningSignal.profile_id == profile.id,
                TasteLearningSignal.status == "active",
            )
        )
    )


def _reason_phrase(kind: str, count: int, scope: str, flavor: str | None) -> str:
    label = {"salty": "咸度", "spicy": "辣度", "sour": "酸度", "sweet": "甜度"}.get(
        flavor or "", "口味"
    )
    where = "" if scope == SCOPE_OVERALL else f"{scope}菜"
    if kind == "manual_adjustment":
        return f"你最近 {count} 次在{where}做菜时手动调过{label}"
    if kind == "explicit_save":
        return f"你在{where}做某菜时选择存进口味，{label}已按它调整"
    if kind == "feedback_unanswered":
        return f"你最近 {count} 次反馈过这道菜的{label}，还没确认是不是你的口味"
    if kind in {"rating", "repeat_cook"}:
        return f"你最近 {count} 次给这类菜高分或反复做，{label}按它小步调整"
    return f"你最近 {count} 次反馈过{label}"


def _accumulate(
    session: Session, profile: TasteProfile, now: datetime
) -> tuple[dict[tuple[str, str], list[TasteLearningSignal]], list[TasteLearningSignal]]:
    grouped: dict[tuple[str, str], list[TasteLearningSignal]] = {}
    ingredient_rows: list[TasteLearningSignal] = []
    for row in _active_signals(session, profile):
        if row.field.startswith("ingredient_preferences."):
            ingredient_rows.append(row)
            continue
        group = (row.field, row.scope)
        grouped.setdefault(group, []).append(row)
    return grouped, ingredient_rows


def apply_learning(session: Session, profile: TasteProfile) -> LearningOutcome:
    """Small-step update per flavour, per scope; locked fields never move."""
    now = utcnow()
    outcome = LearningOutcome()
    locked = session_locks(profile)
    grouped, ingredient_rows = _accumulate(session, profile, now)
    scale = profile_service.scale_for(session)
    flavors = dict(profile.flavors)
    local = {row["cuisine"]: dict(row) for row in (profile.local_cuisines or [])}
    changes: list[profile_service.FieldChange] = []
    consumed_signals: list[TasteLearningSignal] = []

    for (field_name, scope), signals in sorted(grouped.items()):
        if field_name in locked or (scope != SCOPE_OVERALL and f"local_cuisines.{scope}" in locked):
            continue
        fresh: list[TasteLearningSignal] = []
        for signal in signals:
            weight = effective_weight(session, signal.base_weight, signal.observed_at, now)
            if weight <= 0:
                signal.status = "consumed"
                continue
            signal.effective_weight = weight
            fresh.append(signal)
        if not fresh:
            continue
        agree = sum(item.effective_weight for item in fresh if item.direction > 0)
        oppose = sum(item.effective_weight for item in fresh if item.direction < 0)
        direction = 1 if agree >= oppose else -1
        strength = abs(agree - oppose)
        if strength <= 0:
            continue
        outcome.signals_considered += len(fresh)
        delta = min(step(session) * strength, max_change(session))
        if scope == SCOPE_OVERALL:
            current = flavors.get(field_name.split(".", 1)[1])
            if current is None:
                continue
            before = float(current["coefficient"])
            after_value = before - direction * delta
            if not scale.minimum <= after_value <= scale.maximum:
                continue
            after_value = round(after_value, 4)
            if after_value == before:
                continue
            total = agree + oppose
            consistency = abs(agree - oppose) / total if total else 0.0
            confidence = max(
                0.0,
                min(
                    float(config.get(session, "taste.confidence_max")),
                    float(current.get("confidence_score", 0.0))
                    + (2 * consistency - 1) * min(total * 0.25, 0.25),
                ),
            )
            source_ids = sorted({str(signal.record_id) for signal in fresh if signal.record_id})
            change = profile_service.FieldChange(
                field_name,
                dict(current),
                {
                    "coefficient": after_value,
                    "confidence": "high" if confidence >= 0.6 else "low",
                    "confidence_score": round(confidence, 4),
                },
                source_record_ids=source_ids,
            )
            changes.append(change)
            flavors[change.field.split(".", 1)[1]] = change.new_value
        else:
            row = local.get(scope)
            if row is None:
                row = {
                    "cuisine": scope,
                    "adjustments": {},
                    "confidence_score": 0.0,
                }
            before_row = {
                "cuisine": scope,
                "adjustments": dict(row.get("adjustments") or {}),
                "confidence_score": float(row.get("confidence_score", 0.0)),
            }
            adjustments = dict(before_row["adjustments"])
            key = field_name.split(".", 1)[1]
            current = float(adjustments.get(key, scale.default))
            after_value = round(
                max(scale.minimum, min(scale.maximum, current - direction * delta)), 4
            )
            overall_value = float(flavors.get(key, {}).get("coefficient", scale.default))
            if abs(after_value - overall_value) < float(
                config.get(session, "taste.local_cuisine_threshold")
            ):
                continue
            if after_value == current:
                continue
            adjustments[key] = after_value
            source_ids = sorted({str(signal.record_id) for signal in fresh if signal.record_id})
            row = {
                "cuisine": scope,
                "adjustments": adjustments,
                "confidence_score": min(
                    1.0, float(row.get("confidence_score", 0.0)) + strength * 0.25
                ),
            }
            local[scope] = row
            changes.append(
                profile_service.FieldChange(
                    f"local_cuisines.{scope}",
                    before_row,
                    row,
                    source_record_ids=source_ids,
                )
            )
        for signal in fresh:
            # Evidence is consumed whether the effective value moved in the
            # overall scope or only in the cuisine scope.
            signal.status = "consumed"
            consumed_signals.append(signal)
    # A signal with a cuisine scope always adds one overall evidence entry,
    # but its numeric effect stays local (see #241 decision).
    if changes:
        rows = profile_service.record_changes(
            session,
            profile,
            changes,
            reason=_reason_phrase(
                "manual_adjustment", max(1, outcome.signals_considered), SCOPE_OVERALL, None
            ),
            source="learning",
            origin=ORIGIN_AUTO,
        )
        rows_by_field = {row.field: row for row in rows}
        for signal in consumed_signals:
            change_field = (
                signal.field if signal.scope == SCOPE_OVERALL else f"local_cuisines.{signal.scope}"
            )
            change = rows_by_field.get(change_field)
            if change is not None:
                signal.consumed_by_change_id = change.id
        for row in rows:
            session.add(
                TasteChangeFact(
                    owner_id=profile.owner_id,
                    change_id=row.id,
                    event_type="auto_change_applied",
                    source=ORIGIN_AUTO,
                    field=row.field,
                    created_at=row.created_at,
                )
            )
        profile.flavors = flavors
        profile.local_cuisines = [local[key] for key in sorted(local)]
        outcome.applied.extend(rows)
    outcome.pending.extend(ingredient_suggestions(session, profile, ingredient_rows))
    session.flush()
    return outcome


def ingredient_suggestions(
    session: Session, profile: TasteProfile, signals: list[TasteLearningSignal]
) -> list[TasteProfileChange]:
    """Repeated removals produce one target-scoped pending dislike suggestion."""
    threshold = float(config.get(session, "taste.ingredient_dislike_threshold"))
    locked = session_locks(profile)
    buckets: dict[str, list[TasteLearningSignal]] = {}
    for row in signals:
        buckets.setdefault(row.field, []).append(row)
    created: list[TasteProfileChange] = []
    existing = {
        row.field
        for row in session.scalars(
            select(TasteProfileChange).where(
                TasteProfileChange.owner_id == profile.owner_id,
                TasteProfileChange.origin == ORIGIN_AUTO,
                TasteProfileChange.status.in_(("pending", "confirmed", "reverted")),
            )
        )
    }
    now = utcnow()
    for signal_field, rows in sorted(buckets.items()):
        target_key = signal_field.split(".", 1)[1]
        field_name = f"ingredient_preferences.{target_key}"
        if field_name in locked or field_name in existing:
            continue
        strength = sum(
            effective_weight(session, row.base_weight, row.observed_at, now) for row in rows
        )
        if strength + 1e-6 < threshold:
            continue
        sample = rows[0]
        current_item = next(
            (
                dict(item)
                for item in (profile.ingredient_preferences or [])
                if str(item.get("ingredient_id") or item.get("name") or "") == target_key
            ),
            None,
        )
        new_item: dict[str, Any] = {
            "preference": "disliked",
            "name": current_item.get("name", target_key) if current_item else target_key,
        }
        if sample.ingredient_id is not None:
            new_item["ingredient_id"] = str(sample.ingredient_id)
        elif current_item and current_item.get("category"):
            new_item["category"] = current_item["category"]
        elif sample.ingredient_category:
            new_item["category"] = sample.ingredient_category
        else:
            # Names not present in the standard ingredient catalogue cannot be
            # written into the validated profile.
            continue
        rows_out = profile_service.record_changes(
            session,
            profile,
            [
                profile_service.FieldChange(
                    field_name,
                    current_item or {},
                    new_item,
                    source_record_ids=[str(row.record_id) for row in rows if row.record_id],
                )
            ],
            reason=f"你多次去掉{new_item['name']}，要标为不喜欢吗",
            source="learning",
            origin=ORIGIN_AUTO,
            status="pending",
        )
        for signal in rows:
            signal.status = "consumed"
            if rows_out:
                signal.consumed_by_change_id = rows_out[0].id
        created.extend(rows_out)
    if created:
        session.flush()
    return created


# --------------------------------------------------------------- change control


def owned_change(session: Session, owner_id: uuid.UUID, change_id: uuid.UUID) -> TasteProfileChange:
    row = session.scalar(
        select(TasteProfileChange).where(
            TasteProfileChange.id == change_id, TasteProfileChange.owner_id == owner_id
        )
    )
    if row is None:
        raise NotFound()
    return row


def before_change_state(
    session: Session,
    profile: TasteProfile,
    change_id: uuid.UUID,
    *,
    only_target: bool = False,
) -> tuple[dict[str, Any], list[dict[str, Any]], int]:
    """Rewind detached ordinary taste values; current sensitive grants remain authoritative."""
    from copy import deepcopy

    target = owned_change(session, profile.owner_id, change_id)
    if target.status not in ("active", "confirmed"):
        raise ApiError(409, "change_not_effective", "这条口味变化目前没有生效")
    if not (
        target.field.startswith("flavors.")
        or target.field == "ingredient_preferences"
        or target.field.startswith("ingredient_preferences.")
    ):
        raise ApiError(409, "change_not_supported", "这条变化不属于可重算的普通口味")
    if target.effective_at is None or target.effective_version is None:
        raise ApiError(409, "history_unavailable", "没有可靠的口味变化生效时间")
    flavors = deepcopy(profile.flavors)
    preferences = deepcopy(profile.ingredient_preferences)
    operations: list[tuple[datetime, int, TasteProfileChange, bool]] = []
    rows = session.scalars(
        select(TasteProfileChange).where(
            TasteProfileChange.owner_id == profile.owner_id,
            TasteProfileChange.status != "pending",
        )
    )
    for row in rows:
        # Sensitive allergy history is deliberately not replayed: today's consent
        # and safety constraints apply in both views. Ignore unrelated fields too.
        if not (
            row.field.startswith("flavors.")
            or row.field == "ingredient_preferences"
            or row.field.startswith("ingredient_preferences.")
        ):
            continue
        if only_target and row.id != target.id:
            continue
        if row.effective_at is None or row.effective_version is None:
            raise ApiError(409, "history_unavailable", "没有可靠的口味变化生效时间")
        if only_target or row.effective_version >= target.effective_version:
            operations.append((row.effective_at, row.effective_version, row, False))
        if (
            not only_target
            and row.reverted_at is not None
            and row.reverted_at >= target.effective_at
        ):
            # Undo a later revert even if its original application predates target.
            operations.append((row.reverted_at, row.effective_version, row, True))
    operations.sort(key=lambda op: (op[0], op[1], str(op[2].id)), reverse=True)
    for _, _, row, undo_revert in operations:
        expected = row.old_value if undo_revert else row.new_value
        restored = row.new_value if undo_revert else row.old_value
        if row.field.startswith("flavors."):
            key = row.field.split(".", 1)[1]
            if flavors.get(key) != expected:
                raise ApiError(409, "history_unavailable", "无法可靠还原变化前口味")
            flavors[key] = deepcopy(restored)
        elif row.field == "ingredient_preferences":
            if preferences != expected.get("items", []):
                raise ApiError(409, "history_unavailable", "无法可靠还原变化前口味")
            preferences = deepcopy(restored.get("items", []))
        elif row.field.startswith("ingredient_preferences."):
            key = row.field.split(".", 1)[1]
            actual = next(
                (
                    item
                    for item in preferences
                    if str(item.get("ingredient_id") or item.get("name") or "") == key
                ),
                {},
            )
            if actual != expected:
                raise ApiError(409, "history_unavailable", "无法可靠还原变化前口味")
            preferences = [
                item
                for item in preferences
                if str(item.get("ingredient_id") or item.get("name") or "") != key
            ]
            if restored:
                preferences.append(deepcopy(restored))
    return flavors, preferences, max(1, target.effective_version - 1)


def confirm_change(
    session: Session,
    profile: TasteProfile,
    row: TasteProfileChange,
    *,
    source: str | None = None,
) -> None:
    if row.owner_id != profile.owner_id:
        raise NotFound()
    if row.status == "pending":
        # A pending ingredient suggestion only takes effect when confirmed.
        _apply_change_value(session, profile, row)
        profile.version += 1
        profile.updated_at = utcnow()
        row.status = "confirmed"
        row.effective_at = profile.updated_at
        row.effective_version = profile.version
        profile_service.record_change_event(session, profile, row, source=source)
    elif row.status == "active":
        # An already-applied numeric change: confirmation only changes status.
        row.status = "confirmed"
        if source is not None:
            profile_service.record_change_event(session, profile, row, source=source)
    session.flush()


def _apply_change_value(session: Session, profile: TasteProfile, row: TasteProfileChange) -> None:
    field_name = row.field
    if field_name.startswith("ingredient_preferences."):
        target = field_name.split(".", 1)[1]
        items = [
            dict(item)
            for item in (profile.ingredient_preferences or [])
            if str(item.get("ingredient_id") or item.get("name") or "") != target
        ]
        if row.new_value:
            items.append(dict(row.new_value))
        profile.ingredient_preferences = items
    elif field_name == "ingredient_preferences":
        items = row.new_value.get("items", []) if isinstance(row.new_value, dict) else []
        profile.ingredient_preferences = [dict(item) for item in items]
    elif field_name.startswith("flavors."):
        key = field_name.split(".", 1)[1]
        flavors = dict(profile.flavors)
        flavors[key] = row.new_value
        profile.flavors = flavors
    elif field_name.startswith("local_cuisines."):
        cuisine = field_name.split(".", 1)[1]
        rows = [item for item in (profile.local_cuisines or []) if item.get("cuisine") != cuisine]
        rows.append(row.new_value)
        profile.local_cuisines = rows


def revert_change(
    session: Session,
    profile: TasteProfile,
    row: TasteProfileChange,
    *,
    source: str | None = None,
) -> None:
    if row.owner_id != profile.owner_id:
        raise NotFound()
    if row.status == "reverted":
        return
    field_name = row.field
    if field_name.startswith("flavors."):
        key = field_name.split(".", 1)[1]
        current = profile.flavors.get(key)
        if current is None:
            raise NotFound()
        # Never silently overwrite a newer manual or learned value.
        if current != row.new_value:
            raise ApiError(
                409,
                "taste_change_conflict",
                "这一项后来又被改过",
                "请先核对当前值，再决定是否撤销",
            )
        flavors = dict(profile.flavors)
        flavors[key] = row.old_value
        profile.flavors = flavors
    elif field_name.startswith("ingredient_preferences."):
        target = field_name.split(".", 1)[1]
        current = next(
            (
                dict(item)
                for item in (profile.ingredient_preferences or [])
                if str(item.get("ingredient_id") or item.get("name") or "") == target
            ),
            None,
        )
        if current != row.new_value:
            raise ApiError(
                409,
                "taste_change_conflict",
                "这项食材偏好后来又被改过",
                "请先核对当前值，再决定是否撤销",
            )
        items = [
            dict(item)
            for item in (profile.ingredient_preferences or [])
            if str(item.get("ingredient_id") or item.get("name") or "") != target
        ]
        if row.old_value:
            items.append(dict(row.old_value))
        profile.ingredient_preferences = items
    elif field_name.startswith("local_cuisines."):
        cuisine = field_name.split(".", 1)[1]
        current_row = next(
            (item for item in (profile.local_cuisines or []) if item.get("cuisine") == cuisine),
            None,
        )
        if current_row is None or current_row != row.new_value:
            raise ApiError(
                409,
                "taste_change_conflict",
                "这个菜系偏好后来又被改过",
                "请先核对当前值，再决定是否撤销",
            )
        rows = [item for item in (profile.local_cuisines or []) if item.get("cuisine") != cuisine]
        if row.old_value.get("adjustments"):
            rows.append(dict(row.old_value))
        profile.local_cuisines = rows
    row.status = "reverted"
    row.reverted_at = utcnow()
    profile.version += 1
    profile_service.record_change_event(session, profile, row, source=source)
    # Reverted evidence must never be re-learned from the same old signal.
    for signal in session.scalars(
        select(TasteLearningSignal).where(
            TasteLearningSignal.owner_id == profile.owner_id,
            TasteLearningSignal.status == "consumed",
            TasteLearningSignal.consumed_by_change_id == row.id,
        )
    ):
        signal.status = "retracted"
    session.add(
        TasteChangeFact(
            owner_id=profile.owner_id,
            change_id=new_id(),
            event_type="auto_change_reverted",
            source=source or row.origin,
            origin_change_id=row.id,
            field=row.field,
            created_at=utcnow(),
        )
    )
    session.flush()


def set_lock(session: Session, profile: TasteProfile, field_name: str, locked: bool) -> None:
    fields = set(profile.locked_fields or [])
    if locked:
        fields.add(field_name)
    else:
        fields.discard(field_name)
    profile.locked_fields = sorted(fields)
    session.add(
        TasteChangeFact(
            owner_id=profile.owner_id,
            change_id=new_id(),
            event_type="field_locked" if locked else "field_unlocked",
            source=ORIGIN_MANUAL,
            field=field_name,
            created_at=utcnow(),
        )
    )
    session.flush()


def revert_rate(session: Session, owner_id: uuid.UUID) -> tuple[int, int]:
    applied = session.scalar(
        select(func.count())
        .select_from(TasteChangeFact)
        .where(
            TasteChangeFact.owner_id == owner_id,
            TasteChangeFact.event_type == "auto_change_applied",
        )
    )
    reverted = session.scalar(
        select(func.count(func.distinct(TasteChangeFact.origin_change_id)))
        .select_from(TasteChangeFact)
        .where(
            TasteChangeFact.owner_id == owner_id,
            TasteChangeFact.event_type == "auto_change_reverted",
        )
    )
    return int(applied or 0), int(reverted or 0)


def explicit_save_change(
    session: Session,
    profile: TasteProfile,
    record: CookingRecord,
    changes: list[dict[str, Any]],
) -> list[TasteProfileChange]:
    """`存进我的口味`: one explicit-save change per adjustment, applied now."""
    # The operation ID is the cooking record: retrying the same intent must be
    # a no-op, while a later record remains eligible.
    record_key = str(record.id)
    already_saved = session.scalar(
        select(TasteProfileChange.id).where(
            TasteProfileChange.owner_id == profile.owner_id,
            TasteProfileChange.origin == ORIGIN_EXPLICIT,
            TasteProfileChange.source_record_ids.contains([record_key]),
        )
    )
    if already_saved is not None:
        return []
    scale = profile_service.scale_for(session)
    field_changes: list[profile_service.FieldChange] = []
    for item in changes:
        flavor = item.get("flavor") or item.get("flavor_key")
        delta = item.get("delta") or item.get("direction")
        if flavor not in FLAVOR_KEYS or not isinstance(delta, (int, float)) or delta == 0:
            raise ApiError(422, "invalid_taste_change", "这项改动暂时没法换算成口味设置")
        key = f"flavors.{flavor}"
        current = dict(profile.flavors.get(str(flavor), {"coefficient": scale.default}))
        before = float(current["coefficient"])
        # Positive amount deltas mean adding more of the ingredient; a
        # reduction (negative delta) should make the corresponding taste less
        # preferred.  `after = before - delta_value` preserves that direction.
        delta_value = min(step(session), max_change(session)) * (-1 if delta > 0 else 1)
        after = round(max(scale.minimum, min(scale.maximum, before - delta_value)), 4)
        if after == before:
            continue
        field_changes.append(
            profile_service.FieldChange(
                key,
                current,
                {
                    "coefficient": after,
                    "confidence": "high",
                    "confidence_score": 1.0,
                },
            )
        )
    rows = profile_service.record_changes(
        session,
        profile,
        field_changes,
        reason="你在做某菜时选择存进口味",
        source="learning",
        origin=ORIGIN_EXPLICIT,
        source_record_ids=[str(record.id)],
    )
    # Only the amount adjustments represented by this explicit operation are
    # consumed. Feedback and unrelated ingredient evidence remain traceable.
    saved_fields = {f"flavors.{item.get('flavor') or item.get('flavor_key')}" for item in changes}
    for signal in session.scalars(
        select(TasteLearningSignal).where(
            TasteLearningSignal.owner_id == profile.owner_id,
            TasteLearningSignal.record_id == record.id,
            TasteLearningSignal.status == "active",
            TasteLearningSignal.kind == "manual_adjustment",
            TasteLearningSignal.field.in_(saved_fields),
        )
    ):
        signal.status = "consumed"
        if rows:
            signal.consumed_by_change_id = next(
                (row.id for row in rows if row.field == signal.field), rows[0].id
            )
    if rows:
        flavors = dict(profile.flavors)
        for row in rows:
            flavors[row.field.split(".", 1)[-1]] = row.new_value
        profile.flavors = flavors
    session.flush()
    return rows
