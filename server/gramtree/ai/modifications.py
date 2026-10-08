"""Finite, server-owned edits shared by authoring and unsaved generation results."""

import json
import logging
import uuid
from typing import Any

from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway
from gramtree.ai import service as generation
from gramtree.ai.models import GenerationRequest, RecipeModification
from gramtree.ai.modification_schemas import (
    ModificationConfirmInput,
    ModificationDecision,
    ModificationDecisionOut,
    ModificationDecisionsInput,
    ModificationInput,
    ModificationIntent,
    ModificationOperation,
    ModificationOutput,
    ModificationPreview,
)
from gramtree.ai.schemas import AIStatus, GeneratedDraft
from gramtree.core.errors import ApiError, NotFound
from gramtree.core.time import utcnow
from gramtree.events import service as events
from gramtree.events.registry import RecipeModificationContentV1
from gramtree.recipes import food_safety, reproducibility
from gramtree.recipes import service as recipes
from gramtree.recipes.models import RecipeVersion
from gramtree.recipes.schemas import RecipeSnapshot, RecipeVersionCreate, ValueSource
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.ai.modifications")
TEXT_FIELDS = {
    "change_step_field": ("steps", {"instruction", "action", "doneness", "notes", "why"}),
    "change_preparation": ("ingredients", {"preparation"}),
    "change_display_name": ("ingredients", {"display_name"}),
    "change_recipe_info": ("snapshot", {"description"}),
}
SOURCE_FIELDS = {
    "instruction": "instruction_source",
    "doneness": "doneness_source",
    "preparation": "preparation_source",
    "display_name": "quantity_source",
    "description": "text_source",
}


def _target(session: Session, owner: User, body: ModificationInput) -> dict[str, Any]:
    if body.recipe_id is not None and body.base_version_id is not None:
        recipe, version = recipes._owned_version(
            session, owner, body.recipe_id, body.base_version_id
        )
        if recipe.current_version_id != version.id:
            raise ApiError(409, "stale_modification", "菜谱已有新版本，请重新提出修改")
        from gramtree.recipes.models import Dish, DishAlias

        dish = session.get(Dish, recipe.dish_id)
        if dish is None:
            raise NotFound()
        return {
            "snapshot": version.snapshot,
            "dish_name": dish.name,
            "dish_aliases": list(
                session.scalars(select(DishAlias.alias).where(DishAlias.dish_id == dish.id))
            ),
        }
    row = session.scalar(
        select(GenerationRequest)
        .where(
            GenerationRequest.id == body.generation_request_id,
            GenerationRequest.user_id == owner.id,
        )
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if row is None:
        raise NotFound()
    if row.saved_recipe_id:
        raise ApiError(409, "generation_already_saved", "这份生成结果已经保存")
    if not row.draft:
        raise ApiError(409, "generation_required", "请先生成菜谱")
    draft = GeneratedDraft.model_validate(row.draft)
    return {
        "snapshot": draft.recipe.snapshot.model_dump(mode="json"),
        "dish_name": draft.recipe.dish_input().name,
        "dish_aliases": draft.recipe.dish_input().aliases,
        "draft": row.draft,
    }


def _owned(session: Session, owner: User, request_id: uuid.UUID) -> RecipeModification:
    row = session.scalar(
        select(RecipeModification)
        .where(RecipeModification.id == request_id, RecipeModification.user_id == owner.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if row is None:
        raise NotFound()
    return row


def _fresh(session: Session, owner: User, row: RecipeModification) -> None:
    baseline = _target(session, owner, ModificationInput.model_validate(row.request))
    if baseline != row.baseline:
        raise ApiError(409, "stale_modification", "基准内容已更新，请重新提出修改")


def _node(snapshot: RecipeSnapshot, op: ModificationOperation):
    collection, fields = TEXT_FIELDS[op.type]
    if op.field not in fields or (collection == "snapshot" and op.id is not None):
        raise ValueError("操作字段未登记")
    if collection == "snapshot":
        return snapshot
    node = next((n for n in getattr(snapshot, collection) if n.id == op.id), None)
    if node is None:
        raise ValueError("操作目标不存在")
    return node


def _validate_operations(snapshot: RecipeSnapshot, ops: list[ModificationOperation]) -> None:
    by_id = {op.operation_id: op for op in ops}
    if len(by_id) != len(ops):
        raise ValueError("操作标识重复")
    targets = set()
    for op in ops:
        node = _node(snapshot, op)
        target = (TEXT_FIELDS[op.type][0], op.id, op.field)
        if target in targets:
            raise ValueError("同一字段只能提出一条操作")
        targets.add(target)
        if getattr(node, op.field) != op.before:
            raise ValueError("操作前值与基准不一致")
        if op.after == op.before:
            raise ValueError("操作没有改动")
        if len(op.depends_on) != len(set(op.depends_on)) or any(
            d not in by_id for d in op.depends_on
        ):
            raise ValueError("操作依赖不存在或重复")
    visiting, visited = set(), set()

    def visit(key):
        if key in visiting:
            raise ValueError("操作依赖形成循环")
        if key in visited:
            return
        visiting.add(key)
        for dependency in by_id[key].depends_on:
            visit(dependency)
        visiting.remove(key)
        visited.add(key)

    for key in by_id:
        visit(key)


def _apply(
    snapshot: RecipeSnapshot, ops: list[ModificationOperation], choices: list[ModificationDecision]
):
    _validate_operations(snapshot, ops)
    requested = {d.operation_id: d for d in choices}
    if len(requested) != len(choices) or set(requested) - {op.operation_id for op in ops}:
        raise ValueError("未知或重复的操作决定")
    resolved: dict[str, ModificationDecisionOut] = {}
    by_id = {op.operation_id: op for op in ops}

    def resolve(op):
        if op.operation_id in resolved:
            return resolved[op.operation_id]
        blocked = [key for key in op.depends_on if resolve(by_id[key]).decision == "reject"]
        pending = [key for key in op.depends_on if resolve(by_id[key]).decision == "pending"]
        choice = requested.get(op.operation_id)
        decision = (
            "reject"
            if blocked
            else "pending"
            if pending
            else choice.decision
            if choice
            else "pending"
        )
        after = (
            op.before
            if decision in ("reject", "pending")
            else choice.after
            if choice and decision == "modify"
            else op.after
        )
        result = ModificationDecisionOut(
            operation_id=op.operation_id, decision=decision, after=after, blocked_by=blocked
        )
        resolved[op.operation_id] = result
        return result

    result = snapshot.model_copy(deep=True)
    accepted = []
    for op in ops:
        decision = resolve(op)
        if decision.decision in ("reject", "pending"):
            continue
        if decision.after == op.before:
            continue
        node = _node(result, op)
        setattr(node, op.field, decision.after)
        source_field = SOURCE_FIELDS.get(op.field)
        if source_field:
            setattr(
                node,
                source_field,
                ValueSource(source="author_filled")
                if decision.decision == "modify"
                else ValueSource(
                    source="ai_estimated",
                    original=op.before,
                    basis=op.reason,
                    confidence=op.confidence,
                ),
            )
        accepted.append(
            {
                **op.model_dump(mode="json"),
                "after": decision.after,
                "source": "ai_estimated",
                "decision": decision.decision,
            }
        )
    return (
        RecipeSnapshot.model_validate(result.model_dump(mode="json")),
        [resolved[op.operation_id] for op in ops],
        accepted,
    )


def _state(session, row):
    snapshot = RecipeSnapshot.model_validate(row.baseline["snapshot"])
    ops = [ModificationOperation.model_validate(op) for op in row.proposal.get("operations", [])]
    # Saved decisions are canonical request data, not derived rejection state.
    choices = [ModificationDecision.model_validate(d) for d in row.decisions]
    changed, decisions, accepted = _apply(snapshot, ops, choices)
    return recipes._validate_snapshot(session, changed), ops, decisions, accepted


def preview(
    session: Session, settings: Settings, owner: User, row: RecipeModification
) -> ModificationPreview:
    changed, ops, decisions, _ = _state(session, row)
    return ModificationPreview(
        id=row.id,
        revision=row.revision,
        recipe_id=row.recipe_id,
        base_version_id=row.base_version_id,
        generation_request_id=row.generation_request_id,
        intent=row.proposal.get("intent"),
        operations=ops,
        decisions=decisions,
        snapshot=changed,
        safety=food_safety.check(
            session, changed, row.baseline["dish_name"], descriptions=row.baseline["dish_aliases"]
        ),
        reproducibility=reproducibility.check(changed),
        status=AIStatus.model_validate(gateway.availability(session, settings, owner.id, "modify")),
        warnings=row.proposal.get("warnings", []),
        error=row.error,
    )


def get(session, settings, owner, request_id):
    row = _owned(session, owner, request_id)
    if not row.saved_version_id:
        _fresh(session, owner, row)
    return preview(session, settings, owner, row)


def _event(session, redis, owner, row, stage, decisions=None, version=None):
    content = RecipeModificationContentV1(
        request_id=str(row.id),
        stage=stage,
        intent=row.proposal.get("intent"),
        proposed_operations=row.proposal.get("operations", []),
        decisions=[d.model_dump(mode="json") for d in (decisions or [])],
        saved_version_id=str(version.id) if version else None,
    )
    event = events.EventInput(
        id=uuid.uuid5(row.id, f"{stage}:{row.revision}"),
        event_type="ai.recipe_modification",
        type_version=1,
        device_id="server",
        device_time=row.created_at,
        app_version="server",
        correlation={"recipe_version_id": str(version.id)} if version else {},
        content=content.model_dump(mode="json"),
    )
    events.upload(session, redis, owner.id, [event], utcnow(), commit=False)


def propose(
    session: Session, redis: Redis, settings: Settings, owner: User, body: ModificationInput
) -> ModificationPreview:
    canonical = body.model_dump(mode="json", exclude={"request_id"})
    if body.request_id:
        existing = session.get(RecipeModification, body.request_id)
        if existing:
            if existing.user_id != owner.id:
                raise NotFound()
            if existing.request != canonical:
                raise ApiError(409, "modification_request_conflict", "请求标识已用于另一项修改")
            return get(session, settings, owner, existing.id)
    baseline = _target(session, owner, body)
    row = RecipeModification(
        id=body.request_id or uuid.uuid4(),
        user_id=owner.id,
        recipe_id=body.recipe_id,
        base_version_id=body.base_version_id,
        generation_request_id=body.generation_request_id,
        request=canonical,
        baseline=baseline,
    )
    session.add(row)
    session.commit()
    proposal: dict[str, Any] = {}
    try:
        raw = gateway.call(
            session,
            settings,
            owner.id,
            "modify_intent",
            {"text": body.text},
            row.id,
            content_id=body.base_version_id or body.generation_request_id,
        )
        intent = ModificationIntent.model_validate(json.loads(raw) if isinstance(raw, str) else raw)
        proposal["intent"] = intent.model_dump(mode="json")
        if intent.category == "unknown" or intent.confidence < 0.7:
            row.error = "uncertain_intent"
        elif intent.category != "text":
            row.error = "unsupported_intent"
        else:
            payload = {
                "text": body.text,
                "snapshot": baseline["snapshot"],
                "intent": proposal["intent"],
            }
            for repair in range(2):
                raw = gateway.call(
                    session,
                    settings,
                    owner.id,
                    "modify",
                    payload,
                    row.id,
                    content_id=body.base_version_id or body.generation_request_id,
                )
                try:
                    value = json.loads(raw) if isinstance(raw, str) else raw
                    if not isinstance(value, dict):
                        raise ValueError("需要 operations 列表")
                    warnings = (
                        ["unreferenced_fields_dropped"] if set(value) - {"operations"} else []
                    )
                    if warnings:
                        logger.warning(
                            "discarded unreferenced model fields",
                            extra={"modification_id": str(row.id)},
                        )
                    output = ModificationOutput.model_validate(
                        {"operations": value.get("operations")}
                    )
                    changed, _, _ = _apply(
                        RecipeSnapshot.model_validate(baseline["snapshot"]),
                        output.operations,
                        [
                            ModificationDecision(operation_id=op.operation_id, decision="accept")
                            for op in output.operations
                        ],
                    )
                    recipes._validate_snapshot(session, changed)
                    proposal.update(output.model_dump(mode="json"))
                    proposal["warnings"] = warnings
                    row.error = None
                    break
                except (ValueError, TypeError, ApiError) as exc:
                    if repair:
                        raise gateway.Unavailable("invalid_output") from exc
                    # Stable repair input is useful for exact replay; validation details
                    # stay in logs and are not echoed as potentially private field values.
                    payload = {
                        **payload,
                        "repair": {"errors": ["invalid_operations"], "previous": raw},
                    }
    except gateway.Unavailable as exc:
        row.error = exc.reason
    except (ValueError, TypeError) as exc:
        logger.warning("invalid modification intent", exc_info=exc)
        row.error = "invalid_output"
    _fresh(session, owner, row)  # Gateway accounting commits release ownership locks.
    row.proposal = proposal
    _event(session, redis, owner, row, "proposed")
    session.commit()
    return preview(session, settings, owner, row)


def decide(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    request_id: uuid.UUID,
    body: ModificationDecisionsInput,
):
    row = _owned(session, owner, request_id)
    if row.saved_version_id:
        raise ApiError(409, "modification_already_saved", "这批修改已经保存")
    _fresh(session, owner, row)
    if row.error:
        raise ApiError(409, "modification_not_ready", "没有可确认的修改建议", row.error)
    try:
        _, ops, _, _ = _state(session, row)
        changed, decisions, _ = _apply(
            RecipeSnapshot.model_validate(row.baseline["snapshot"]), ops, body.decisions
        )
        recipes._validate_snapshot(session, changed)
    except (ValueError, TypeError) as exc:
        raise ApiError(422, "invalid_modification_decision", "修改值或操作决定有误") from exc
    canonical = [d.model_dump(mode="json", exclude_unset=True) for d in body.decisions]
    if row.decisions != canonical:
        row.decisions = canonical
        row.revision += 1
        _event(session, redis, owner, row, "decided", decisions)
        session.commit()
    return preview(session, settings, owner, row)


def confirm(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    request_id: uuid.UUID,
    body: ModificationConfirmInput,
):
    row = _owned(session, owner, request_id)
    canonical = body.model_dump(mode="json")
    if row.saved_version_id:
        if row.confirmation != canonical:
            raise ApiError(409, "modification_already_saved", "这批修改已经保存")
        version = session.get(RecipeVersion, row.saved_version_id)
        if version is None:
            raise NotFound()
        return recipes.get_version(session, settings, owner, version.recipe_id, version.id)
    _fresh(session, owner, row)
    if row.error:
        raise ApiError(409, "modification_not_ready", "没有可确认的修改建议", row.error)
    if row.confirmation:
        raise ApiError(409, "modification_already_saved", "这批修改已经保存")
    if row.revision != body.revision:
        raise ApiError(409, "stale_modification_decisions", "选择已更新，请核对最新预览")
    changed, _, decisions, accepted = _state(session, row)
    if any(d.decision == "pending" for d in decisions):
        raise ApiError(409, "modification_decisions_required", "请逐条处理修改建议后再确认")
    accepted = [op for op in accepted if op["before"] != op["after"]]
    if row.recipe_id and not accepted:
        raise ApiError(409, "no_modifications", "没有实际改动，不需要保存新版本")
    # Re-run with current rules and the actual confirmation note; never trust a
    # previous preview's safety receipt, nor require completeness for private save.
    safety = food_safety.check(
        session,
        changed,
        row.baseline["dish_name"],
        descriptions=[*row.baseline["dish_aliases"], body.change_note],
    )
    if not safety.can_save:
        raise ApiError(422, "prohibited_health_claim", "请改写疗效类措辞后再保存")
    if row.generation_request_id and safety.high_risk:
        raise ApiError(422, "unsafe_ai_output", "AI 辅助菜谱不能保存高风险食材")

    def receipt(version):
        row.saved_version_id = version.id
        row.confirmation = canonical
        _event(session, redis, owner, row, "saved", decisions, version)

    if row.recipe_id:
        create = RecipeVersionCreate.model_construct(
            snapshot=changed,
            base_version_id=row.base_version_id,
            expected_current_version_id=row.base_version_id,
            ai_assisted=True,
            change_note=body.change_note,
            image_ids=[],
        )
        return recipes.save_version(
            session,
            redis,
            settings,
            owner,
            row.recipe_id,
            create,
            trusted_sources=True,
            confirmed_operations=accepted,
            before_commit=receipt,
        )
    if row.generation_request_id is None:
        raise NotFound()
    draft = GeneratedDraft.model_validate(row.baseline["draft"])
    create = draft.recipe.model_copy(deep=True)
    create.snapshot = changed
    create.change_note = body.change_note
    return generation.save(
        session,
        redis,
        settings,
        owner,
        row.generation_request_id,
        create,
        confirmed_operations=accepted,
        before_commit=receipt,
    )
