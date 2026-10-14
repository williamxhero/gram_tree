"""Owner-scoped scenario decisions; no recipe, record or taste snapshot is mutated."""

from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime
from typing import Any, Literal, cast
from zoneinfo import ZoneInfo

from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.time import utcnow
from gramtree.events import service as events
from gramtree.events.models import Event
from gramtree.recipes.models import RecipeVersion
from gramtree.records.models import CookingRecord
from gramtree.runtime_config import service as config
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
    versions = select(RecipeVersion.id).where(RecipeVersion.recipe_id == recipe_id)
    return list(
        session.scalars(
            select(CookingRecord)
            .where(
                CookingRecord.owner_id == user.id,
                CookingRecord.counts_as_cooked.is_(True),
                (CookingRecord.recipe_id == recipe_id)
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
