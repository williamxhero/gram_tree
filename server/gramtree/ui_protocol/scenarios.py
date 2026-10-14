"""Owner-scoped scenario decisions; no recipe, record or taste snapshot is mutated."""

from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime, timedelta
from typing import Any, Literal, cast
from zoneinfo import ZoneInfo

from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError
from gramtree.core.time import utcnow
from gramtree.events import service as events
from gramtree.events.models import Event
from gramtree.recipes.models import Recipe, RecipeVersion
from gramtree.recipes.schemas import PersonalizationRequest, RecipeSnapshot
from gramtree.records.models import CookingRecord, CookingRecordRevision
from gramtree.runtime_config import service as config
from gramtree.settings import Settings
from gramtree.taste_profiles.models import TasteProfileChange
from gramtree.ui_protocol.protocol import (
    ActionDescriptor,
    ComponentDescriptor,
    ComponentReason,
    DetailLevel,
)

Preference = Literal["auto", "brief", "detailed"]


def digest(value: object) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, default=str).encode()).hexdigest()[:20]


def preference(session: Session, owner_id: uuid.UUID) -> Preference:
    row = session.scalar(
        select(Event)
        .where(Event.user_id == owner_id, Event.event_type == "ui.detail_preference")
        .order_by(Event.received_at.desc(), Event.id.desc())
        .limit(1)
    )
    value = row.content.get("detail") if row else "auto"
    return cast(Preference, value) if value in ("auto", "brief", "detailed") else "auto"


def record_event(
    session: Session, redis: Redis, owner_id: uuid.UUID, event_type: str, content: dict[str, Any]
) -> None:
    now = utcnow()
    events.upload(
        session,
        redis,
        owner_id,
        [
            events.EventInput(
                id=uuid.uuid4(),
                event_type=event_type,
                type_version=1,
                device_id="server",
                app_version="server",
                device_time=now,
                correlation={},
                content=content,
            )
        ],
        now=now,
    )


def session_completed(row: CookingRecord) -> bool:
    # A partially executed session is not evidence of a completed cook. Missing
    # historical execution data must not be filled from the current recipe.
    snapshot = row.snapshot or {}
    detail = snapshot.get("detail")
    if not isinstance(detail, dict):
        return False
    version = detail.get("version")
    if not isinstance(version, dict):
        return False
    execution = version.get("snapshot")
    if not isinstance(execution, dict):
        return False
    steps = execution.get("steps")
    if not isinstance(steps, list) or not steps:
        return False
    step_ids = [step.get("id") if isinstance(step, dict) else None for step in steps]
    if not all(isinstance(step_id, str) and step_id for step_id in step_ids):
        return False
    ids = set(step_ids)
    completed = row.source_context.get("completed_steps", [])
    skipped = row.source_context.get("skipped_steps", [])
    if not isinstance(completed, list) or not isinstance(skipped, list):
        return False
    return (
        len(ids) == len(steps)
        and all(isinstance(step_id, str) and step_id for step_id in ids)
        and all(isinstance(step_id, str) for step_id in completed + skipped)
        and ids.issubset(set(completed + skipped))
    )


def calendar_signal(user: User, now: datetime) -> dict[str, Any]:
    local = now.astimezone(ZoneInfo(user.timezone))
    return {
        "value": "weekend" if local.weekday() >= 5 else "weekday",
        "period": "morning" if local.hour < 12 else "afternoon" if local.hour < 18 else "evening",
        "source": {"timezone": user.timezone, "local_date": local.date().isoformat()},
        "rule_entry": "weekend_leisure" if local.weekday() >= 5 else "weekday_quick",
    }


def records_for(session: Session, user: User, recipe_id: uuid.UUID) -> list[CookingRecord]:
    recipe = session.get(Recipe, recipe_id)
    if recipe is None or recipe.owner_id != user.id:
        raise ApiError(404, "not_found", "没有这份菜谱")
    recipes = select(Recipe.id).where(Recipe.dish_id == recipe.dish_id)
    versions = select(RecipeVersion.id).where(RecipeVersion.recipe_id.in_(recipes))
    return list(
        session.scalars(
            select(CookingRecord)
            .where(
                CookingRecord.owner_id == user.id,
                CookingRecord.counts_as_cooked.is_(True),
                CookingRecord.recipe_id.in_(recipes)
                | CookingRecord.recipe_version_id.in_(versions),
            )
            .order_by(CookingRecord.occurred_at.desc(), CookingRecord.id.desc())
        )
    )


def summary(
    session: Session,
    user: User,
    recipe_id: uuid.UUID,
    *,
    screen_width: int,
    override: DetailLevel | None,
) -> tuple[ComponentDescriptor, dict[str, Any], list[CookingRecord]]:
    rows = records_for(session, user, recipe_id)
    # Completion is a recorded cooking-session fact, not a rating or a dining entry.
    completed = list(
        session.scalars(
            select(CookingRecord).where(
                CookingRecord.owner_id == user.id,
                CookingRecord.source == "cooking_session",
                CookingRecord.counts_as_cooked.is_(True),
            )
        )
    )
    completed = [row for row in completed if session_completed(row)]
    experience_count = len(completed)
    experienced = experience_count >= int(config.get(session, "ui.scenario.experienced_count"))
    frequent = len(rows) >= int(config.get(session, "ui.scenario.frequent_count"))
    pref = preference(session, user.id)
    detail: DetailLevel = override or (
        pref if pref != "auto" else "brief" if experienced else "detailed"
    )
    code = (
        "page_switch"
        if override
        else "user_setting"
        if pref != "auto"
        else "experienced"
        if experienced
        else "novice"
    )
    text = {
        "page_switch": "页面切换，只影响当前查看。",
        "user_setting": "使用你在设置中固定的默认详略。",
        "experienced": "你已多次完成做菜，先显示紧凑清单。",
        "novice": "展开成熟判断与原理，帮助第一次或较少做菜时确认每一步。",
    }[code]
    # Full steps stay available until an actual execution-difference card is
    # supplied; frequency alone is not a reason to hide recipe content.
    collapsed = False
    signals = {
        "experience": {
            "value": "experienced" if experienced else "novice",
            "count": experience_count,
            "source": [str(row.id) for row in completed],
        },
        "calendar": calendar_signal(user, utcnow()),
        "dish_history": {
            "value": "frequent" if frequent else "cooked" if rows else "first_time",
            "count": len(rows),
            "source": [str(row.id) for row in rows],
        },
        "device": {
            "value": "tablet" if screen_width >= 600 else "phone",
            "source": "viewport_width",
        },
        "detail": {"value": detail, "source": code},
    }
    component = ComponentDescriptor(
        type="scenario_summary",
        id=f"scene:detail:{recipe_id}",
        detail=detail,
        reason=ComponentReason(code=code, text=text),
        actions=[
            ActionDescriptor(intent="set_scenario_detail", params={"detail": value})
            for value in ("brief", "detailed", "auto")
        ],
        data={
            "conclusion": "详细步骤" if detail == "detailed" else "紧凑清单",
            "steps_collapsed": collapsed,
            "layout": signals["device"]["value"],
            "source": {
                "source_type": "scenario_adjusted",
                "value": text,
                "basis": {
                    "reason_code": code,
                    "text": text,
                    "citation": "做菜记录、你的默认设置及本次页面选择",
                },
            },
        },
    )
    return component, signals, rows


def source(text: str, code: str, citation: str) -> dict[str, Any]:
    return {
        "source_type": "scenario_adjusted",
        "value": text,
        "basis": {"reason_code": code, "text": text, "citation": citation},
    }


def notice(
    kind: str, component_id: str, data: dict[str, Any], code: str, citation: str
) -> ComponentDescriptor:
    text = data["conclusion"]
    return ComponentDescriptor(
        type=kind,
        id=component_id,
        detail="standard",
        data={**data, "source": source(text, code, citation)},
        reason=ComponentReason(code=code, text=text),
        actions=[
            ActionDescriptor(
                intent=intent,
                params={"component_id": component_id, "source_type": "scenario_adjusted"},
            )
            for intent in ("skip_this_time", "dont_do_again")
        ],
    )


def feedback_scope(session: Session, user: User, component_id: str) -> tuple[str, ...]:
    """Resolve trusted ownership and stable dish/rule scope, never caller-supplied IDs."""
    parts = component_id.split(":")
    try:
        if len(parts) == 3 and parts[:2] == ["scene", "taste"]:
            from gramtree.taste_profiles.learning import owned_change

            row = owned_change(session, user.id, uuid.UUID(parts[2]))
            return ("taste", str(row.id))
        if (len(parts) == 3 and parts[:2] == ["scene", "difference"]) or (
            len(parts) == 6
            and parts[:2] == ["scene", "failure"]
            and parts[3] in FAILURE_RULES
            and parts[5] in ("before", "at")
        ):
            recipe = session.get(Recipe, uuid.UUID(parts[2]))
            if recipe is not None and recipe.owner_id == user.id:
                if parts[1] == "difference":
                    return ("difference", str(recipe.dish_id))
                return ("failure", str(recipe.dish_id), parts[3])
    except (ValueError, TypeError):
        pass
    raise ApiError(404, "unknown_component", "没有这个场景组件")


def suppressed(session: Session, user: User, component_id: str) -> bool:
    scope = feedback_scope(session, user, component_id)
    rows = session.scalars(
        select(Event).where(Event.user_id == user.id, Event.event_type == "ui.source_feedback")
    )
    for row in rows:
        if row.content.get("feedback") != "never_again":
            continue
        try:
            if feedback_scope(session, user, str(row.content.get("component_id", ""))) == scope:
                return True
        except ApiError:
            continue
    return False


def execution_snapshot(row: CookingRecord) -> RecipeSnapshot | None:
    # detail.version.snapshot is the actual execution projection frozen when cooking
    # starts. render can contain author-based serving conversion: do not prefer it.
    try:
        return RecipeSnapshot.model_validate((row.snapshot or {})["detail"]["version"]["snapshot"])
    except (ValueError, KeyError, TypeError):
        return None


def differences(before: RecipeSnapshot, after: RecipeSnapshot) -> list[dict[str, str]]:
    result: list[dict[str, str]] = []
    previous = {item.id: item for item in before.ingredients}
    current = {item.id: item for item in after.ingredients}
    for item_id in dict.fromkeys([*previous, *current]):
        old, new = previous.get(item_id), current.get(item_id)
        label = new.display_name if new else old.display_name if old else item_id
        if old is None or new is None:
            result.append(
                {
                    "kind": "ingredient",
                    "ingredient_id": item_id,
                    "label": label,
                    "before": old.display_name if old else "无",
                    "after": new.display_name if new else "无",
                }
            )
            continue
        if old.quantity != new.quantity or old.unit != new.unit:
            result.append(
                {
                    "kind": "quantity",
                    "ingredient_id": item_id,
                    "label": label,
                    "before": f"{old.quantity:g} {old.unit}",
                    "after": f"{new.quantity:g} {new.unit}",
                }
            )
        if old.display_name != new.display_name:
            result.append(
                {
                    "kind": "ingredient",
                    "ingredient_id": item_id,
                    "label": label,
                    "before": old.display_name,
                    "after": new.display_name,
                }
            )
    # This card compares conversion values (servings, amounts, substitutions),
    # not arbitrary author edits or structural recipe-version changes.
    if before.servings != after.servings:
        result.append(
            {
                "kind": "servings",
                "label": "份数",
                "before": str(before.servings),
                "after": str(after.servings),
            }
        )
    return result


def difference_card(
    recipe_id: uuid.UUID, rows: list[CookingRecord], current: RecipeSnapshot
) -> ComponentDescriptor | None:
    if not rows:
        return None
    row = rows[0]
    previous = execution_snapshot(row)
    if previous is None:
        return None  # Missing evidence is not "unchanged"; keep all steps expanded.
    changes = differences(previous, current)
    date = row.occurred_at.date().isoformat()
    return notice(
        "scenario_difference",
        f"scene:difference:{recipe_id}",
        {
            "conclusion": "与上次做的换算不同" if changes else "与上次做的换算用量相同",
            "record_id": str(row.id),
            "record_date": date,
            "differences": changes,
        },
        "last_execution",
        f"{date} 做菜记录 {row.id} 的不可变执行快照",
    )


# Deliberately small, reviewable mapping table. No lexical/AI guess at a step.
FAILURE_RULES = {
    "dry_meat": (
        {"肉柴", "肉太干", "肉炒干了", "炒干了", "太干", "dry_meat"},
        None,
        "留意肉的成熟状态，熟后及时离火；不要为追求上色继续加热。",
    ),
    "too_salty": (
        {"偏咸", "太咸", "salty"},
        "salty",
        "分次加入咸味调料，确认味道后再决定是否加完。",
    ),
    "too_spicy": ({"太辣", "偏辣", "spicy"}, "spicy", "辣味调料先少放，确认能接受后再补。"),
    "too_oily": ({"太油", "太腻", "oily"}, "oily", "留意用油量，不要在原用量之外继续补油。"),
}
HEATING_ACTIONS = {"炒", "煎", "炸", "烤", "煮", "炖", "蒸", "焖"}
MEAT_NAMES = {"猪肉", "牛肉", "羊肉", "鸡肉", "鸡腿肉", "鸡胸肉", "肉片", "肉丝", "排骨"}


def failure_cards(
    session: Session, recipe_id: uuid.UUID, rows: list[CookingRecord], current: RecipeSnapshot
) -> list[ComponentDescriptor]:
    cards: list[ComponentDescriptor] = []
    seen: set[str] = set()
    # A successful latest cook supersedes earlier negative evidence.
    for row in rows[:1]:
        revisions = list(
            session.scalars(
                select(CookingRecordRevision)
                .where(
                    CookingRecordRevision.record_id == row.id,
                    CookingRecordRevision.owner_id == row.owner_id,
                )
                .order_by(CookingRecordRevision.revision)
            )
        )
        effective: dict[str, dict[str, Any]] = {}
        for revision in revisions:
            effective[revision.field] = revision.value or {}
        tags: set[str] = set()
        for field in ("feedback", "tags"):
            value = effective.get(field, {})
            if not value.get("deleted"):
                raw = value.get("taste_tags", value.get("tags", []))
                if isinstance(raw, list):
                    tags.update(str(tag) for tag in raw)
        adjustment_revision = effective.get("adjustments")
        adjustments = (
            adjustment_revision.get("adjustments", [])
            if adjustment_revision is not None
            else row.adjustments
        )
        if adjustment_revision and adjustment_revision.get("deleted"):
            adjustments = []
        if isinstance(adjustments, list):
            for adjustment in adjustments:
                if not isinstance(adjustment, dict):
                    continue
                flavor_key = adjustment.get("flavor", adjustment.get("flavor_key"))
                delta = adjustment.get("delta", adjustment.get("direction"))
                # Explicit reductions of a named flavor are observable live-cook
                # evidence, not inference from generic quantity/serving edits.
                if isinstance(delta, (int, float)) and not isinstance(delta, bool) and delta < 0:
                    label = {"salty": "偏咸", "spicy": "太辣", "oily": "太腻"}.get(str(flavor_key))
                    if label:
                        tags.add(label)
        previous = execution_snapshot(row)
        if previous is None:
            continue
        for rule_id, (labels, flavor, advice) in FAILURE_RULES.items():
            matched = tags.intersection(labels)
            if rule_id in seen or not matched:
                continue
            seen.add(rule_id)

            def targets(snapshot: RecipeSnapshot, flavor: str | None = flavor) -> list[str]:
                ingredient_ids = {
                    item.id
                    for item in snapshot.ingredients
                    if (
                        item.display_name in MEAT_NAMES
                        if flavor is None
                        else bool(getattr(item.flavor_contribution, flavor, None))
                    )
                }
                return [
                    step.id
                    for step in snapshot.steps
                    if ingredient_ids.intersection(step.ingredient_ids)
                    and (step.action in HEATING_ACTIONS if flavor is None else True)
                ]

            historical, candidates = targets(previous), targets(current)
            if len(historical) != 1 or candidates != historical:
                continue  # Ambiguous or changed step identity: do not invent confidence.
            date = row.occurred_at.date().isoformat()
            for placement in ("before", "at"):
                component_id = f"scene:failure:{recipe_id}:{rule_id}:{candidates[0]}:{placement}"
                cards.append(
                    notice(
                        "failure_reminder",
                        component_id,
                        {
                            "conclusion": "留意上次遇到的问题",
                            "problem": sorted(matched)[0],
                            "advice": advice,
                            "rule_id": rule_id,
                            "record_id": str(row.id),
                            "record_date": date,
                            "step_id": candidates[0],
                            "placement": placement,
                        },
                        rule_id,
                        f"{date} 做菜记录 {row.id} 的最新反馈及临场改动",
                    )
                )
    return cards


def taste_cards(
    session: Session,
    settings: Settings,
    redis: Redis,
    user: User,
    recipe_id: uuid.UUID,
    inputs: PersonalizationRequest,
    current: RecipeSnapshot,
    *,
    before_change_id: uuid.UUID | None,
    view: Literal["personalized", "original"] = "personalized",
) -> list[ComponentDescriptor]:
    from gramtree.recipes import service as recipes
    from gramtree.taste_profiles import service as taste_service

    if before_change_id is not None or view == "original":
        return []
    profile = taste_service.locked_profile(session, user.id, taste_service.scale_for(session))
    cutoff = utcnow() - timedelta(days=int(config.get(session, "ui.scenario.taste_recent_days")))
    rows = session.scalars(
        select(TasteProfileChange)
        .where(
            TasteProfileChange.owner_id == user.id,
            TasteProfileChange.status.in_(("active", "confirmed")),
            TasteProfileChange.effective_at >= cutoff,
        )
        .order_by(
            TasteProfileChange.effective_version.desc(),
            TasteProfileChange.effective_at.desc(),
            TasteProfileChange.id.desc(),
        )
    )
    result: list[ComponentDescriptor] = []
    seen: set[str] = set()
    for row in rows:
        if row.field in seen:
            continue
        seen.add(row.field)
        # A recent but superseded change is not a currently effective source.
        if row.field.startswith("flavors."):
            if profile.flavors.get(row.field.split(".", 1)[1]) != row.new_value:
                continue
            flavor = row.field.split(".", 1)[1]
            if not any(
                getattr(item.flavor_contribution, flavor, None) for item in current.ingredients
            ):
                continue
        elif not row.field.startswith("ingredient_preferences"):
            continue
        try:
            before = recipes.personalize_recipe(
                session,
                settings,
                user,
                recipe_id,
                inputs,
                redis=redis,
                before_change_id=row.id,
                compare_change_only=True,
            )
        except ApiError as exc:
            if exc.status == 409:
                continue  # Unreconstructable history is not evidence of influence.
            raise
        if not differences(before.snapshot, current):
            continue
        if row.effective_at is None:
            continue
        date = row.effective_at.date().isoformat()
        card = notice(
            "taste_change_notice",
            f"scene:taste:{row.id}",
            {
                "conclusion": "最近的口味变化影响了这道菜的换算",
                "change_id": str(row.id),
                "change_date": date,
            },
            "recent_taste_change",
            f"{date} 口味变化 {row.id}：{row.reason}",
        )
        card.actions.extend(
            ActionDescriptor(intent=intent, params={"change_id": str(row.id)})
            for intent in ("show_before_taste_change", "open_taste_change")
        )
        result.append(card)
    return result
