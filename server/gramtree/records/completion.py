"""Validate a completed, frozen cooking view before minting verification.

A view receipt is issued by the server, scoped to the executing account and
exact version. It stays valid offline: recipes are immutable and execution must
not be recomputed from today's profile when yesterday's record is synchronized.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import uuid
from copy import deepcopy
from typing import Any

from pydantic import ValidationError

from gramtree.core.errors import ApiError
from gramtree.core.time import utcnow
from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.records.schemas import CookingRecordCreate
from gramtree.settings import Settings

_RESERVED = {"server_completed", "executed_snapshot", "derivation_available"}


def execution_token(
    owner_id: uuid.UUID,
    version_id: uuid.UUID,
    snapshot: RecipeSnapshot | dict[str, Any],
    settings: Settings,
) -> str:
    value = RecipeSnapshot.model_validate(snapshot).model_dump(mode="json")
    digest = hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()
    ).hexdigest()
    message = f"cooking-execution:v1:{owner_id}:{version_id}:{digest}".encode()
    return hmac.new(settings.auth_secret.encode(), message, hashlib.sha256).hexdigest()


def _invalid(detail: str) -> ApiError:
    return ApiError(422, "invalid_cooking_completion", "做菜完成记录有误", detail)


def completed_context(
    owner_id: uuid.UUID,
    body: CookingRecordCreate,
    settings: Settings,
) -> tuple[str, dict[str, Any]]:
    """Ignore no evidence; reject attempted self-attestation or altered evidence."""
    if _RESERVED.intersection(body.source_context):
        raise _invalid("不能提交服务端验证字段")
    if body.verification != "unverified":
        raise ApiError(422, "verification_unavailable", "不能自行声明做菜模式验证")
    completion = body.completion
    if completion is None:
        return "unverified", deepcopy(body.source_context)
    if body.source != "cooking_session" or body.recipe_version_id is None:
        raise _invalid("完成证明只能用于做菜模式的精确版本")
    if completion.session_id != body.client_id:
        raise _invalid("会话和记录 ID 不一致")
    if completion.finished_at < completion.started_at or completion.finished_at > utcnow():
        raise _invalid("完成时间必须在开始之后，且不能在未来")
    if body.occurred_at is not None and body.occurred_at != completion.finished_at:
        raise _invalid("记录时间和完成时间不一致")
    frozen = body.snapshot or {}
    detail = frozen.get("detail")
    version = detail.get("version") if isinstance(detail, dict) else None
    if (
        frozen.get("format_version") != 1
        or frozen.get("recipe_id") != str(body.recipe_id)
        or frozen.get("version_id") != str(body.recipe_version_id)
        or not isinstance(detail, dict)
        or detail.get("id") != str(body.recipe_id)
        or not isinstance(version, dict)
        or version.get("id") != str(body.recipe_version_id)
    ):
        raise _invalid("执行快照和精确版本不一致")
    try:
        executed = RecipeSnapshot.model_validate(version.get("snapshot"))
    except ValidationError as exc:
        raise _invalid("执行快照不完整") from exc
    expected = execution_token(owner_id, body.recipe_version_id, executed, settings)
    if not hmac.compare_digest(expected, completion.execution_token):
        raise _invalid("执行快照不是本账号从服务端取得的这一版做法")
    step_ids = {step.id for step in executed.steps}
    completed = set(completion.completed_steps)
    skipped = set(completion.skipped_steps)
    reached = set(completion.reached_steps)
    if (
        not step_ids
        or len(completed) != len(completion.completed_steps)
        or len(skipped) != len(completion.skipped_steps)
        or len(reached) != len(completion.reached_steps)
        or completed.intersection(skipped)
        or completed.union(skipped) != step_ids
        or not completed.issubset(reached)
        or not reached.issubset(step_ids)
    ):
        raise _invalid("需要完成或明确跳过每个真实步骤，不能重复或引用其他步骤")
    executed_value, available = _apply_adjustments(executed, body.adjustments)
    context = deepcopy(body.source_context)
    context.update(completion.model_dump(mode="json", exclude={"execution_token"}))
    context.update(
        server_completed=bool(completed),
        executed_snapshot=executed_value,
        derivation_available=available and not skipped,
    )
    # Full coverage preserves the session, but skipping everything proves no cooking.
    return "cooking_mode" if completed else "unverified", context


def _apply_adjustments(
    snapshot: RecipeSnapshot, adjustments: list[dict[str, Any]]
) -> tuple[dict[str, Any], bool]:
    result = snapshot.model_dump(mode="json")
    available = True
    ingredients = {item["id"]: item for item in result["ingredients"]}
    steps = {step["id"]: step for step in result["steps"]}
    for adjustment in adjustments:
        if "ingredient_id" in adjustment and "quantity" in adjustment:
            item = ingredients.get(adjustment["ingredient_id"])
            if item is None or adjustment.get("unit", item["unit"]) != item["unit"]:
                raise _invalid("临场用量必须关联真实食材并沿用原单位")
            quantity = adjustment["quantity"]
            if isinstance(quantity, bool) or not isinstance(quantity, (int, float)):
                raise _invalid("临场用量必须是数值")
            item["quantity"] = quantity
            item["base_quantity"] = None
            item["base_unit"] = None
            item["quantity_source"] = {"source": "author_filled", "basis": "临场调整"}
        elif "step_id" in adjustment and isinstance(adjustment.get("fields"), dict):
            step = steps.get(adjustment["step_id"])
            fields = adjustment["fields"]
            if (
                step is None
                or not fields
                or not set(fields).issubset(
                    {
                        "instruction",
                        "action",
                        "heat",
                        "duration_seconds",
                        "temperature_celsius",
                        "cookware",
                        "doneness",
                    }
                )
            ):
                raise _invalid("临场步骤修改必须关联真实步骤与可编辑字段")
            step.update(fields)
        else:
            # Free text is retained in the record, but cannot attest a precise
            # recipe. Do not guess quantities or discard a recorded adjustment.
            available = False
    try:
        value = RecipeSnapshot.model_validate(result).model_dump(mode="json")
    except ValidationError as exc:
        raise _invalid("临场改动超出菜谱字段范围") from exc
    return value, available
