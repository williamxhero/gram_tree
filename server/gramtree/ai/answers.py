"""Read-only version explanations. Evidence/personalization remain disconnected.

The context/dependency boundary is internal: future evidence and cache consumers
must resolve authorized, current inputs here, not accept model-reported provenance.
"""

import re
import uuid
from typing import Any

from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway, service
from gramtree.ai.schemas import AIStatus, ModelAnswer, RecipeAnswer
from gramtree.recipes import food_safety
from gramtree.recipes import service as recipes
from gramtree.recipes.schemas import RecipeDetail, RecipeSafetyResult, RecipeSnapshot
from gramtree.settings import Settings

POLICY_VERSION = "recipe-answer-v1"
# No platform evidence exists in this slice. Reject invented provenance, not
# ordinary quantities, temperatures or times. Never try to redact it piecemeal.
EVIDENCE_CLAIM = re.compile(
    r"平台|社区|做过记录|样本|已验证|经验证|评分|成功率|"
    r"\d+\s*(?:人认为|人做过|人验证|%|％)|"
    r"platform|community|verified|cooking records|samples|success rate",
    re.IGNORECASE,
)
UNSAFE_ADVICE = re.compile(
    r"(?:鸡|禽|猪|肉|蛋).{0,12}(?:生吃|半熟|不用煮熟|不必煮熟)|"
    r"(?:表面变白|颜色变白).{0,8}(?:就熟|即可|就安全)|"
    r"(?:不需要|无需|不用).{0,6}(?:熟透|中心温度)|"
    r"(?:eat|serve).{0,15}(?:raw|undercooked).{0,15}(?:chicken|poultry|pork)",
    re.IGNORECASE,
)


def cooking_context(snapshot: RecipeSnapshot, dish_name: str) -> dict[str, Any]:
    """Shared allowlist for live/replay input, never an oracle for HTTP tests.

    Only local step/ingredient IDs; no global IDs, notes, profiles, images or logs.
    Static design rationale is not experience evidence and is deliberately excluded.
    """
    return {
        "dish_name": dish_name,
        "servings": snapshot.servings,
        "ingredients": [
            item.model_dump(
                mode="json",
                include={
                    "id",
                    "display_name",
                    "quantity",
                    "unit",
                    "preparation",
                },
            )
            for item in snapshot.ingredients
        ],
        "steps": [
            step.model_dump(
                mode="json",
                include={
                    "id",
                    "action",
                    "instruction",
                    "ingredient_ids",
                    "duration_seconds",
                    "heat",
                    "temperature_celsius",
                    "cookware",
                    "doneness",
                },
            )
            for step in snapshot.steps
        ],
    }


def answer_context(detail: RecipeDetail) -> tuple[dict[str, Any], dict[str, str]]:
    """Dependency identifiers stay server-side for #136/#138."""
    context = cooking_context(detail.version.snapshot, detail.dish.name)
    dependencies = {
        "recipe_version": str(detail.version.id),
        "answer_policy": POLICY_VERSION,
        "safety_rules": food_safety.rules().version,
        "evidence": "disabled",
        "personal_context": "none",
    }
    return context, dependencies


def _merge_safety(base: RecipeSafetyResult, extra: RecipeSafetyResult) -> None:
    """Add question/output risks without erasing version-bound findings or scope."""
    for finding in extra.findings:
        if finding not in base.findings:
            base.findings.append(finding)
    base.allergens = sorted(set(base.allergens) | set(extra.allergens))
    base.prohibited_claims = sorted(set(base.prohibited_claims) | set(extra.prohibited_claims))
    for replacement in extra.replacement_allergens:
        if replacement not in base.replacement_allergens:
            base.replacement_allergens.append(replacement)
    base.high_risk |= extra.high_risk
    base.allergens_incomplete |= extra.allergens_incomplete
    base.can_save &= extra.can_save
    base.claim_basis = base.claim_basis or extra.claim_basis


def answer(
    session: Session,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    version_id: uuid.UUID,
    question: str,
) -> RecipeAnswer:
    # Resolve permission and recipe/version membership before quota checks or I/O.
    detail = recipes.get_version(session, settings, owner, recipe_id, version_id)
    snapshot = detail.version.snapshot
    context, dependencies = answer_context(detail)
    status = AIStatus.model_validate(gateway.availability(session, settings, owner.id, "explain"))
    safety, _ = recipes.recipe_safety_context(session, owner, recipe_id, version_id)
    result = RecipeAnswer(
        recipe_id=recipe_id,
        version_id=version_id,
        question=question,
        state="cannot_answer",
        status=status,
        conclusion="无法可靠回答这个问题。请保留必显安全提示；需要改动时使用表单并确认保存。",
        safety=safety,
        numeric_warnings=service.numeric_warnings(snapshot),
    )
    request_safety = food_safety.check(session, RecipeSnapshot(servings=1), question)
    _merge_safety(result.safety, request_safety)
    if request_safety.high_risk or request_safety.prohibited_claims:
        result.error = "unsafe_question"
        return result
    if not status.available:
        result.state = "unavailable"
        result.error = status.reason
        result.conclusion = "菜谱解释能力暂时不可用；问题已保留，查看、表单编辑和规则换算仍可使用。"
        return result
    payload = {
        "stage": "recipe_question",
        "question": question,
        "context": context,
        "basis": "general_experience",
        "evidence": None,
        "policy_version": dependencies["answer_policy"],
    }
    try:
        raw = gateway.call(
            session, settings, owner.id, "explain", payload, uuid.uuid4(), content_id=version_id
        )
        model = (
            ModelAnswer.model_validate_json(raw)
            if isinstance(raw, str)
            else ModelAnswer.model_validate(raw)
        )
        text = " ".join([model.conclusion, model.explanation, model.details])
        output_safety = food_safety.check(session, RecipeSnapshot(servings=1), text)
        _merge_safety(result.safety, output_safety)
        # Use the deployed rules' core-temperature parser and applicable thresholds,
        # not model confidence or an independently maintained temperature table.
        uncooked = snapshot.model_copy(deep=True)
        uncooked.steps = []
        thresholds = [
            finding.threshold_celsius
            for finding in food_safety.check(session, uncooked, detail.dish.name).findings
            if finding.threshold_celsius is not None
        ]
        temperatures = food_safety.core_temperatures(text, food_safety.rules())
        unsafe_temperature = bool(thresholds) and any(
            value < max(thresholds) for value in temperatures
        )
        if (
            output_safety.high_risk
            or output_safety.prohibited_claims
            or EVIDENCE_CLAIM.search(text)
            or UNSAFE_ADVICE.search(text)
            or unsafe_temperature
        ):
            result.error = "unsafe_output"
            return result
        if not model.kitchen_scope or model.state == "cannot_answer":
            result.error = "outside_scope" if not model.kitchen_scope else "no_reliable_answer"
            return result
        result.state = "uncertain" if model.confidence < 0.7 else model.state
        if result.state == "uncertain":
            result.conclusion = "不确定：无法从这个版本可靠确定。"
            result.explanation = "请补充具体食材、火候或操作条件后再问；不要把推测当作结论。"
        else:
            result.conclusion = model.conclusion
            result.explanation = model.explanation
            result.details = model.details
    except (gateway.Unavailable, ValueError, TypeError) as exc:
        result.state = "unavailable"
        result.error = exc.reason if isinstance(exc, gateway.Unavailable) else "invalid_output"
        result.status.available = False
        result.status.reason = result.error
        result.conclusion = "菜谱解释能力暂时不可用；问题已保留，查看、表单编辑和规则换算仍可使用。"
    finally:
        refreshed = AIStatus.model_validate(
            gateway.availability(session, settings, owner.id, "explain")
        )
        result.status.remaining = refreshed.remaining
    return result
