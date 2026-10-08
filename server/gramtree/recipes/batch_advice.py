"""Read-only large-batch advice for an explicitly selected owned version."""

import json
import uuid
from typing import Any

from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway
from gramtree.ai.schemas import AIStatus, BatchAdvice, RecipeBatchAdviceOut
from gramtree.recipes import service
from gramtree.recipes.schemas import RecipeDerived, RecipeSnapshot
from gramtree.runtime_config import service as config
from gramtree.settings import Settings


def _validated(output: Any, related_ids: set[str]) -> BatchAdvice:
    if isinstance(output, str):
        if len(output) > 128_000:
            raise ValueError("Advice output exceeds size limit")
        output = json.loads(output)
    advice = BatchAdvice.model_validate(output)
    ids = [step.step_id for step in advice.steps]
    if len(set(ids)) != len(ids) or set(ids) != related_ids:
        raise ValueError("Advice must cover every related snapshot step exactly once")
    return advice


def request_advice(
    session: Session,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    version_id: uuid.UUID,
    target_servings: int,
) -> RecipeBatchAdviceOut:
    recipe, version = service._owned_version(session, owner, recipe_id, version_id)
    snapshot = RecipeSnapshot.model_validate(version.snapshot)
    # Reuse conversion for configured serving bounds and the exact same batch threshold.
    conversion = service._convert_snapshot_servings(
        session, snapshot, RecipeDerived.model_validate(version.derived), target_servings
    )
    eligible = target_servings >= snapshot.servings * float(
        config.get(session, "recipe.scaling_batch_multiplier")
    )
    result = RecipeBatchAdviceOut(
        recipe_id=recipe.id,
        version_id=version.id,
        original_servings=snapshot.servings,
        target_servings=target_servings,
        eligible=eligible,
        status=AIStatus.model_validate(
            gateway.availability(session, settings, owner.id, "batch_advice")
        ),
    )
    related_ids = {step.id for step in conversion.steps if step.batch_warning}
    if not eligible or not related_ids:
        result.error = "below_batch_threshold" if not eligible else "no_related_steps"
        result.status = AIStatus(
            available=False, remaining=result.status.remaining, reason=result.error
        )
        return result
    if not result.status.available:
        result.error = result.status.reason
        return result
    # Semantic replay keys deliberately omit recipe/user UUIDs. They include the full
    # persisted snapshot, so different versions and target servings never share advice.
    payload = {"snapshot": version.snapshot, "target_servings": target_servings}
    operation_id = uuid.uuid4()
    try:
        for repair in (False, True):
            output = gateway.call(
                session,
                settings,
                owner.id,
                "batch_advice",
                {**payload, "repair": True} if repair else payload,
                operation_id,
                content_id=version.id,
            )
            try:
                result.advice = _validated(output, related_ids)
                break
            except (ValueError, TypeError):
                if repair:
                    raise gateway.Unavailable("invalid_model_output") from None
    except gateway.Unavailable as exc:
        result.error = exc.reason
    result.status = AIStatus.model_validate(
        gateway.availability(session, settings, owner.id, "batch_advice")
    )
    if result.error:
        result.status = AIStatus(
            available=False, remaining=result.status.remaining, reason=result.error
        )
    return result
