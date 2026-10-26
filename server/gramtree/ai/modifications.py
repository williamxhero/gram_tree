"""Finite, server-owned edits shared by authoring and unsaved generation results."""

import json
import logging
import math
import uuid
from typing import Any

from pydantic import TypeAdapter
from redis import Redis
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import context, gateway
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
from gramtree.ingredients.models import Ingredient
from gramtree.recipes import food_safety, personal_safety, reproducibility
from gramtree.recipes import service as recipes
from gramtree.recipes.models import RecipeVersion
from gramtree.recipes.schemas import (
    RecipeIngredient,
    RecipeSnapshot,
    RecipeStep,
    RecipeVersionCreate,
    ValueSource,
)
from gramtree.runtime_config import service as config
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
    "change_flavor_contribution": ("ingredients", {"flavor_contribution"}),
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
    "flavor_contribution": "flavor_source",
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
    if body.improvement_draft_id is not None:
        from gramtree.recipes.improvements import owned_draft

        row = owned_draft(session, owner, body.improvement_draft_id)
        return {"snapshot": row.snapshot, "dish_name": row.dish_name, "dish_aliases": []}
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
    current = context.build(session, owner, session.info["settings"])
    if row.baseline.get("context_dependency") != current.dependency:
        raise ApiError(409, "stale_modification", "口味或家庭授权已变化，请重新提出修改")
    stored_recipe_baseline = {
        key: row.baseline[key]
        for key in ("snapshot", "dish_name", "dish_aliases", "draft")
        if key in row.baseline
    }
    if baseline != stored_recipe_baseline:
        raise ApiError(409, "stale_modification", "菜谱已有新版本，请重新提出修改")


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


_TASTE_AXES = {
    "salty": "咸",
    "sweet": "甜",
    "sour": "酸",
    "spicy": "辣",
    "umami": "鲜",
    "numbing": "麻",
    "oily": "油",
}
_REDUCE_WORDS = {"less", "reduce", "decrease", "lower", "淡", "减少", "降低", "少"}
_INCREASE_WORDS = {"more", "increase", "raise", "加", "增加", "提高", "重"}


def _taste_axis(intent: ModificationIntent) -> str | None:
    for key in ("axis", "taste_axis", "flavor", "taste"):
        value = intent.parameters.get(key)
        if isinstance(value, str):
            value = value.strip().casefold()
            if value in _TASTE_AXES:
                return value
            for axis, label in _TASTE_AXES.items():
                if value == label:
                    return axis
    return None


def _taste_direction(intent: ModificationIntent) -> str | None:
    value = intent.parameters.get("direction")
    if not isinstance(value, str):
        value = intent.parameters.get("change")
    if not isinstance(value, str):
        return None
    value = value.strip().casefold()
    if value in _REDUCE_WORDS:
        return "reduce"
    if value in _INCREASE_WORDS:
        return "increase"
    return None


def _taste_percent(session: Session, intent: ModificationIntent) -> float:
    raw = intent.parameters.get("adjustment_percent")
    if raw is None:
        raw = intent.parameters.get("percent")
    if raw is None:
        raw = config.get(session, "taste.adjustment_percent")
    if not isinstance(raw, (int, float)) or isinstance(raw, bool):
        raise ValueError("味型调整幅度必须是 20%、25% 或 30%")
    value = float(raw)
    if value > 1:
        value /= 100
    if value not in (0.2, 0.25, 0.3):
        raise ValueError("味型调整幅度只能是 20%、25% 或 30%")
    return value


def _taste_weights(snapshot: RecipeSnapshot, axis: str):
    result = []
    for ingredient in snapshot.ingredients:
        profile = ingredient.flavor_contribution
        strength = None if profile is None else getattr(profile, axis)
        if strength is None:
            raise ValueError(f"{ingredient.display_name} 未填写该味型贡献，不能当作零贡献")
        if strength == 0 or ingredient.quantity == 0:
            continue
        amount = ingredient.base_quantity
        if amount is None or amount <= 0:
            raise ValueError(f"{ingredient.display_name} 缺少可换算基础量，无法可靠分摊")
        result.append((ingredient, float(strength) * float(amount)))
    return result


def _taste_expected_quantities(
    session: Session, snapshot: RecipeSnapshot, intent: ModificationIntent
) -> dict[str, float]:
    axis = _taste_axis(intent)
    direction = _taste_direction(intent)
    if axis is None or direction is None:
        raise ValueError("味型调整需要明确味型和增减方向")
    percent = _taste_percent(session, intent)
    weighted = _taste_weights(snapshot, axis)
    if not weighted:
        raise ValueError("菜谱没有完整的该味型贡献和基础用量，无法可靠分摊")
    adjustable = [(item, weight) for item, weight in weighted if not item.functional]
    if not adjustable:
        raise ValueError("功能性用料受到保护，且没有可调整的其他来源")
    total = sum(weight for _, weight in weighted)
    adjustable_total = sum(weight for _, weight in adjustable)
    change = total * percent
    if direction == "reduce" and change > adjustable_total + 1e-9:
        raise ValueError("功能性用料保护后无法达到请求的味型降幅")
    # Strength is per base unit (g/ml/count), not per displayed kg/l/spoon.
    # Allocate contribution deltas by weight, then convert back to the author's
    # unit. In this linear model that simplifies to one common quantity factor.
    factor = 1 + (-1 if direction == "reduce" else 1) * change / adjustable_total
    return {item.id: round(item.quantity * max(0, factor), 6) for item, _ in adjustable}


def _taste_warnings(
    snapshot: RecipeSnapshot, intent: ModificationIntent, affected_ids: set[str] | None = None
) -> list[str]:
    axis = _taste_axis(intent)
    direction = _taste_direction(intent)
    if axis is None or direction is None or direction != "reduce":
        return []
    warnings: list[str] = []
    ingredients = [
        item for item in snapshot.ingredients if affected_ids is None or item.id in affected_ids
    ]
    if not ingredients:
        return []
    names = " ".join(item.display_name for item in ingredients)
    if axis == "salty":
        if any(term in names for term in ("生抽", "酱油", "老抽", "豆瓣酱")):
            warnings.append("减少咸味来源可能使颜色变浅，请单独观察上色")
        if any(
            item.flavor_contribution is not None and item.flavor_contribution.umami
            for item in ingredients
        ):
            warnings.append("减少咸味来源可能同时降低鲜味，补救操作需单独确认")
        if any("收汁" in (step.instruction + (step.notes or "")) for step in snapshot.steps):
            warnings.append("调味液减少可能改变收汁浓度和时间，请在收汁步骤复核")
    elif axis == "sweet":
        warnings.append("减少甜味可能改变上色和酸甜平衡，请在出锅前复核")
    elif axis == "spicy":
        warnings.append("减少辣味只调整有记录的辣味来源，不能推断辣度为零")
    elif axis == "sour":
        warnings.append("减少酸味可能改变酸甜平衡，请在出锅前复核")
    elif axis == "oily":
        warnings.append("减少油量可能改变传热和挂汁效果，请复核火候")
    return warnings


def _validate_taste_operations(
    session: Session,
    snapshot: RecipeSnapshot,
    intent: ModificationIntent,
    ops: list[ModificationOperation],
) -> list[str]:
    expected = _taste_expected_quantities(session, snapshot, intent)
    quantity_ops = {op.id: op for op in ops if op.type == "change_quantity"}
    if set(quantity_ops) != set(expected):
        raise ValueError("味型调整必须覆盖所有可计算来源，且只能改变用量")
    for ingredient_id, quantity in expected.items():
        op = quantity_ops[ingredient_id]
        if (
            op.field != "quantity"
            or isinstance(op.after, bool)
            or not isinstance(op.after, (int, float))
            or not math.isclose(op.after, quantity, rel_tol=1e-6, abs_tol=1e-6)
        ):
            raise ValueError("味型分摊结果与服务端计算不一致")
        ingredient = next(item for item in snapshot.ingredients if item.id == ingredient_id)
        if ingredient.functional:
            raise ValueError("功能性用料不能被味型降幅操作改变")
    roots = {op.operation_id for op in quantity_ops.values()}
    by_id = {op.operation_id: op for op in ops}
    for op in ops:
        if op.type == "change_quantity":
            continue
        if op.type != "change_step_field" or op.field not in TEXT_FIELDS["change_step_field"][1]:
            raise ValueError("味型调整只能改变用量或提出步骤副作用建议")
        if not roots.intersection(
            {op_id for op_id in op.depends_on}
            | {ancestor for dep in op.depends_on for ancestor in _operation_ancestors(by_id, dep)}
        ):
            raise ValueError("副作用建议必须依赖味型用量调整")
    return _taste_warnings(snapshot, intent)


def _operation_ancestors(by_id: dict[str, ModificationOperation], operation_id: str) -> set[str]:
    result: set[str] = set()
    for dependency in by_id[operation_id].depends_on:
        result.add(dependency)
        result.update(_operation_ancestors(by_id, dependency))
    return result


def _substitution_target(snapshot: RecipeSnapshot, intent: ModificationIntent) -> RecipeIngredient:
    target = intent.parameters.get("ingredient_id")
    candidates = [item for item in snapshot.ingredients if item.id == target]
    if not candidates:
        name = intent.parameters.get("missing_ingredient") or intent.parameters.get(
            "ingredient_name"
        )
        candidates = [item for item in snapshot.ingredients if item.display_name == name]
    if len(candidates) != 1:
        raise ValueError("请明确缺料在这道菜里的具体作用；同名食材不能合并替代")
    return candidates[0]


def _substitution_facts(session: Session, source: RecipeIngredient) -> dict[str, Any] | None:
    relation = source.replacement
    if relation is None or isinstance(relation, str) or relation.ingredient_id is None:
        return None
    standard = session.get(Ingredient, relation.ingredient_id)
    if standard is None:
        return None
    return {
        "ingredient_id": str(standard.id),
        "display_name": standard.standard_name,
        "ratio": relation.ratio,
        "attributes": recipes._ingredient_attributes(session, standard.id).model_dump(mode="json"),
    }


def _validate_substitution_operations(
    session: Session,
    snapshot: RecipeSnapshot,
    intent: ModificationIntent,
    ops: list[ModificationOperation],
) -> None:
    allowed = {
        "replace_ingredient",
        "change_quantity",
        "change_replacement",
        "change_display_name",
        "change_flavor_contribution",
        "change_step_field",
        "remove_ingredient",
        "change_step_ingredients",
    }
    if any(op.type not in allowed for op in ops):
        raise ValueError("缺料替代只能改变食材、用量、味型事实、替代说明或清理步骤引用")
    target = intent.parameters.get("ingredient_id")
    if not isinstance(target, str) or not target.strip():
        raise ValueError("缺料替代必须明确菜谱内食材 ID，不能按同名食材猜测")
    replacements = [op for op in ops if op.type == "replace_ingredient"]
    removals = [op for op in ops if op.type == "remove_ingredient"]
    if len(replacements) + len(removals) != 1:
        raise ValueError("缺料替代只能明确一个替代或省略目标")
    root = replacements[0] if replacements else removals[0]
    if root.id != target:
        raise ValueError("缺料替代目标与意图不一致")
    source = next((item for item in snapshot.ingredients if item.id == target), None)
    if source is None:
        raise ValueError("缺料目标不存在")
    if any(
        op.id != target
        for op in ops
        if op.type not in {"change_step_ingredients", "change_step_field"}
    ):
        raise ValueError("缺料替代不得修改其他食材")
    for op in ops:
        if op.type == "change_step_field":
            step = next((step for step in snapshot.steps if step.id == op.id), None)
            if (
                step is None
                or target not in step.ingredient_ids
                or op.field not in {"instruction", "notes", "why"}
            ):
                raise ValueError("缺料只能改相关步骤的说明、备注和原因")
        if op.type == "change_step_ingredients":
            step = next((step for step in snapshot.steps if step.id == op.id), None)
            if step is None or target not in step.ingredient_ids:
                raise ValueError("引用清理不得修改无关步骤")
            if op.after != [key for key in step.ingredient_ids if key != target]:
                raise ValueError("省略只能清理缺料引用，不得改动其他引用")
    if removals:
        if source.functional:
            raise ValueError("功能性用料不能直接省略，需先确认适用替代")
        if any(
            op.type not in {"remove_ingredient", "change_step_ingredients", "change_step_field"}
            for op in ops
        ):
            raise ValueError("省略只能删除缺料并显式调整相关步骤")
        for step in snapshot.steps:
            if (
                target in step.ingredient_ids
                and source.display_name in step.instruction
                and not any(
                    op.id == step.id
                    and op.type == "change_step_field"
                    and op.field == "instruction"
                    for op in ops
                )
            ):
                raise ValueError("省略必须显式改写仍要求使用缺料的步骤说明")
        for op in ops:
            if op.type == "change_step_field" and op.operation_id not in _operation_ancestors(
                {item.operation_id: item for item in ops}, root.operation_id
            ):
                raise ValueError("省略必须依赖相关步骤改写，避免留下无法执行的说明")
        if root.field != "ingredients":
            raise ValueError("省略操作必须删除目标食材")
        return
    if root.field != "ingredient_id" or not isinstance(root.after, str):
        raise ValueError("替代食材必须提供标准食材 ID")
    try:
        target_id = uuid.UUID(root.after)
    except ValueError as exc:
        raise ValueError("替代食材 ID 无效") from exc
    replacement = session.get(Ingredient, target_id)
    if replacement is None:
        raise ValueError("替代食材未登记，不能作为已核实建议")
    attributes = recipes._ingredient_attributes(session, target_id)
    relation = source.replacement
    known_relation = (
        relation is not None
        and not isinstance(relation, str)
        and relation.ingredient_id == target_id
    )
    if source.functional and not known_relation:
        raise ValueError("功能性用料没有本菜谱登记的适用替代，不能猜测")
    if relation is not None and not isinstance(relation, str) and known_relation:
        proposed = source.model_copy(deep=True)
        for op in ops:
            if op.id == source.id and op.type == "change_quantity":
                setattr(proposed, op.field, op.after)
        after_amount, after_unit = recipes._base_quantity(session, proposed)
        if (
            after_amount is None
            or after_unit != source.base_unit
            or source.base_quantity is None
            or not math.isclose(after_amount, source.base_quantity * relation.ratio, abs_tol=1e-6)
        ):
            raise ValueError("替代换算与本菜谱登记的基础量比例不一致")
    expected_fields: dict[str, Any] = {
        "display_name": replacement.standard_name,
        "replacement": {"ingredient_id": str(target_id), "display_name": replacement.standard_name},
    }
    if attributes.flavor is not None:
        expected_fields["flavor_contribution"] = attributes.flavor.value.model_dump()
    elif source.flavor_contribution is not None:
        expected_fields["flavor_contribution"] = None
    for op in ops:
        if op.type == "change_quantity" and op.field not in {"quantity", "unit"}:
            raise ValueError("替代换算只能改变数量和单位")
        if op.type == "change_replacement" and op.field != "replacement":
            raise ValueError("替代说明字段未登记")
        if op.type in {"change_display_name", "change_replacement", "change_flavor_contribution"}:
            expected = expected_fields.get(op.field)
            if (
                expected is not None
                and op.after != expected
                and not (
                    op.field == "replacement"
                    and isinstance(op.after, dict)
                    and op.after.get("ingredient_id") == str(target_id)
                    and op.after.get("display_name") == replacement.standard_name
                )
            ):
                raise ValueError("替代后的登记事实与食材库不一致")
            if op.field == "flavor_contribution" and expected is None and op.after is not None:
                raise ValueError("替代食材没有已登记味型，不能凭空补全")
        if op is not root and root.operation_id not in op.depends_on:
            raise ValueError("替代事实、换算和步骤引用必须依赖替代操作")
    for step in snapshot.steps:
        if target not in step.ingredient_ids or source.display_name not in step.instruction:
            continue
        instruction = next(
            (op for op in ops if op.id == step.id and op.field == "instruction"), None
        )
        if (
            instruction is None
            or instruction.after == step.instruction
            or (
                source.display_name in str(instruction.after)
                and replacement.standard_name not in str(instruction.after)
            )
        ):
            raise ValueError("替代必须显式改写仍要求使用原食材的步骤说明")
    original = source.model_dump(mode="json")
    for field, expected in expected_fields.items():
        unchanged = original[field] == expected
        if field == "replacement" and isinstance(original[field], dict):
            unchanged = all(original[field].get(key) == value for key, value in expected.items())
        if not unchanged and not any(op.field == field for op in ops):
            raise ValueError(f"替代后必须显式刷新登记字段：{field}")


def _validate_intent_operations(
    snapshot: RecipeSnapshot,
    intent: ModificationIntent,
    ops: list[ModificationOperation],
    *,
    session: Session | None = None,
) -> list[str]:
    if intent.category == "taste":
        if session is None:
            raise ValueError("味型调整缺少服务端规则上下文")
        return _validate_taste_operations(session, snapshot, intent, ops)
    if intent.category == "substitution":
        if session is None:
            raise ValueError("替代建议缺少服务端规则上下文")
        _validate_substitution_operations(session, snapshot, intent, ops)
        source = _substitution_target(snapshot, intent)
        warnings = ["替代不保证原风味或功能等效；请按本菜谱场景确认换算和成熟判断"]
        if source.functional:
            warnings.append("保留作者在本菜谱的功能性标记；食材库默认值不能替代实际作用")
        for op in ops:
            if op.type != "replace_ingredient":
                continue
            attributes = recipes._ingredient_attributes(session, uuid.UUID(str(op.after)))
            if attributes.flavor is None:
                warnings.append("替代品味型资料不完整，不推断精确贡献")
            else:
                warnings.append("替代品味型差异已按登记参考单独列为操作，不保证与本菜谱原贡献等效")
            if attributes.functional is None or attributes.functional.value != source.functional:
                warnings.append("替代品功能参考未知或与本菜谱不同，请核对适用场景")
            if attributes.allergens is None or attributes.allergens.estimate:
                warnings.append("替代品过敏原资料不完整，未知不能视为无过敏原")
            elif attributes.allergens.value:
                warnings.append("替代品含过敏原：" + "、".join(attributes.allergens.value))
        return warnings
    if intent.category == "text":
        if any(op.type not in TEXT_FIELDS or op.field not in TEXT_FIELDS[op.type][1] for op in ops):
            raise ValueError("改文字不得改变烹饪条件")
        return []
    by_id = {op.operation_id: op for op in ops}

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
                    and cause.operation_id not in _operation_ancestors(by_id, op.operation_id)
                ):
                    raise ValueError("时长必须依赖同时改变的步骤说明")
    if intent.category != "cookware" or not ops:
        return []
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
        if op is not root and root.operation_id not in _operation_ancestors(by_id, op.operation_id):
            raise ValueError("烹饪条件必须依赖厨具转换")
    return []


def _validate_selected_substitution(snapshot, changed, ops, decisions):
    by_decision = {decision.operation_id: decision for decision in decisions}
    for root in ops:
        if root.type != "replace_ingredient":
            continue
        selected = by_decision[root.operation_id]
        if selected.decision not in ("accept", "modify"):
            continue
        if selected.after != root.after:
            raise ValueError("改变替代品需要重新提出包含对应登记事实和换算的建议")
        before = next(item for item in snapshot.ingredients if item.id == root.id)
        after = next(item for item in changed.ingredients if item.id == root.id)
        if (
            after.functional != before.functional
            or after.functional_source != before.functional_source
        ):
            raise ValueError("替代不得覆盖作者的功能性标记")
        for step in snapshot.steps:
            if root.id not in step.ingredient_ids or before.display_name not in step.instruction:
                continue
            instruction = next(op for op in ops if op.id == step.id and op.field == "instruction")
            decision = by_decision[instruction.operation_id]
            if decision.decision == "pending":
                continue
            actual = _operation_value(changed, instruction)
            if (
                decision.decision == "reject"
                or actual == step.instruction
                or (before.display_name in actual and after.display_name not in actual)
            ):
                raise ValueError("替代后不能保留仍要求原食材的步骤，请拒绝替代或确认步骤改写")
        # Pending companion choices are allowed while reviewing. Once a fact is
        # decided, it cannot leave the accepted identity pointing at stale data.
        for op in ops:
            if op.id != root.id or op.field not in {
                "display_name",
                "flavor_contribution",
                "replacement",
            }:
                continue
            decision = by_decision[op.operation_id]
            if decision.decision == "pending":
                continue
            actual = _operation_value(changed, op)
            if actual != op.after:
                raise ValueError("替代品与登记事实不一致，请拒绝替代或保留对应事实操作")


def _apply(
    snapshot: RecipeSnapshot,
    ops: list[ModificationOperation],
    choices: list[ModificationDecision],
    *,
    session: Session | None = None,
    substitution: bool = False,
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
        resolve(op)
    if substitution:
        # Resolve deletion first: a rejection caused by cleanup must abandon the
        # whole omission group just like an explicit rejection of deletion.
        rejected_removals = [
            op
            for op in ops
            if op.type == "remove_ingredient" and resolved[op.operation_id].decision == "reject"
        ]
        abandoned = {op.operation_id: resolved[op.operation_id] for op in rejected_removals}
        for root in rejected_removals:
            for key in _operation_ancestors(by_id, root.operation_id):
                decision = resolved[key]
                abandoned[key] = (
                    decision
                    if decision.decision == "reject"
                    else ModificationDecisionOut(
                        operation_id=key,
                        decision="reject",
                        after=by_id[key].before,
                        blocked_by=[root.operation_id],
                    )
                )
        if abandoned:
            resolved = abandoned
            for op in ordered:
                resolve(op)
    for op in ordered:
        decision = resolved[op.operation_id]
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
    decisions = [resolved[op.operation_id] for op in ops]
    if session is not None and substitution:
        _validate_selected_substitution(snapshot, result, ops, decisions)
    return result, decisions, accepted


def _state(session, row):
    snapshot = RecipeSnapshot.model_validate(row.baseline["snapshot"])
    ops = [ModificationOperation.model_validate(op) for op in row.proposal.get("operations", [])]
    # Saved decisions are canonical request data, not derived rejection state.
    choices = [ModificationDecision.model_validate(d) for d in row.decisions]
    intent = ModificationIntent.model_validate(row.proposal["intent"]) if ops else None
    if intent is not None:
        _validate_intent_operations(snapshot, intent, ops, session=session)
    changed, decisions, accepted = _apply(
        snapshot,
        ops,
        choices,
        session=session,
        substitution=intent is not None and intent.category == "substitution",
    )
    changed = recipes._validate_snapshot(session, changed)
    by_id = {op.operation_id: op for op in ops}
    for decision in decisions:
        if decision.decision in ("accept", "modify"):
            decision.after = _operation_value(changed, by_id[decision.operation_id])
    for operation in accepted:
        operation["after"] = _operation_value(changed, by_id[operation["operation_id"]])
    return changed, ops, decisions, accepted


def _preview_warnings(session, row, changed, ops, decisions):
    warnings = list(row.proposal.get("warnings", []))
    if not ops or not row.decisions:
        return warnings
    baseline = RecipeSnapshot.model_validate(row.baseline["snapshot"])
    intent = ModificationIntent.model_validate(row.proposal["intent"])
    if intent.category == "taste":
        original_warnings = _taste_warnings(baseline, intent)
        warnings = [warning for warning in warnings if warning not in original_warnings]
        affected = {
            item.id
            for item in changed.ingredients
            if item.quantity
            < next(source.quantity for source in baseline.ingredients if source.id == item.id)
        }
        warnings.extend(_taste_warnings(baseline, intent, affected))
    elif intent.category == "substitution":
        by_decision = {decision.operation_id: decision for decision in decisions}
        for op in ops:
            if op.type != "replace_ingredient" or by_decision[op.operation_id].decision not in (
                "accept",
                "modify",
            ):
                continue
            source = next(item for item in baseline.ingredients if item.id == op.id)
            after = next(item for item in changed.ingredients if item.id == op.id)
            relation = after.replacement
            if (
                relation is not None
                and not isinstance(relation, str)
                and source.base_quantity is not None
                and after.base_quantity is not None
                and (
                    source.base_unit != after.base_unit
                    or not math.isclose(
                        after.base_quantity, source.base_quantity * relation.ratio, abs_tol=1e-6
                    )
                )
            ):
                warnings.append(
                    "实际选中用量已偏离登记换算参考比例；以作者确认的用量为准，需重新核对风味和功能"
                )
    return warnings


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
        personal_safety=personal_safety.check(session, changed, owner.id, settings),
        reproducibility=reproducibility.check(changed),
        status=status,
        warnings=_preview_warnings(session, row, changed, ops, decisions),
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
    authorized = context.build(session, owner, settings)
    context_payload = {
        key: value for key, value in authorized.model_payload.items() if value is not None
    }
    baseline = (
        row.baseline
        if row is not None
        else {
            **_target(session, owner, body),
            "context_dependency": authorized.dependency,
            "authorized_context": context_payload,
        }
    )
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
            {
                "text": body.text,
                **({"context": context_payload} if context_payload else {}),
            },
            row.id,
            content_id=body.base_version_id or body.generation_request_id,
        )
        intent = ModificationIntent.model_validate(json.loads(raw) if isinstance(raw, str) else raw)
        if intent.category == "taste":
            effective_percent = body.adjustment_percent
            if effective_percent is None:
                effective_percent = round(_taste_percent(session, intent) * 100)
            intent = intent.model_copy(
                update={
                    "parameters": {
                        **intent.parameters,
                        "adjustment_percent": effective_percent,
                    }
                }
            )
        if intent.category == "substitution" and intent.confidence >= 0.7:
            try:
                source = _substitution_target(
                    RecipeSnapshot.model_validate(baseline["snapshot"]), intent
                )
                intent = intent.model_copy(
                    update={"parameters": {**intent.parameters, "ingredient_id": source.id}}
                )
            except ValueError as exc:
                row.error = "cannot_modify"
                proposal["warnings"] = [str(exc)]
        proposal["intent"] = intent.model_dump(mode="json")
        if row.error == "cannot_modify":
            pass
        elif intent.category == "unknown" or intent.confidence < 0.7:
            row.error = "uncertain_intent"
        elif intent.category not in (
            "text",
            "cookware",
            "substitution",
            "taste",
            "time_difficulty",
            "method",
        ):
            row.error = "unsupported_intent"
        else:
            payload = {
                "text": body.text,
                "snapshot": baseline["snapshot"],
                "intent": proposal["intent"],
                **(
                    {"context": baseline["authorized_context"]}
                    if baseline.get("authorized_context")
                    else {}
                ),
            }
            if intent.category == "substitution":
                source = _substitution_target(
                    RecipeSnapshot.model_validate(baseline["snapshot"]), intent
                )
                payload["substitution_facts"] = _substitution_facts(session, source)
            if intent.category == "taste":
                base = RecipeSnapshot.model_validate(baseline["snapshot"])
                try:
                    payload["taste_quantities"] = _taste_expected_quantities(session, base, intent)
                except ValueError as exc:
                    proposal["operations"] = []
                    proposal["warnings"] = [str(exc)]
                    row.error = "cannot_modify"
            for repair in range(0 if row.error == "cannot_modify" else 2):
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
                    rule_warnings = (
                        _validate_intent_operations(
                            base, intent, output.operations, session=session
                        )
                        if output.operations
                        else []
                    )
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
                        session=session,
                        substitution=intent.category == "substitution",
                    )
                    changed = recipes._validate_snapshot(session, changed)
                    for op in output.operations:
                        op.after = _operation_value(changed, op)
                        if op.after == op.before:
                            raise ValueError("操作没有实际改动")
                    proposal.update(output.model_dump(mode="json"))
                    proposal["warnings"] = [*warnings, *rule_warnings]
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
    if row.saved_version_id or row.confirmation:
        raise ApiError(409, "modification_already_saved", "这批修改已经保存")
    _fresh(session, owner, row)
    if row.error:
        raise ApiError(409, "modification_not_ready", "没有可确认的修改建议", row.error)
    try:
        _, ops, _, _ = _state(session, row)
        changed, decisions, _ = _apply(
            RecipeSnapshot.model_validate(row.baseline["snapshot"]),
            ops,
            body.decisions,
            session=session,
            substitution=row.proposal.get("intent", {}).get("category") == "substitution",
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
    if row.request.get("improvement_draft_id"):
        raise ApiError(409, "improvement_save_required", "请在改良保存页确认来源和微调选择后保存")
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
