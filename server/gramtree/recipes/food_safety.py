"""Versioned, deterministic checks; evidence is local to the affected ingredient.

Cooking temperature is deliberately not treated as food centre temperature. Rules
and every accepted form of evidence are data, so policy changes are reviewable.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import re
from datetime import timedelta
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator
from sqlalchemy import func, literal, or_, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from gramtree.core.time import utcnow
from gramtree.ingredients.attributes import IngredientAttributes
from gramtree.ingredients.models import Ingredient, IngredientAttribute
from gramtree.recipes.models import (
    Dish,
    DishAlias,
    FoodSafetyRuleRelease,
    Recipe,
    RecipeSafetyRecheck,
    RecipeVersion,
)
from gramtree.recipes.schemas import (
    RecipeIngredient,
    RecipeReplacementAllergens,
    RecipeSafetyFinding,
    RecipeSafetyResult,
    RecipeSnapshot,
    RecipeStep,
)

RULES_PATH = Path(__file__).with_name("data") / "food_safety_rules.json"


class PolicyModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class Trigger(PolicyModel):
    ingredient_terms: list[str] = Field(default_factory=list)
    categories: list[str] = Field(default_factory=list)
    exclude_ingredient_terms: list[str] = Field(default_factory=list)
    recipe_terms: list[str] = Field(default_factory=list)
    mode_terms: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)


class Evidence(PolicyModel):
    kind: Literal["text", "core_temperature", "duration"]
    terms: list[list[str]] = Field(default_factory=list)
    exclude_terms: list[str] = Field(default_factory=list)
    minimum: float | None = Field(default=None, ge=0, allow_inf_nan=False)
    actions: list[str] = Field(default_factory=list)
    instruction_patterns: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def valid_evidence(self) -> Evidence:
        if self.kind == "text" and (not self.terms or any(not group for group in self.terms)):
            raise ValueError("Text evidence needs nonempty groups of alternatives")
        if self.kind != "text" and self.minimum is None:
            raise ValueError("Numeric evidence needs a minimum")
        if self.kind == "duration" and not self.actions:
            raise ValueError("Duration evidence needs cooking/rest actions")
        for pattern in self.instruction_patterns:
            re.compile(pattern)
        return self


class EvidenceGroup(PolicyModel):
    scope: Literal["same_step", "ingredient_steps"] = "same_step"
    all: list[Evidence] = Field(min_length=1)


class SafetyRule(PolicyModel):
    id: str = Field(min_length=1)
    trigger: Trigger
    severity: Literal["info", "warning", "high_risk"]
    message: str = Field(min_length=1)
    basis: str = Field(min_length=1)
    threshold_celsius: float | None = None
    rest_minutes: int | None = None
    satisfied_by: list[EvidenceGroup] = Field(default_factory=list)


class ClaimPolicy(PolicyModel):
    version: str = Field(min_length=1, max_length=64)
    basis: str = Field(min_length=1)
    terms: list[str] = Field(min_length=1)


class Rules(PolicyModel):
    version: str = Field(min_length=1, max_length=64)
    evidence_negation_prefixes: list[str] = Field(min_length=1)
    evidence_disqualifiers: list[str] = Field(min_length=1)
    core_temperature_pattern: str
    rules: list[SafetyRule] = Field(min_length=1)
    prohibited_claims: ClaimPolicy

    @model_validator(mode="after")
    def valid_policy(self) -> Rules:
        ids = [rule.id for rule in self.rules]
        if len(set(ids)) != len(ids):
            raise ValueError("Rule IDs must be unique")
        pattern = re.compile(self.core_temperature_pattern)
        if "temperature" not in pattern.groupindex:
            raise ValueError("Core temperature pattern needs a temperature group")
        for rule in self.rules:
            trigger = rule.trigger
            if not (trigger.ingredient_terms or trigger.categories or trigger.recipe_terms):
                raise ValueError(f"Rule {rule.id} has no trigger")
        return self

    def digest(self) -> str:
        return hashlib.sha256(
            json.dumps(self.model_dump(), sort_keys=True, ensure_ascii=False).encode()
        ).hexdigest()


def rules(path: Path | None = None) -> Rules:
    # Read afresh: API and long-lived workers must notice a deployed rules update.
    path = path or Path(os.environ.get("GRAMTREE_FOOD_SAFETY_RULES_PATH", str(RULES_PATH)))
    return Rules.model_validate_json(path.read_text(encoding="utf-8"))


def register_release(session: Session, policy: Rules) -> FoodSafetyRuleRelease:
    """Record the immutable policy fingerprint in the same transaction as a save."""
    session.execute(
        insert(FoodSafetyRuleRelease)
        .values(
            version=policy.version,
            digest=policy.digest(),
            payload=policy.model_dump(mode="json"),
            discovered_at=utcnow(),
        )
        .on_conflict_do_nothing(index_elements=["version"])
    )
    row = session.get(FoodSafetyRuleRelease, policy.version)
    if row is None or row.digest != policy.digest():
        raise ValueError(f"规则版本 {policy.version} 的内容不可变")
    return row


def is_current(session: Session, version: RecipeVersion, policy: Rules) -> bool:
    release = session.get(FoodSafetyRuleRelease, policy.version)
    return bool(
        version.safety_current
        and version.safety_rules_version == policy.version
        and release is not None
        and release.digest == policy.digest()
    )


def queue_rechecks(session: Session, policy: Rules) -> int:
    """Discover all stale immutable versions idempotently for a policy release."""
    register_release(session, policy)
    stale = select(
        func.gen_random_uuid(),
        RecipeVersion.id,
        literal(policy.version),
        literal("pending"),
        literal(0),
        func.now(),
    ).where(
        or_(
            RecipeVersion.safety_rules_version.is_(None),
            RecipeVersion.safety_rules_version != policy.version,
        )
    )
    inserted = (
        insert(RecipeSafetyRecheck)
        .from_select(
            ["id", "version_id", "rules_version", "status", "attempts", "created_at"],
            stale,
            include_defaults=False,
        )
        .on_conflict_do_nothing(constraint="uq_recipe_safety_recheck_target")
        .returning(RecipeSafetyRecheck.id)
        .cte("queued")
    )
    # psycopg may report rowcount=-1; count RETURNING rows on the database.
    return session.scalar(select(func.count()).select_from(inserted)) or 0


def run_rechecks(session: Session, policy: Rules, limit: int = 100) -> dict[str, Any]:
    """Process a bounded batch, with a recoverable lease for worker crashes.

    A claim is committed before work starts. Its five-minute lease expires on
    crash; successful index writes and job completion commit together.
    """
    queued = queue_rechecks(session, policy)
    session.commit()
    checked = failed = 0
    attempted_ids = []
    for _ in range(limit):
        if rules().digest() != policy.digest():
            break  # Deployment changed while this batch was running.
        ready = or_(
            RecipeSafetyRecheck.status.in_(["pending", "retry"]),
            (RecipeSafetyRecheck.status == "running")
            & (RecipeSafetyRecheck.attempted_at < utcnow() - timedelta(minutes=5)),
        )
        job = session.scalar(
            select(RecipeSafetyRecheck)
            .where(
                RecipeSafetyRecheck.rules_version == policy.version,
                ready,
                RecipeSafetyRecheck.id.not_in(attempted_ids),
            )
            .order_by(RecipeSafetyRecheck.attempted_at.asc().nullsfirst(), RecipeSafetyRecheck.id)
            .limit(1)
            .with_for_update(skip_locked=True)
            .execution_options(populate_existing=True)
        )
        if job is None:
            session.rollback()
            break
        job_id = job.id
        attempted_ids.append(job_id)
        job.status = "running"
        job.attempts += 1
        attempt = job.attempts
        job.attempted_at = utcnow()
        session.commit()
        try:
            # Hold the lease row and version locks until index + completion commit.
            session.refresh(job, with_for_update=True)
            if job.status != "running" or job.attempts != attempt:
                session.rollback()
                continue  # An expired claim was recovered while this worker paused.
            version = session.scalar(
                select(RecipeVersion)
                .where(RecipeVersion.id == job.version_id)
                .with_for_update()
                .execution_options(populate_existing=True)
            )
            if version is None:
                # Account/recipe deletion cascades the work row too.
                session.rollback()
                continue
            recipe = session.get(Recipe, version.recipe_id)
            dish = session.get(Dish, recipe.dish_id) if recipe is not None else None
            if dish is None:
                raise ValueError("菜谱关联数据不存在")
            snapshot = RecipeSnapshot.model_validate(version.snapshot)
            safety_title, safety_descriptions = version_safety_input(session, version, dish)
            result = check(
                session, snapshot, safety_title, descriptions=safety_descriptions, policy=policy
            )
            if rules().digest() != policy.digest():
                raise ValueError("规则更新，等待新规则复检")
            version.safety_current = result.model_dump(mode="json")
            version.safety_rules_version = result.rules_version
            job.status = "success"
            job.completed_at = utcnow()
            job.last_error = None
            session.commit()
            checked += 1
        except Exception as exc:
            session.rollback()
            refreshed = session.scalar(
                select(RecipeSafetyRecheck)
                .where(
                    RecipeSafetyRecheck.id == job_id,
                    RecipeSafetyRecheck.status == "running",
                    RecipeSafetyRecheck.attempts == attempt,
                )
                .with_for_update()
            )
            if refreshed is not None:
                refreshed.status = "retry"
                # Do not put private recipe text from a validation error in logs.
                refreshed.last_error = type(exc).__name__
                session.commit()
            logging.getLogger("gramtree.food_safety").warning(
                "food safety recheck deferred",
                extra={
                    "job_id": str(job_id),
                    "rules_version": policy.version,
                    "error_type": type(exc).__name__,
                },
            )
            failed += 1
    return {
        "rules_version": policy.version,
        "checked": checked,
        "failed": failed,
        "queued": queued,
        "remaining": session.scalar(
            select(func.count())
            .select_from(RecipeSafetyRecheck)
            .where(
                RecipeSafetyRecheck.rules_version == policy.version,
                RecipeSafetyRecheck.status != "success",
            )
        )
        or 0,
    }


def _strings(value: Any) -> list[str]:
    """Health claims cover all textual fields, including notes and provenance."""
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [text for item in value.values() for text in _strings(item)]
    if isinstance(value, list):
        return [text for item in value for text in _strings(item)]
    return []


def _has(text: str, terms: list[str]) -> bool:
    return any(term.casefold() in text.casefold() for term in terms)


def _affirmative_prefix(text: str, start: int, policy: Rules) -> bool:
    # Allow intervening verbs ("不要确认中心无粉红"), but do not carry
    # negation across punctuation into another instruction clause.
    prefix = re.split(r"[，,。；;！!？?\n]", text[max(0, start - 64) : start])[-1]
    return not _has(prefix, policy.evidence_negation_prefixes)


def core_temperatures(text: str, policy: Rules) -> list[float]:
    """Only affirmative centre-temperature statements, using deployed negation rules."""
    return [
        float(match.group("temperature"))
        for match in re.finditer(policy.core_temperature_pattern, text)
        if _affirmative_prefix(text, match.start(), policy)
    ]


def _positive(text: str, term: str, policy: Rules) -> bool:
    return any(
        _affirmative_prefix(text, match.start(), policy)
        for match in re.finditer(re.escape(term), text, re.IGNORECASE)
    )


def _step_text(step: RecipeStep) -> str:
    # Notes/why explain a step; they do not establish that an action is performed.
    return " ".join((step.action or "", step.instruction, step.doneness or ""))


def _related_steps(
    snapshot: RecipeSnapshot, item: RecipeIngredient, standard_name: str
) -> list[RecipeStep]:
    result = []
    for step in snapshot.steps:
        if item.id in step.ingredient_ids or (
            not step.ingredient_ids
            and _has(
                _step_text(step), [item.display_name, *([standard_name] if standard_name else [])]
            )
        ):
            result.append(step)
    # A sole ingredient is unambiguous even in older snapshots without references.
    if len(snapshot.ingredients) == 1:
        result.extend(
            step for step in snapshot.steps if not step.ingredient_ids and step not in result
        )
    return result


def _evidence(evidence: Evidence, step: RecipeStep, policy: Rules) -> bool:
    text = _step_text(step)
    if _has(text, [*evidence.exclude_terms, *policy.evidence_disqualifiers]):
        return False
    # A structured timer covers the whole step. Phase-specific rules must accept
    # only a dedicated instruction, never infer a phase duration from mixed work.
    if evidence.instruction_patterns and not any(
        re.fullmatch(pattern, step.instruction.strip()) for pattern in evidence.instruction_patterns
    ):
        return False
    if evidence.kind == "text":
        return all(any(_positive(text, term, policy) for term in group) for group in evidence.terms)
    if evidence.kind == "duration":
        return any(
            _positive(text, action, policy) for action in evidence.actions
        ) and step.duration_seconds >= (evidence.minimum or 0)
    return any(value >= (evidence.minimum or 0) for value in core_temperatures(text, policy))


def _satisfied(rule: SafetyRule, steps: list[RecipeStep], policy: Rules) -> bool:
    for group in rule.satisfied_by:
        if group.scope == "same_step":
            if any(
                all(_evidence(condition, step, policy) for condition in group.all) for step in steps
            ):
                return True
        elif all(
            any(_evidence(condition, step, policy) for step in steps) for condition in group.all
        ):
            return True
    return False


def version_safety_input(
    session: Session, version: RecipeVersion, dish: Dish
) -> tuple[str, list[str]]:
    """Replay the exact descriptive fields checked at save when available.

    Legacy versions have no context column, so include the current aliases as a
    conservative fallback; new versions never depend on mutable dish metadata.
    """
    context = version.safety_context
    if isinstance(context, dict):
        title = context.get("title")
        descriptions = context.get("descriptions")
        if (
            isinstance(title, str)
            and isinstance(descriptions, list)
            and all(isinstance(value, str) for value in descriptions)
        ):
            return title, descriptions
    aliases = list(
        session.scalars(select(DishAlias.alias).where(DishAlias.dish_id == dish.id)).all()
    )
    return dish.name, [*aliases, version.change_note]


def _library(session: Session, ingredient_id: Any) -> tuple[str, str, list[str], bool]:
    if ingredient_id is None:
        return "", "", [], True
    row = session.get(Ingredient, ingredient_id)
    if row is None:
        return "", "", [], True
    attrs = IngredientAttributes.from_stored(
        {
            attribute.field: (attribute.value, attribute.source, attribute.status)
            for attribute in session.query(IngredientAttribute).filter_by(ingredient_id=row.id)
        }
    )
    return (
        row.standard_name,
        row.category,
        [] if attrs.allergens is None else attrs.allergens.value,
        attrs.allergens is None,
    )


def check(
    session: Session,
    snapshot: RecipeSnapshot,
    title: str = "",
    *,
    descriptions: list[str] | None = None,
    policy: Rules | None = None,
) -> RecipeSafetyResult:
    policy = policy or rules()
    recipe_text = " ".join(
        [
            title,
            snapshot.dish_type or "",
            snapshot.description or "",
            *snapshot.tags,
            *(descriptions or []),
        ]
    )
    findings: list[RecipeSafetyFinding] = []
    allergens: set[str] = set()
    incomplete = False
    replacements: list[RecipeReplacementAllergens] = []
    library = {item.id: _library(session, item.ingredient_id) for item in snapshot.ingredients}
    for item in snapshot.ingredients:
        _, _, item_allergens, unknown = library[item.id]
        allergens.update(item_allergens)
        incomplete |= unknown
        if item.replacement is not None:
            replacement = item.replacement
            name = replacement if isinstance(replacement, str) else replacement.display_name
            replacement_id = None if isinstance(replacement, str) else replacement.ingredient_id
            _, _, replacement_allergens, replacement_unknown = _library(session, replacement_id)
            allergens.update(replacement_allergens)
            incomplete |= replacement_unknown
            replacements.append(
                RecipeReplacementAllergens(
                    ingredient_id=item.id,
                    display_name=name,
                    allergens=sorted(replacement_allergens),
                    incomplete=replacement_unknown,
                )
            )
    for rule in policy.rules:
        trigger = rule.trigger
        if trigger.tags and not set(trigger.tags).intersection(snapshot.tags):
            continue
        matched = False
        for item in snapshot.ingredients:
            standard_name, category, _, _ = library[item.id]
            ingredient_text = " ".join([item.display_name, standard_name, item.preparation or ""])
            if _has(ingredient_text, trigger.exclude_ingredient_terms):
                continue
            if not (
                _has(ingredient_text, trigger.ingredient_terms) or category in trigger.categories
            ):
                continue
            steps = _related_steps(snapshot, item, standard_name)
            if trigger.mode_terms and not _has(
                " ".join(
                    [
                        recipe_text,
                        ingredient_text,
                        *(text for step in steps for text in _strings(step.model_dump())),
                    ]
                ),
                trigger.mode_terms,
            ):
                continue
            matched = True
            if _satisfied(rule, steps, policy):
                continue
            findings.append(
                RecipeSafetyFinding(
                    rule_id=rule.id,
                    severity=rule.severity,
                    message=rule.message,
                    basis=rule.basis,
                    step_ids=[step.id for step in steps],
                    ingredient_ids=[item.id],
                    threshold_celsius=rule.threshold_celsius,
                    rest_minutes=rule.rest_minutes,
                )
            )
        # Recognise explicitly risky dish names even without a corresponding item.
        if not matched and _has(recipe_text, trigger.recipe_terms):
            steps = [
                step for step in snapshot.steps if _has(_step_text(step), trigger.recipe_terms)
            ]
            if not _satisfied(rule, steps, policy):
                findings.append(
                    RecipeSafetyFinding(
                        rule_id=rule.id,
                        severity=rule.severity,
                        message=rule.message,
                        basis=rule.basis,
                        step_ids=[step.id for step in steps],
                        threshold_celsius=rule.threshold_celsius,
                        rest_minutes=rule.rest_minutes,
                    )
                )
    claim_texts = [title, *(descriptions or []), *_strings(snapshot.model_dump())]
    prohibited = [
        term
        for term in policy.prohibited_claims.terms
        if any(_has(text, [term]) for text in claim_texts)
    ]
    return RecipeSafetyResult(
        rules_version=policy.version,
        checked_at=utcnow(),
        findings=findings,
        high_risk=any(item.severity == "high_risk" for item in findings),
        allergens=sorted(allergens),
        allergens_incomplete=incomplete,
        replacement_allergens=replacements,
        prohibited_claims=prohibited,
        can_save=not prohibited,
        claim_basis=policy.prohibited_claims.basis,
    )
