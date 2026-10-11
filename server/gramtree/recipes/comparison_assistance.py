"""Display-only AI overlay; never changes deterministic comparison or saved versions."""

import hashlib
import json
import logging
import uuid
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field
from redis import Redis
from redis.exceptions import RedisError
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway
from gramtree.ai.models import AICall
from gramtree.core.ids import IdV4
from gramtree.recipes.full_comparison import (
    RecipeFullComparison,
    _visible_pair,
    compare_full,
    rules,
)
from gramtree.recipes.models import RecipeComparisonAssistanceCache
from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.runtime_config import service as config
from gramtree.settings import Settings
from gramtree.ui_protocol.protocol import SourceBasis, SourcedValue


class AssistedStepPair(BaseModel):
    before_step_id: str
    after_step_id: str
    alignment: Literal["ai_assisted"]
    confidence: float = Field(ge=0, le=1, allow_inf_nan=False)
    source_type: Literal["ai_estimated"]
    basis: SourceBasis


class RecipeComparisonAssistance(BaseModel):
    from_version_id: IdV4
    to_version_id: IdV4
    rules_version: str
    status: Literal["ready", "unavailable"] = "unavailable"
    alignments: list[AssistedStepPair] = Field(default_factory=list)
    interpretation: SourcedValue | None = None
    reason_code: str | None = None


logger = logging.getLogger("gramtree.comparison_assistance")


class AssistancePolicy(BaseModel):
    min_confidence: float = Field(ge=0, le=1, allow_inf_nan=False)

    @property
    def version(self) -> str:
        # Bind threshold and prompt/validation revisions without changing #142.
        payload = json.dumps(["comparison-v1", gateway.PROMPT_VERSION, self.min_confidence])
        return "assist-v1-" + hashlib.sha256(payload.encode()).hexdigest()[:32]


def _policy(session: Session) -> AssistancePolicy:
    return AssistancePolicy(
        min_confidence=config.get(session, "recipe.comparison_ai_min_confidence")
    )


class ModelStepPair(BaseModel):
    model_config = ConfigDict(extra="forbid")

    before_step_id: str = Field(min_length=1, max_length=100)
    after_step_id: str = Field(min_length=1, max_length=100)
    confidence: float = Field(ge=0, le=1, allow_inf_nan=False, strict=True)


class ComparisonModelOutput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    alignments: list[ModelStepPair] = Field(max_length=100)
    interpretation: str | None = Field(max_length=400, strict=True)


# Only these execution facts cross the model boundary. Do not forward raw added/
# removed deltas: they contain signed measure receipts and provenance payloads.
_STEP_FIELDS = (
    "id",
    "action",
    "instruction",
    "duration_seconds",
    "unattended",
    "heat",
    "temperature_celsius",
    "cookware",
    "doneness",
    "depends_on",
)
_INGREDIENT_FIELDS = (
    "display_name",
    "quantity",
    "unit",
    "base_quantity",
    "base_unit",
    "preparation",
    "group",
    "optional",
    "functional",
    "scaling_mode",
)
# Fact values are opt-in too: a scalar replacement note (or a future provenance
# field) is not execution metadata merely because it is a string.
_FACT_VALUE_FIELDS = frozenset(
    (
        *_STEP_FIELDS,
        *_INGREDIENT_FIELDS,
        "total_time_seconds",
        "active_time_seconds",
        "difficulty",
        "dish_type",
        "tags",
        "cuisine",
        "order",
        "main_heating_actions",
        "quantity_unit",
        "flavor_contribution",
    )
)


def _payload(
    comparison: RecipeFullComparison, a: RecipeSnapshot, b: RecipeSnapshot
) -> dict[str, Any]:
    def uncertain(side: str, snapshot: RecipeSnapshot) -> list[dict[str, Any]]:
        names = {item.id: item.display_name for item in snapshot.ingredients}
        result = []
        for row in comparison.steps:
            step = getattr(row, side)
            if row.alignment == "uncertain" and step is not None:
                fields = {field: getattr(step, field) for field in _STEP_FIELDS}
                fields["ingredient_names"] = [names[ref] for ref in step.ingredient_ids]
                result.append(fields)
        return result

    def fact(change: Any) -> dict[str, Any]:
        result = {"kind": change.kind, "field": change.field, "grade": change.grade}
        # Nested before/after objects are deliberately not trusted as safe facts.
        if change.field in _FACT_VALUE_FIELDS and change.kind not in {
            "added",
            "removed",
            "replacement",
        }:
            for side in ("before", "after"):
                value = getattr(change, side)
                if (
                    value is None
                    or isinstance(value, (str, int, float, bool))
                    or (isinstance(value, list) and all(isinstance(v, str) for v in value))
                ):
                    result[side] = value
        return result

    ingredient_changes = []
    for row in comparison.ingredients:
        changes = [fact(c) for c in row.changes if c.grade != "excluded"]
        if changes:
            ingredient_changes.append(
                {
                    side: {field: getattr(item, field) for field in _INGREDIENT_FIELDS}
                    if (item := getattr(row, side)) is not None
                    else None
                    for side in ("before", "after")
                }
                | {"changes": changes}
            )
    return {
        "versions": {
            side: {
                "dish_name": version.dish_name,
                "servings": version.servings,
                "duration_seconds": sum(step.duration_seconds for step in snapshot.steps),
            }
            for side, version, snapshot in (
                ("before", comparison.from_version, a),
                ("after", comparison.to_version, b),
            )
        },
        "uncertain_steps": {"before": uncertain("before", a), "after": uncertain("after", b)},
        "differences": {
            "conclusion": comparison.conclusion,
            "ingredients": ingredient_changes,
            "snapshot_fields": [
                fact(c) for c in comparison.snapshot_fields if c.grade != "excluded"
            ],
            "steps": [
                fact(c) | {"before_index": row.before_index, "after_index": row.after_index}
                for row in comparison.steps
                for c in row.changes
                if c.grade != "excluded"
            ],
            "methods": [fact(c) for c in comparison.method_changes],
        },
    }


def _validated(output: Any, before_ids: set[str], after_ids: set[str]) -> ComparisonModelOutput:
    try:
        if isinstance(output, str):
            if len(output) > 128_000:
                raise ValueError("Comparison output exceeds size limit")
            output = json.loads(output)
        result = ComparisonModelOutput.model_validate(output)
        left = [pair.before_step_id for pair in result.alignments]
        right = [pair.after_step_id for pair in result.alignments]
        if (
            not set(left) <= before_ids
            or not set(right) <= after_ids
            or len(left) != len(set(left))
            or len(right) != len(set(right))
        ):
            raise ValueError("Pairs must reference unique legal uncertain steps")
        if result.interpretation is not None:
            sentence = result.interpretation.strip()
            if (
                not sentence
                or len(sentence.splitlines()) != 1
                or any(
                    term in sentence.casefold()
                    for term in ("已验证", "经验证", "verified", "用户反馈", "个人反馈", "口味档案")
                )
            ):
                raise ValueError("Interpretation must be one line of general experience")
            result.interpretation = sentence
        return result
    except (ValueError, TypeError) as exc:
        raise gateway.Unavailable("invalid_model_output") from exc


def request_assistance(
    session: Session,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    from_version_id: uuid.UUID,
    to_version_id: uuid.UUID,
    *,
    redis: Redis,
) -> RecipeComparisonAssistance:
    comparison = compare_full(session, owner, recipe_id, from_version_id, to_version_id)
    result = RecipeComparisonAssistance(
        from_version_id=from_version_id,
        to_version_id=to_version_id,
        rules_version=comparison.rules_version,
    )
    policy = _policy(session)
    key = (from_version_id, to_version_id, comparison.rules_version, policy.version)

    def check_binding() -> None:
        # Recheck both permissions after waiting/provider I/O too. A deleted or
        # no-longer-readable version must not be served from shared AI storage.
        _visible_pair(session, owner, recipe_id, from_version_id, to_version_id)
        current_rules = rules(session).version
        if current_rules != comparison.rules_version or _policy(session).version != policy.version:
            result.rules_version = current_rules
            raise gateway.Unavailable("rules_changed")

    def cached() -> RecipeComparisonAssistance | None:
        check_binding()
        row = session.get(RecipeComparisonAssistanceCache, key)
        return RecipeComparisonAssistance.model_validate(row.result) if row else None

    try:
        if saved := cached():
            return saved
        status = gateway.availability(session, settings, owner.id, "comparison")
        if not status["available"]:
            result.reason_code = status["reason"]
            return result
        _, model_policy = gateway.route(session, "comparison")
        # A Redis lease survives gateway.call's budget/accounting commits. Its
        # conservative finite TTL covers all configured attempts and HTTP phases;
        # waiters return a bounded unavailable overlay rather than duplicate spend.
        lock = redis.lock(
            "comparison-assistance:" + ":".join(map(str, key)),
            timeout=(model_policy.retries + 1) * (4 * model_policy.timeout + 15) + 30,
            blocking_timeout=2,
        )
        if not lock.acquire():
            if saved := cached():
                return saved
            result.reason_code = "comparison_in_progress"
            return result
        try:
            if saved := cached():
                return saved
            status = gateway.availability(session, settings, owner.id, "comparison")
            if not status["available"]:
                result.reason_code = status["reason"]
                return result
            a, b = _visible_pair(session, owner, recipe_id, from_version_id, to_version_id)
            payload = _payload(
                comparison,
                RecipeSnapshot.model_validate(a.snapshot),
                RecipeSnapshot.model_validate(b.snapshot),
            )
            before_ids = {step["id"] for step in payload["uncertain_steps"]["before"]}
            after_ids = {step["id"] for step in payload["uncertain_steps"]["after"]}
            operation_id = uuid.uuid4()
            try:
                output = gateway.call(
                    session,
                    settings,
                    owner.id,
                    "comparison",
                    payload,
                    operation_id,
                    validate_output=lambda raw: _validated(raw, before_ids, after_ids),
                )
                result.alignments = [
                    AssistedStepPair(
                        before_step_id=pair.before_step_id,
                        after_step_id=pair.after_step_id,
                        confidence=pair.confidence,
                        alignment="ai_assisted",
                        source_type="ai_estimated",
                        basis=SourceBasis(
                            reason_code="ai_assisted_alignment",
                            text="AI 辅助对齐，仅用于展示；不改变确定性差异或结论",
                        ),
                    )
                    for pair in output.alignments
                    if pair.confidence >= policy.min_confidence
                ]
                if output.interpretation:
                    result.interpretation = SourcedValue(
                        source_type="ai_estimated",
                        value=output.interpretation,
                        basis=SourceBasis(
                            reason_code="general_experience",
                            text="AI 一句话解读，依据为一般经验；不是已验证结论",
                        ),
                    )
                result.status = (
                    "ready" if result.alignments or result.interpretation else "unavailable"
                )
                if result.status == "unavailable":
                    result.reason_code = (
                        "low_confidence" if output.alignments else "no_interpretation"
                    )
            except gateway.Unavailable as exc:
                result.reason_code = exc.reason
            check_binding()
            attempted = session.scalar(
                select(AICall.id).where(AICall.request_id == operation_id).limit(1)
            )
            if attempted is not None:
                # Reuse failed/low-confidence actual attempts too. Admission
                # denials above made no attempt and must recover after reconfiguration.
                session.execute(
                    insert(RecipeComparisonAssistanceCache)
                    .values(
                        from_version_id=from_version_id,
                        to_version_id=to_version_id,
                        rules_version=comparison.rules_version,
                        assistance_version=policy.version,
                        result=result.model_dump(mode="json"),
                    )
                    .on_conflict_do_nothing()
                )
                session.commit()
            return result
        finally:
            try:
                lock.release()
            except RedisError:
                logger.warning("comparison singleflight lease unavailable during release")
    except gateway.Unavailable as exc:
        result.reason_code = exc.reason
    except RedisError:
        result.reason_code = "singleflight_unavailable"
    result.status = "unavailable"
    result.alignments = []
    result.interpretation = None
    return result
