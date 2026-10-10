"""Finite, server-owned edits shared by authoring and unsaved generation results."""

import json
import logging
import uuid
from typing import Any

from pydantic import TypeAdapter
from redis import Redis
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
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
from gramtree.recipes.schemas import (
    RecipeIngredient,
    RecipeSnapshot,
    RecipeStep,
    RecipeVersionCreate,
    ValueSource,
)
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.ai.modifications")
TEXT_FIELDS = {
    "change_step_field": ("steps", {"instruction", "action", "doneness", "notes", "why"}),
    "change_preparation": ("ingredients", {"preparation"}),
    "change_display_name": ("ingredients", {"display_name"}),
    "change_recipe_info": ("snapshot", {"description"}),
}
REGISTERED_FIELDS = {
    **TEXT_FIELDS,
    "change_step_field": (
        "steps",
        {*TEXT_FIELDS["change_step_field"][1], "cookware", "unattended"},
    ),
    "change_step_duration": ("steps", {"duration_seconds"}),
    "change_step_heat": ("steps", {"heat", "temperature_celsius"}),
    "change_step_ingredients": ("steps", {"ingredient_ids"}),
    "change_step_dependencies": ("steps", {"depends_on"}),
    "replace_ingredient": ("ingredients", {"ingredient_id"}),
    "change_quantity": ("ingredients", {"quantity", "unit"}),
    "change_group_or_optional": ("ingredients", {"group", "optional"}),
    "change_functional": ("ingredients", {"functional"}),
    "change_scaling": ("ingredients", {"scaling_mode"}),
    "change_replacement": ("ingredients", {"replacement"}),
    "change_recipe_info": (
        "snapshot",
        {
            "servings",
            "base_mold",
            "difficulty",
            "dish_type",
            "description",
            "tags",
            "total_time_seconds",
            "active_time_seconds",
        },
    ),
}
STRUCTURAL_FIELDS = {
    "add_ingredient": "ingredients",
    "remove_ingredient": "ingredients",
    "add_step": "steps",
    "remove_step": "steps",
    "reorder_ingredients": "ingredients",
    "reorder_steps": "steps",
}
SOURCE_FIELDS = {
    "instruction": "instruction_source",
    "doneness": "doneness_source",
    "preparation": "preparation_source",
    "display_name": "quantity_source",
    "description": "text_source",
    "duration_seconds": "duration_source",
    "heat": "heat_source",
    "temperature_celsius": "temperature_source",
    "ingredient_id": "quantity_source",
    "quantity": "quantity_source",
    "unit": "quantity_source",
    "servings": "servings_source",
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
    collection, fields = REGISTERED_FIELDS[op.type]
    if op.field not in fields or (collection == "snapshot" and op.id is not None):
        raise ValueError("操作字段未登记")
    if collection == "snapshot":
        return snapshot
    node = next((n for n in getattr(snapshot, collection) if n.id == op.id), None)
    if node is None:
        raise ValueError("操作目标不存在")
    return node


def _operation_value(snapshot: RecipeSnapshot, op: ModificationOperation):
    collection = STRUCTURAL_FIELDS.get(op.type)
    if collection is None:
        return _node(snapshot, op).model_dump(mode="json")[op.field]
    if op.field != collection:
        raise ValueError("结构操作字段未登记")
    items = getattr(snapshot, collection)
    if op.type.startswith("reorder_"):
        if op.id is not None:
            raise ValueError("排序不得指定单个目标")
        return [item.id for item in items]
    if not op.id:
        raise ValueError("加删需要稳定的目标 ID")
    node = next((item for item in items if item.id == op.id), None)
    return node.model_dump(mode="json") if node is not None else None


def _source(op: ModificationOperation, decision: ModificationDecisionOut) -> ValueSource:
    if decision.decision == "modify":
        return ValueSource(source="author_filled")
    return ValueSource(
        source="ai_estimated",
        original=op.before
        if isinstance(op.before, str) or op.before is None
        else json.dumps(op.before, ensure_ascii=False),
        basis=op.reason,
        confidence=op.confidence,
    )


def _new_node(op: ModificationOperation, decision: ModificationDecisionOut):
    model = RecipeStep if op.type == "add_step" else RecipeIngredient
    node = model.model_validate_json(json.dumps(decision.after, ensure_ascii=False), strict=True)
    if node.id != op.id:
        raise ValueError("新增目标 ID 不得改变")
    for field in type(node).model_fields:
        if field.endswith("_source"):
            existing = getattr(node, field)
            if existing is not None and existing.source == "verified":
                raise ValueError("模型或作者不能创建已验证证据")
            setattr(node, field, _source(op, decision))
    return node


def _validate_operations(snapshot: RecipeSnapshot, ops: list[ModificationOperation]) -> None:
    by_id = {op.operation_id: op for op in ops}
    if len(by_id) != len(ops):
        raise ValueError("操作标识重复")
    targets = set()
    for op in ops:
        collection = STRUCTURAL_FIELDS.get(op.type) or REGISTERED_FIELDS[op.type][0]
        target = (collection, op.id, op.field)
        if target in targets:
            raise ValueError("同一字段只能提出一条操作")
        targets.add(target)
        before = _operation_value(snapshot, op)
        if before != op.before:
            raise ValueError("操作前值与基准不一致")
        if op.type.startswith("add_") and (before is not None or op.before is not None):
            raise ValueError("新增目标已存在")
        if op.type.startswith("remove_") and (before is None or op.after is not None):
            raise ValueError("删除目标不存在或后值不是空值")
        if (
            op.type == "change_recipe_info"
            and op.field in ("total_time_seconds", "active_time_seconds")
            and (type(op.after) is not int or op.after != 0)
        ):
            raise ValueError("AI 不能编造总时长，只能恢复服务端派生")
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
    _validate_reference_dependencies(snapshot, ops)


def _validate_reference_dependencies(snapshot, ops):
    by_id = {op.operation_id: op for op in ops}

    def depends(op, prerequisite):
        return prerequisite.operation_id in op.depends_on or any(
            depends(by_id[key], prerequisite) for key in op.depends_on
        )

    additions = {
        (STRUCTURAL_FIELDS[op.type], op.id): op for op in ops if op.type.startswith("add_")
    }
    removals = {
        (STRUCTURAL_FIELDS[op.type], op.id): op for op in ops if op.type.startswith("remove_")
    }
    for op in ops:
        if op.type.startswith("remove_"):
            collection = STRUCTURAL_FIELDS[op.type]
            if any(
                other.id == op.id
                and other is not op
                and other.type in REGISTERED_FIELDS
                and REGISTERED_FIELDS[other.type][0] == collection
                for other in ops
            ):
                raise ValueError("删除目标不能同时修改其字段")
            field = "ingredient_ids" if collection == "ingredients" else "depends_on"
            kind = (
                "change_step_ingredients"
                if collection == "ingredients"
                else "change_step_dependencies"
            )
            for step in snapshot.steps:
                if op.id not in getattr(step, field):
                    continue
                cleanup = next(
                    (
                        other
                        for other in ops
                        if other.id == step.id
                        and (
                            other.type == "remove_step"
                            or (
                                other.type == kind
                                and isinstance(other.after, list)
                                and op.id not in other.after
                            )
                        )
                    ),
                    None,
                )
                if cleanup is None or not depends(op, cleanup):
                    raise ValueError("删除必须依赖引用清理")
        if op.type.startswith("reorder_"):
            collection = STRUCTURAL_FIELDS[op.type]
            for (changed_collection, _), dependency in {**additions, **removals}.items():
                if collection == changed_collection and not depends(op, dependency):
                    raise ValueError("排序必须依赖加删操作")
        references = {}
        if op.type == "add_step" and isinstance(op.after, dict):
            references = {
                "ingredients": op.after.get("ingredient_ids", []),
                "steps": op.after.get("depends_on", []),
            }
        elif op.type in ("change_step_ingredients", "change_step_dependencies"):
            references = {"ingredients" if op.field == "ingredient_ids" else "steps": op.after}
        for collection, ids in references.items():
            if not isinstance(ids, list):
                raise ValueError("引用必须为 ID 列表")
            for item_id in ids:
                if not isinstance(item_id, str):
                    raise ValueError("引用需要字符串 ID")
                prerequisite = additions.get((collection, item_id))
                if prerequisite is not None and not depends(op, prerequisite):
                    raise ValueError("引用必须依赖新增目标")


def _validate_intent_operations(
    snapshot: RecipeSnapshot, intent: ModificationIntent, ops: list[ModificationOperation]
) -> None:
    if intent.category == "text":
        if any(op.type not in TEXT_FIELDS or op.field not in TEXT_FIELDS[op.type][1] for op in ops):
            raise ValueError("改文字不得改变烹饪条件")
        return
    by_id = {op.operation_id: op for op in ops}

    def ancestors(op):
        return set(op.depends_on).union(*(ancestors(by_id[key]) for key in op.depends_on))

    if intent.category in ("time_difficulty", "method"):
        if any(op.field == "cookware" for op in ops):
            raise ValueError("已有步骤换厨具必须走换厨具意图")
        for op in ops:
            if op.type != "change_step_duration":
                continue
            for cause in ops:
                if (
                    cause.id == op.id
                    and cause.type == "change_step_field"
                    and cause.field == "instruction"
                    and cause.operation_id not in ancestors(op)
                ):
                    raise ValueError("时长必须依赖同时改变的步骤说明")
    if intent.category != "cookware" or not ops:
        return
    if any(op.type in STRUCTURAL_FIELDS for op in ops):
        raise ValueError("换厨具不得改动步骤结构")
    target = intent.parameters.get("target_cookware")
    if not isinstance(target, str) or not target.strip():
        raise ValueError("缺少目标厨具")
    roots = {op.id: op for op in ops if op.field == "cookware"}
    if not roots:
        raise ValueError("换厨具需要明确步骤")
    affected = intent.parameters.get("step_ids")
    if affected is not None and (
        not isinstance(affected, str) or set(affected.split(",")) != set(roots)
    ):
        raise ValueError("受影响步骤不一致")
    for step_id, root in roots.items():
        if root.after != target:
            raise ValueError("厨具与请求目标不一致")
        changes = {op.field: op for op in ops if op.id == step_id}
        if not {"instruction", "notes", "doneness"}.issubset(changes):
            raise ValueError("转换需要步骤、容器要求和成熟判断")
        for field in ("instruction", "notes", "doneness"):
            value = changes[field].after
            if not isinstance(value, str) or not value.strip():
                raise ValueError("转换需要明确的步骤、容器要求和成熟判断")
        step = next(step for step in snapshot.steps if step.id == step_id)
        for field in ("duration_seconds", "temperature_celsius"):
            value = changes[field].after if field in changes else getattr(step, field)
            if isinstance(value, bool) or not isinstance(value, (int, float)) or value <= 0:
                raise ValueError("转换需要明确的时间和温度")
        if step.heat is not None and "heat" not in changes:
            raise ValueError("转换需要重新说明火候")
    for op in ops:
        root = roots.get(op.id)
        if REGISTERED_FIELDS[op.type][0] != "steps" or root is None:
            raise ValueError("厨具转换不得更改无关字段")
        if op is not root and root.operation_id not in ancestors(op):
            raise ValueError("烹饪条件必须依赖厨具转换")


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
            if blocked or (choice and choice.decision == "reject")
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
    ordered: list[ModificationOperation] = []
    visited = set()

    def order(op):
        if op.operation_id in visited:
            return
        for key in op.depends_on:
            order(by_id[key])
        visited.add(op.operation_id)
        ordered.append(op)

    for op in ops:
        order(op)
    for op in ordered:
        decision = resolve(op)
        if decision.decision in ("reject", "pending"):
            continue
        if isinstance(decision.after, str) and not decision.after.strip():
            raise ValueError("修改后文字不能为空白")
        if decision.after == op.before:
            continue
        collection = STRUCTURAL_FIELDS.get(op.type)
        if collection is not None:
            items = getattr(result, collection)
            if op.type.startswith("add_"):
                items.append(_new_node(op, decision))
            elif op.type.startswith("remove_"):
                if decision.after is not None:
                    raise ValueError("删除操作后值必须为空")
                setattr(result, collection, [item for item in items if item.id != op.id])
            else:
                ids = decision.after
                if not isinstance(ids, list) or any(not isinstance(key, str) for key in ids):
                    raise ValueError("排序需要 ID 列表")
                by_item = {item.id: item for item in items}
                if len(ids) != len(set(ids)) or set(ids) != set(by_item):
                    raise ValueError("排序不得遗漏、重复或引入目标")
                setattr(result, collection, [by_item[key] for key in ids])
            continue
        node = _node(result, op)
        adapter = TypeAdapter(type(node).model_fields[op.field].rebuild_annotation())
        value = adapter.validate_json(json.dumps(decision.after, ensure_ascii=False), strict=True)
        if op.field in ("total_time_seconds", "active_time_seconds") and value != 0:
            raise ValueError("AI 只能恢复服务端派生时长")
        setattr(node, op.field, value)
    result = RecipeSnapshot.model_validate(result.model_dump(mode="json"))
    # Attribute only canonical, effective changes. Multiple ingredient fields
    # share one source marker; a no-op must not erase another field's evidence.
    for op in ordered:
        decision = resolved[op.operation_id]
        source_field = SOURCE_FIELDS.get(op.field)
        if (
            decision.decision not in ("reject", "pending")
            and source_field
            and op.type not in STRUCTURAL_FIELDS
            and _operation_value(result, op) != op.before
        ):
            setattr(_node(result, op), source_field, _source(op, decision))
    # Field validators can canonicalize text (for example ingredient labels).
    # Visible selections, immutable operations and experience receipts must all
    # use the exact value that passed snapshot validation, not raw model text.
    for op in ops:
        decision = resolved[op.operation_id]
        if decision.decision in ("reject", "pending"):
            continue
        decision.after = _operation_value(result, op)
        if decision.after == op.before:
            continue
        accepted.append(
            {
                **op.model_dump(mode="json"),
                "after": decision.after,
                "source": "ai_estimated",
                "decision": decision.decision,
            }
        )
    return result, [resolved[op.operation_id] for op in ops], accepted


def _state(session, row):
    snapshot = RecipeSnapshot.model_validate(row.baseline["snapshot"])
    ops = [ModificationOperation.model_validate(op) for op in row.proposal.get("operations", [])]
    # Saved decisions are canonical request data, not derived rejection state.
    choices = [ModificationDecision.model_validate(d) for d in row.decisions]
    changed, decisions, accepted = _apply(snapshot, ops, choices)
    changed = recipes._validate_snapshot(session, changed)
    by_id = {op.operation_id: op for op in ops}
    for decision in decisions:
        if decision.decision in ("accept", "modify"):
            decision.after = _operation_value(changed, by_id[decision.operation_id])
    for operation in accepted:
        operation["after"] = _operation_value(changed, by_id[operation["operation_id"]])
    return changed, ops, decisions, accepted


def preview(
    session: Session, settings: Settings, owner: User, row: RecipeModification
) -> ModificationPreview:
    changed, ops, decisions, _ = _state(session, row)
    status = AIStatus.model_validate(gateway.availability(session, settings, owner.id, "modify"))
    if row.error in ("model_unavailable", "configuration", "daily_quota", "monthly_budget"):
        status.available = False
        status.reason = row.error
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
        status=status,
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
    canonical = body.model_dump(mode="json", exclude={"request_id", "retry_failed"})
    row = None
    if body.request_id:
        existing = session.scalar(
            select(RecipeModification)
            .where(RecipeModification.id == body.request_id)
            .with_for_update()
            .execution_options(populate_existing=True)
        )
        if existing:
            if existing.user_id != owner.id:
                raise NotFound()
            if existing.request != canonical:
                raise ApiError(409, "modification_request_conflict", "请求标识已用于另一项修改")
            if not body.retry_failed or existing.error not in (
                "model_unavailable",
                "configuration",
                "daily_quota",
                "monthly_budget",
                "invalid_output",
            ):
                return get(session, settings, owner, existing.id)
            _fresh(session, owner, existing)
            # Claim the retry before gateway I/O commits. Concurrent retries see
            # pending, and all actual attempts retain the original quota identity.
            existing.error = "pending"
            existing.revision += 1
            row = existing
    baseline = row.baseline if row is not None else _target(session, owner, body)
    if row is None:
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
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        existing = session.get(RecipeModification, body.request_id) if body.request_id else None
        if existing is None:
            raise
        if existing.user_id != owner.id:
            raise NotFound() from None
        if existing.request != canonical:
            raise ApiError(
                409, "modification_request_conflict", "请求标识已用于另一项修改"
            ) from None
        # The winning request may still be running; return its honest pending
        # receipt without a second gateway reservation or experience event.
        return get(session, settings, owner, existing.id)
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
        elif intent.category not in ("text", "cookware", "time_difficulty", "method"):
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
                        ["unreferenced_fields_dropped"]
                        if set(value) - {"operations", "explanation"}
                        else []
                    )
                    if warnings:
                        logger.warning(
                            "discarded unreferenced model fields",
                            extra={"modification_id": str(row.id)},
                        )
                    output = ModificationOutput.model_validate(
                        {
                            "operations": value.get("operations"),
                            "explanation": value.get("explanation"),
                        }
                    )
                    base = RecipeSnapshot.model_validate(baseline["snapshot"])
                    _validate_operations(base, output.operations)
                    _validate_intent_operations(base, intent, output.operations)
                    if not output.operations:
                        proposal["operations"] = []
                        proposal["warnings"] = [output.explanation]
                        row.error = "cannot_modify"
                        break
                    changed, _, _ = _apply(
                        RecipeSnapshot.model_validate(baseline["snapshot"]),
                        output.operations,
                        [
                            ModificationDecision(operation_id=op.operation_id, decision="accept")
                            for op in output.operations
                        ],
                    )
                    changed = recipes._validate_snapshot(session, changed)
                    for op in output.operations:
                        op.after = _operation_value(changed, op)
                        if op.after == op.before:
                            raise ValueError("操作没有实际改动")
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
    canonical = body.model_dump(mode="json", exclude_none=True)
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
    from gramtree.ai import explanations

    explanations.validate_modification_fingerprint(
        owner.id, row.id, body.revision, accepted, body.explanation_fingerprint
    )
    if body.tags is not None:
        changed.tags = body.tags
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
