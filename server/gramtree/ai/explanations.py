"""Pre-save descriptions from canonical edits, independent of recipe persistence."""

import hashlib
import json
import re
import uuid
from dataclasses import dataclass
from typing import Any

from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway, modifications
from gramtree.ai import service as generation
from gramtree.ai.explanation_schemas import (
    ChangeExplanationInput,
    ChangeExplanationOutput,
    ChangeExplanationResult,
)
from gramtree.ai.schemas import AIStatus, GeneratedDraft
from gramtree.core.errors import ApiError
from gramtree.recipes import food_safety
from gramtree.recipes import service as recipes
from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.settings import Settings

# Labels are editable explanation output, not evidence of a recipe change.
# Derived base amounts and provenance are likewise not additional author edits.
_EXCLUDED_FIELDS = {"tags", "base_quantity", "base_unit"}
_FACT_FIELDS = {"type", "id", "field", "before", "after", "intent"}
_VERIFICATION_CLAIM = re.compile(
    r"验证|已做过|实测|亲测|证实|保证|verified|validated|tested|proven|guaranteed",
    re.IGNORECASE,
)


def _json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _fact_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            k: _fact_value(v)
            for k, v in value.items()
            if not k.endswith("_source") and k not in {"base_quantity", "base_unit"}
        }
    if isinstance(value, list):
        return [_fact_value(item) for item in value]
    return value


def facts(operations: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Stable whitelist shared by prompt grounding and save-time freshness checks."""
    result = []
    for operation in operations:
        if operation.get("field") in _EXCLUDED_FIELDS:
            continue
        if (
            "before" in operation
            and "after" in operation
            and operation["before"] == operation["after"]
        ):
            continue
        result.append({k: _fact_value(v) for k, v in operation.items() if k in _FACT_FIELDS})
    return sorted(result, key=_json)


def fingerprint(
    owner_id: uuid.UUID, target: dict[str, Any], operations: list[dict[str, Any]]
) -> str:
    return hashlib.sha256(
        _json(
            {"owner_id": str(owner_id), "target": target, "operations": facts(operations)}
        ).encode()
    ).hexdigest()


def manual_target(recipe_id: uuid.UUID, base_version_id: uuid.UUID) -> dict[str, Any]:
    return {"recipe_id": str(recipe_id), "base_version_id": str(base_version_id)}


def generation_target(request_id: uuid.UUID) -> dict[str, Any]:
    return {"generation_request_id": str(request_id)}


def validate_fingerprint(
    owner_id: uuid.UUID,
    target: dict[str, Any],
    operations: list[dict[str, Any]],
    supplied: str | None,
) -> None:
    if supplied is not None and supplied != fingerprint(owner_id, target, operations):
        raise ApiError(409, "stale_change_explanation", "改动已变化，请重新生成说明或手写后保存")


def validate_modification_fingerprint(
    owner_id: uuid.UUID,
    request_id: uuid.UUID,
    revision: int,
    operations: list[dict[str, Any]],
    supplied: str | None,
) -> None:
    validate_fingerprint(
        owner_id,
        {"modification_id": str(request_id), "revision": revision},
        operations,
        supplied,
    )


@dataclass
class ChangeFacts:
    target: dict[str, Any]
    snapshot: RecipeSnapshot
    operations: list[dict[str, Any]]
    content_id: uuid.UUID


def _changes(
    session: Session, settings: Settings, owner: User, body: ChangeExplanationInput
) -> ChangeFacts:
    if body.modification_id is not None:
        row = modifications._owned(session, owner, body.modification_id)
        if row.saved_version_id:
            raise ApiError(409, "modification_already_saved", "这批修改已经保存")
        modifications._fresh(session, owner, row)
        if row.error:
            raise ApiError(409, "modification_not_ready", "没有可确认的修改建议", row.error)
        if row.revision != body.revision:
            raise ApiError(409, "stale_modification_decisions", "选择已更新，请核对最新预览")
        snapshot, _, decisions, accepted = modifications._state(session, row)
        if any(d.decision == "pending" for d in decisions):
            raise ApiError(409, "modification_decisions_required", "请逐条处理修改建议后再生成说明")
        return ChangeFacts(
            {"modification_id": str(row.id), "revision": row.revision},
            snapshot,
            accepted,
            row.id,
        )
    if body.snapshot is None:
        raise ValueError("需要新快照")
    if body.generation_request_id is not None:
        snapshot = recipes._validate_snapshot(session, body.snapshot, owner.id, settings=settings)
        row = generation.owned_request(session, owner, body.generation_request_id)
        if row.saved_recipe_id:
            raise ApiError(409, "generation_already_saved", "这份生成结果已经保存")
        if not row.draft:
            raise ApiError(409, "generation_required", "请先生成菜谱")
        previous = GeneratedDraft.model_validate(row.draft).recipe.snapshot
        return ChangeFacts(
            generation_target(row.id), snapshot, recipes._operations(previous, snapshot), row.id
        )
    if body.recipe_id is None or body.base_version_id is None:
        raise ValueError("需要菜谱基准")
    _, version = recipes._owned_version(session, owner, body.recipe_id, body.base_version_id)
    previous = RecipeSnapshot.model_validate(version.snapshot)
    snapshot = recipes._prepare_version_snapshot(
        session, body.snapshot, previous, owner.id, settings=settings
    )
    return ChangeFacts(
        manual_target(body.recipe_id, version.id),
        snapshot,
        recipes._operations(previous, snapshot),
        version.id,
    )


def _validate_output(session: Session, changes: ChangeFacts, value: Any) -> ChangeExplanationOutput:
    output = (
        ChangeExplanationOutput.model_validate_json(value)
        if isinstance(value, str)
        else ChangeExplanationOutput.model_validate(value)
    )
    # An explanation is not cooking evidence, even when the supplied edits contain
    # a request to claim verification. Fail closed instead of inventing provenance.
    if _VERIFICATION_CLAIM.search(" ".join([output.change_note, *output.tags])):
        raise ValueError("说明不能声称已验证")
    result = food_safety.check(
        session,
        changes.snapshot.model_copy(update={"tags": output.tags}),
        descriptions=[output.change_note],
    )
    if not result.can_save:
        raise ValueError("说明不能包含疗效声明")
    return output


def explain(
    session: Session, settings: Settings, owner: User, body: ChangeExplanationInput
) -> ChangeExplanationResult:
    changes = _changes(session, settings, owner, body)
    binding = fingerprint(owner.id, changes.target, changes.operations)
    operations = facts(changes.operations)
    status = AIStatus.model_validate(
        gateway.availability(session, settings, owner.id, "change_explanation")
    )
    if not operations:
        return ChangeExplanationResult(
            status=status, changes_fingerprint=binding, error="no_changes"
        )
    payload = {"operations": operations}
    operation_id = uuid.uuid4()
    try:
        for repair in range(2):
            raw = gateway.call(
                session,
                settings,
                owner.id,
                "change_explanation",
                payload,
                operation_id,
                content_id=changes.content_id,
            )
            try:
                output = _validate_output(session, changes, raw)
                break
            except (ValueError, TypeError) as exc:
                if repair:
                    raise gateway.Unavailable("invalid_output") from exc
                payload = {
                    **payload,
                    "repair": {"errors": ["invalid_explanation"], "previous": raw},
                }
        else:
            raise gateway.Unavailable("invalid_output")
        # Gateway accounting commits release locks. Re-resolve the canonical
        # decisions/baseline so a late response cannot be adopted for newer edits.
        session.expire_all()
        fresh = _changes(session, settings, owner, body)
        validate_fingerprint(owner.id, fresh.target, fresh.operations, binding)
        return ChangeExplanationResult(
            status=AIStatus.model_validate(
                gateway.availability(session, settings, owner.id, "change_explanation")
            ),
            change_note=output.change_note,
            tags=output.tags,
            source="ai_estimated",
            changes_fingerprint=binding,
        )
    except gateway.Unavailable as exc:
        status = AIStatus.model_validate(
            gateway.availability(session, settings, owner.id, "change_explanation")
        )
        status.available = False
        status.reason = exc.reason
        return ChangeExplanationResult(status=status, changes_fingerprint=binding, error=exc.reason)
