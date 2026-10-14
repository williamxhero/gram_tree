"""Private transient constraints; only equipment step rewrites enter Redis."""

import hashlib
import json
import uuid
from dataclasses import replace
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Literal, cast

from pydantic import BaseModel, ConfigDict, Field
from redis import Redis
from redis.exceptions import RedisError
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.ai import gateway
from gramtree.core.errors import ApiError
from gramtree.ingredients.models import Ingredient
from gramtree.recipes import personal_safety
from gramtree.recipes.schemas import RecipeReplacement, RecipeSnapshot, RecipeStep
from gramtree.runtime_config import service as config
from gramtree.settings import Settings
from gramtree.taste_profiles.authorized_constraints import AuthorizedConstraints

# Deliberately small and reviewable. Allergy safety is established from the
# standard library and every selected person's constraints, never this table.
COMMON_REPLACEMENTS = {"香菜": "小葱"}


def select_diners(
    constraints: AuthorizedConstraints, ids: list[uuid.UUID]
) -> AuthorizedConstraints:
    selected = {str(value) for value in ids}
    if not selected <= {member.id for member in constraints.family}:
        raise ApiError(422, "invalid_diners", "同吃成员不存在或未获得授权，请重新选择")
    return replace(constraints, family=tuple(m for m in constraints.family if m.id in selected))


def diner_flavors(
    owner: dict[str, float], constraints: AuthorizedConstraints, primary: uuid.UUID | None
) -> dict[str, float]:
    if primary is not None:
        member = next(m for m in constraints.family if m.id == str(primary))
        return {key: float((member.flavors or {}).get(key, 1)) for key in owner}
    values = [owner, *(member.flavors or {} for member in constraints.family)]
    return {
        key: (min if key in {"spicy", "numbing"} else lambda v: sum(v) / len(v))(
            [float(value.get(key, 1)) for value in values]
        )
        for key in owner
    }


def substitute(
    session: Session,
    settings: Settings,
    owner_id: uuid.UUID,
    snapshot: RecipeSnapshot,
    constraints: AuthorizedConstraints,
    *,
    redis: Redis,
    version_id: uuid.UUID,
) -> tuple[RecipeSnapshot, dict[str, tuple[str, float, bool]], list[str]]:
    result = snapshot.model_copy(deep=True)
    reasons: dict[str, tuple[str, float, bool]] = {}
    notices: list[str] = []
    for item in result.ingredients:
        single = RecipeSnapshot(servings=snapshot.servings, ingredients=[item])
        matches = personal_safety.check(
            session,
            single,
            owner_id,
            settings,
            constraints=constraints,
            include_replacements=False,
        )
        if not matches.alerts:
            continue
        replacement = item.replacement
        if isinstance(replacement, str):
            replacement = RecipeReplacement(display_name=replacement)
        if replacement is None and item.display_name in COMMON_REPLACEMENTS:
            name = COMMON_REPLACEMENTS[item.display_name]
            row = session.scalar(select(Ingredient).where(Ingredient.standard_name == name))
            if row is not None:
                replacement = RecipeReplacement(display_name=name, ingredient_id=row.id)
        suggested = False
        if replacement is None:
            replacement, unavailable = suggest_replacement(
                session,
                redis,
                settings,
                owner_id,
                version_id,
                item.display_name,
                [s.instruction for s in snapshot.steps if item.id in s.ingredient_ids],
            )
            suggested = replacement is not None
            if unavailable:
                notices.append(unavailable)
        if isinstance(replacement, RecipeReplacement):
            # Resolve model/author names through the reviewed ingredient catalogue.
            if replacement.ingredient_id is None:
                row = session.scalar(
                    select(Ingredient).where(Ingredient.standard_name == replacement.display_name)
                )
                if row is not None:
                    replacement = replacement.model_copy(update={"ingredient_id": row.id})
            candidate = item.model_copy(deep=True)
            candidate.display_name = replacement.display_name
            candidate.ingredient_id = replacement.ingredient_id
            candidate.quantity = float(
                (Decimal(str(item.quantity)) * Decimal(str(replacement.ratio))).quantize(
                    Decimal("0.01"), rounding=ROUND_HALF_UP
                )
            )
            if item.base_quantity is not None:
                candidate.base_quantity = float(
                    (Decimal(str(item.base_quantity)) * Decimal(str(replacement.ratio))).quantize(
                        Decimal("0.01"), rounding=ROUND_HALF_UP
                    )
                )
            candidate.replacement = None
            # Original ingredient density/nutrition cannot describe a substitute.
            candidate.base_quantity = candidate.quantity if candidate.unit in {"g", "ml"} else None
            candidate.base_unit = (
                cast(Literal["g", "ml", "count"], candidate.unit)
                if candidate.base_quantity is not None
                else None
            )
            checked = personal_safety.check(
                session,
                RecipeSnapshot(servings=snapshot.servings, ingredients=[candidate]),
                owner_id,
                settings,
                constraints=constraints,
                include_replacements=False,
            )
            # Unknown data cannot certify an allergen-free alternative.
            has_allergy = bool(
                constraints.owner_allergies.get("categories")
                or constraints.owner_allergies.get("ingredients")
                or any(
                    m.allergies.get("categories") or m.allergies.get("ingredients")
                    for m in constraints.family
                )
            )
            if not checked.alerts and not (has_allergy and checked.incomplete):
                reason = f"已替换：{item.display_name} → {candidate.display_name}；" + (
                    "AI 建议，已重新检查" if suggested else "按明确替代比例，已重新检查"
                )
                reasons[item.id] = (reason, replacement.ratio, suggested)
                result.ingredients[result.ingredients.index(item)] = candidate
                # Stable ingredient references stay intact; executable text must
                # also use the alternative that is shown in the ingredient list.
                for step in result.steps:
                    # Legacy/manual steps may omit ingredient references.
                    step.instruction = step.instruction.replace(
                        item.display_name, candidate.display_name
                    )
                    if step.action:
                        step.action = step.action.replace(item.display_name, candidate.display_name)
                continue
        notices.append(f"这道菜可能不适合你：{item.display_name}没有明确安全替代，已保留原料")
    return result, reasons, notices


class ReplacementSuggestion(BaseModel):
    model_config = ConfigDict(extra="forbid")
    replacement: RecipeReplacement | None


def suggest_replacement(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner_id: uuid.UUID,
    version_id: uuid.UUID,
    ingredient: str,
    usage: list[str],
) -> tuple[RecipeReplacement | None, str | None]:
    # Ask only about culinary facts. Personal constraints are checked locally
    # after replay/cache lookup, and never sent to the model or cached here.
    payload = {"ingredient": ingredient, "usage": usage}
    digest = gateway.replay_key("personalize_replacement", payload)
    key = f"personalized:replacement:v1:{owner_id}:{version_id}:{digest}"

    def validate(raw: Any) -> ReplacementSuggestion:
        value = json.loads(raw) if isinstance(raw, str) else raw
        output = ReplacementSuggestion.model_validate(value)
        if output.replacement is not None and output.replacement.ingredient_id is not None:
            raise ValueError("AI must suggest a name, not invent catalogue identities")
        return output

    try:
        with redis.lock(key + ":lock", timeout=180, blocking_timeout=2):
            cached = redis.get(key)
            if cached is not None:
                output = validate(
                    cached.decode("utf-8") if isinstance(cached, bytes) else str(cached)
                )
            else:
                output = gateway.call(
                    session,
                    settings,
                    owner_id,
                    "personalize_replacement",
                    payload,
                    uuid.uuid4(),
                    content_id=version_id,
                    validate_output=validate,
                )
                redis.setex(key, 86400, output.model_dump_json())
            return output.replacement, None
    except (gateway.Unavailable, RedisError, ValueError, TypeError):
        return None, "AI 或替换缓存暂不可用；忌口替换暂缺，前三步换算仍可用"


def split_children(
    snapshot: RecipeSnapshot, constraints: AuthorizedConstraints
) -> tuple[RecipeSnapshot, dict[str, float]]:
    children = [
        m
        for m in constraints.family
        if m.age_band in {"under_1", "1_to_3", "3_to_6", "6_to_12"}
        and (m.flavors or {}).get("spicy", 1) == 0
    ]
    if not children:
        return snapshot, {}
    spicy = {
        item.id
        for item in snapshot.ingredients
        if item.flavor_contribution is not None and (item.flavor_contribution.spicy or 0) > 0
    }
    if not spicy:
        return snapshot, {}
    additions = [s for s in snapshot.steps if spicy.intersection(s.ingredient_ids)]
    target = additions[0] if len(additions) == 1 else None
    # Only an explicit late addition to an already cooked base can be divided.
    # Otherwise retain the reduced-spice result and explain incompatibility.
    if (
        target is None
        or not target.depends_on
        or not any(token in target.instruction for token in ("最后", "出锅前", "后加"))
    ):
        return snapshot, {}
    result = snapshot.model_copy(deep=True)
    target = next(s for s in result.steps if s.id == target.id)
    split_id = "personalized-child-portion"
    while any(s.id == split_id for s in result.steps):
        split_id += "-1"
    portion = len(children) / (len(constraints.family) + 1)
    for item in result.ingredients:
        if item.id in spicy:
            item.quantity = float(
                (Decimal(str(item.quantity)) * Decimal(str(1 - portion))).quantize(
                    Decimal("0.01"), rounding=ROUND_HALF_UP
                )
            )
            if item.base_quantity is not None:
                item.base_quantity = float(
                    (Decimal(str(item.base_quantity)) * Decimal(str(1 - portion))).quantize(
                        Decimal("0.01"), rounding=ROUND_HALF_UP
                    )
                )
    split = RecipeStep(
        id=split_id,
        action="先盛出儿童份",
        instruction=f"先盛出儿童的 {portion:.0%} 份量，再给其余份量后加辣椒；份量按人数估算。",
        depends_on=list(target.depends_on),
        why="同吃儿童不吃辣；仅对原步骤明确允许的后加辣味分盛",
    )
    target.depends_on = [split_id]
    result.steps.insert(result.steps.index(target), split)
    return result, {item_id: 1 - portion for item_id in spicy}


class EquipmentRewrite(BaseModel):
    model_config = ConfigDict(extra="forbid")
    steps: list[RecipeStep] = Field(max_length=200)


def equipment_payload(snapshot: RecipeSnapshot, equipment: list[str]) -> dict[str, Any]:
    # Called before family-specific child steps are added; omit private profile data.
    fields = {
        "id",
        "action",
        "instruction",
        "ingredient_ids",
        "duration_seconds",
        "heat",
        "temperature_celsius",
        "cookware",
        "doneness",
        "depends_on",
        "unattended",
    }
    return {
        "equipment": sorted(equipment),
        "steps": [step.model_dump(mode="json", include=fields) for step in snapshot.steps],
    }


def adapt_equipment(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner_id: uuid.UUID,
    version_id: uuid.UUID,
    snapshot: RecipeSnapshot,
    equipment: list[str],
) -> tuple[RecipeSnapshot, set[str], str | None]:
    vocabulary = config.get(session, "taste.equipment")["items"]
    aliases = {
        label: item["id"]
        for item in vocabulary
        for label in (item["id"], item["label"], *item.get("aliases", []))
    }
    allowed = {aliases.get(value, value) for value in equipment}
    missing = {
        step.id
        for step in snapshot.steps
        if step.cookware and aliases.get(step.cookware, step.cookware) not in allowed
    }
    if not missing:
        return snapshot, set(), None
    if not allowed:
        return snapshot, set(), "厨具适配暂缺：请先选择本次可用厨具；前三步换算仍可用"
    payload = equipment_payload(snapshot, sorted(allowed))
    digest = hashlib.sha256(
        json.dumps(
            [str(version_id), payload, gateway.PROMPT_VERSION], ensure_ascii=False, sort_keys=True
        ).encode()
    ).hexdigest()
    key = f"personalized:equipment:v1:{owner_id}:{digest}"

    def validate(raw: Any) -> EquipmentRewrite:
        value = json.loads(raw) if isinstance(raw, str) else raw
        output = EquipmentRewrite.model_validate(value)
        before = {step.id: step for step in snapshot.steps}
        if [s.id for s in output.steps] != [s.id for s in snapshot.steps]:
            raise ValueError("AI must retain step identities and order")
        for step in output.steps:
            source = before[step.id]
            if step.ingredient_ids != source.ingredient_ids or step.depends_on != source.depends_on:
                raise ValueError("AI must retain ingredient and dependency references")
            if step.id in missing and (
                not step.cookware
                or aliases.get(step.cookware, step.cookware) not in allowed
                or not step.doneness
            ):
                raise ValueError("AI must use available equipment and describe doneness")
            if step.id not in missing and step.model_dump(
                include={
                    "instruction",
                    "cookware",
                    "duration_seconds",
                    "heat",
                    "temperature_celsius",
                    "doneness",
                }
            ) != source.model_dump(
                include={
                    "instruction",
                    "cookware",
                    "duration_seconds",
                    "heat",
                    "temperature_celsius",
                    "doneness",
                }
            ):
                raise ValueError("AI cannot change unrelated steps")
        return output

    try:
        with redis.lock(key + ":lock", timeout=180, blocking_timeout=2):
            cached = redis.get(key)
            if cached is not None:
                output = validate(
                    json.loads(cached.decode("utf-8") if isinstance(cached, bytes) else str(cached))
                )
            else:
                output = gateway.call(
                    session,
                    settings,
                    owner_id,
                    "personalize_equipment",
                    payload,
                    uuid.uuid4(),
                    content_id=version_id,
                    validate_output=validate,
                )
                redis.setex(key, 86400, output.model_dump_json())
            result = snapshot.model_copy(deep=True)
            # Preserve author provenance on unrelated fields and put the accepted
            # execution facts onto copies of the actual displayed steps.
            for before, rewritten in zip(result.steps, output.steps, strict=True):
                if before.id in missing:
                    for field in (
                        "action",
                        "instruction",
                        "cookware",
                        "duration_seconds",
                        "heat",
                        "temperature_celsius",
                        "doneness",
                        "unattended",
                    ):
                        setattr(before, field, getattr(rewritten, field))
            return result, missing, None
    except (gateway.Unavailable, RedisError, ValueError, TypeError):
        return snapshot, set(), "AI 或厨具缓存暂不可用；厨具适配暂缺，前三步换算仍可用"
