"""Quantify saved execution fields with the existing gateway; apply owned decisions."""

import math
import uuid
from collections import defaultdict
from typing import Any

from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway
from gramtree.core.errors import ApiError, NotFound
from gramtree.core.time import utcnow
from gramtree.events.service import EventInput
from gramtree.ingredients.models import Ingredient, IngredientAttribute
from gramtree.recipes import reproducibility, service
from gramtree.recipes.models import Recipe, RecipeQuantification, RecipeVersion
from gramtree.recipes.quantification_schemas import (
    QuantificationDecision,
    QuantificationDecisionsInput,
    QuantificationOutput,
    QuantificationSuggestion,
    RecipeQuantificationOut,
)
from gramtree.recipes.schemas import (
    RecipeSnapshot,
    RecipeVersionCreate,
    ReproducibilityProblem,
    ValueSource,
)
from gramtree.settings import Settings

SOURCES = {
    "quantity": "quantity_source",
    "preparation": "preparation_source",
    "instruction": "instruction_source",
    "duration_seconds": "duration_source",
    "heat": "heat_source",
    "doneness": "doneness_source",
    "temperature_celsius": "temperature_source",
}


def _current(
    session: Session, owner: User, recipe_id: uuid.UUID, base_id: uuid.UUID
) -> tuple[Recipe, RecipeVersion]:
    recipe = session.scalar(
        select(Recipe)
        .where(Recipe.id == recipe_id, Recipe.owner_id == owner.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if recipe is None:
        raise NotFound()
    if recipe.current_version_id != base_id:
        raise ApiError(409, "stale_quantification", "菜谱已有新版本，请重新检查和量化")
    version = session.get(RecipeVersion, base_id)
    if version is None:
        raise NotFound()
    return recipe, version


def _context(session: Session, snapshot: RecipeSnapshot) -> list[dict[str, Any]]:
    contexts = []
    for item in snapshot.ingredients:
        library = session.get(Ingredient, item.ingredient_id) if item.ingredient_id else None
        attributes = (
            {
                row.field: {"value": row.value, "source": row.source, "status": row.status}
                for row in session.scalars(
                    select(IngredientAttribute).where(
                        IngredientAttribute.ingredient_id == library.id
                    )
                )
            }
            if library
            else {}
        )
        contexts.append(
            {
                "id": item.id,
                "role": item.group or "未指定",
                "functional": item.functional,
                "category": library.category if library else None,
                "density": attributes.get("density"),
                "unit_weight": attributes.get("count_units"),
            }
        )
    return contexts


def propose(
    session: Session, settings: Settings, owner: User, recipe_id: uuid.UUID, base_id: uuid.UUID
) -> RecipeQuantificationOut:
    _, version = _current(session, owner, recipe_id, base_id)
    snapshot = RecipeSnapshot.model_validate(version.snapshot)
    problems = reproducibility.check(snapshot).problems
    ignored = {
        p["id"]
        for p in (version.reproducibility or {}).get("problems", [])
        if p["status"] == "ignored"
    }
    for p in problems:
        if p.id in ignored:
            p.status = "ignored"
    if not problems:
        raise ApiError(409, "quantification_not_needed", "当前版本已经可复刻")
    if any(p.position.collection == "snapshot" for p in problems):
        raise ApiError(422, "quantification_requires_recipe", "请先填写食材和步骤，再请求量化")
    payload = {
        "snapshot": snapshot.model_dump(mode="json"),
        "problems": [p.model_dump(mode="json") for p in problems],
        "ingredient_context": _context(session, snapshot),
    }
    try:
        raw = gateway.call(
            session, settings, owner.id, "quantify", payload, uuid.uuid4(), content_id=base_id
        )
        output = (
            QuantificationOutput.model_validate_json(raw)
            if isinstance(raw, str)
            else QuantificationOutput.model_validate(raw)
        )
        ids = [s.problem_id for s in output.suggestions]
        if len(ids) != len(set(ids)) or set(ids) != {p.id for p in problems}:
            raise ValueError("每个问题必须有且只有一项建议")
        by_id = {p.id: p for p in problems}
        for suggestion in output.suggestions:
            if by_id[suggestion.problem_id].position.field in (
                "quantity",
                "duration_seconds",
                "heat",
            ) and not (suggestion.baseline and suggestion.adjustment):
                raise ValueError("变量参数需要基准和调整方法")
        # Validate patches without saving anything. Every suggestion must actually
        # concretize its target; malformed model output never becomes owned metadata.
        applied = _apply(
            snapshot,
            problems,
            output.suggestions,
            [
                QuantificationDecision(problem_id=s.problem_id, decision="accept")
                for s in output.suggestions
            ],
        )
        remaining = reproducibility.check(applied).problems
        targets = {(p.position.collection, p.position.item_id, p.position.field) for p in problems}
        if any(
            (p.position.collection, p.position.item_id, p.position.field) in targets
            for p in remaining
        ):
            raise ValueError("建议没有具体化问题字段")
        service._validate_snapshot(session, applied)
    except gateway.Unavailable as exc:
        raise ApiError(
            503, "quantification_unavailable", "暂时无法量化，可手动填写", exc.reason
        ) from exc
    except (ValueError, TypeError, KeyError, StopIteration) as exc:
        raise ApiError(503, "invalid_quantification", "量化结果不完整，请重试或手动填写") from exc
    _current(session, owner, recipe_id, base_id)  # Gateway accounting commits release locks.
    row = RecipeQuantification(
        recipe_id=recipe_id,
        base_version_id=base_id,
        proposals={
            "problems": [p.model_dump(mode="json") for p in problems],
            **output.model_dump(mode="json"),
        },
    )
    session.add(row)
    session.commit()
    return RecipeQuantificationOut(
        id=row.id, base_version_id=base_id, problems=problems, suggestions=output.suggestions
    )


def _apply(
    snapshot: RecipeSnapshot,
    problems: list[ReproducibilityProblem],
    suggestions: list[QuantificationSuggestion],
    decisions: list[QuantificationDecision],
) -> RecipeSnapshot:
    result = snapshot.model_copy(deep=True)
    by_problem = {p.id: p for p in problems}
    by_suggestion = {s.problem_id: s for s in suggestions}
    groups = defaultdict(list)
    for d in decisions:
        if d.problem_id not in by_suggestion or d.problem_id not in by_problem:
            raise ValueError("未知问题")
        if d.decision != "ignore":
            p = by_problem[d.problem_id]
            groups[(p.position.collection, p.position.item_id, p.position.field)].append(
                (p, by_suggestion[d.problem_id], d)
            )
    for (collection, item_id, field), patches in groups.items():
        if field not in SOURCES or collection not in ("ingredients", "steps"):
            raise ValueError("不支持的执行字段")
        node = next(i for i in getattr(result, collection) if i.id == item_id)
        # Full-field cutting fixes can cover an ambiguous amount. Require every
        # covered problem to be decided and every fragment value to appear in the
        # chosen full text; otherwise it would silently discard another decision.
        whole = [patch for patch in patches if patch[0].position.start is None]
        applying = patches
        if whole and field not in ("quantity", "duration_seconds", "temperature_celsius"):
            if len(whole) != 1:
                raise ValueError("同字段完整建议冲突")
            p, s, d = whole[0]
            text = d.value if d.decision == "modify" else s.value
            handled = {patch[0].id for patch in patches}
            if any(
                (other.position.collection, other.position.item_id, other.position.field)
                == (collection, item_id, field)
                and other.id not in handled
                for other in problems
            ):
                raise ValueError("完整字段建议覆盖了未接受的问题，请逐项确认或手动编辑")
            for _, fragment, choice in patches:
                value = choice.value if choice.decision == "modify" else fragment.value
                if value is None or text is None or value not in text:
                    raise ValueError("同字段建议不一致，请统一修改")
            applying = whole
        else:
            spans = [(p.position.start or 0, p.position.end or 0) for p, _, _ in patches]
            for index, (start, end) in enumerate(spans):
                if any(
                    start < other_end and other_start < end
                    for other_start, other_end in spans[:index]
                ):
                    raise ValueError("同字段建议重叠")
        # Disjoint text fragments apply right-to-left to retain original offsets.
        for p, s, d in sorted(
            applying, key=lambda patch: patch[0].position.start or 0, reverse=True
        ):
            value = d.value if d.decision == "modify" else s.value
            unit = d.unit if d.decision == "modify" else s.unit
            if value is None:
                raise ValueError("缺少具体值")
            if field == "quantity":
                number = float(value)
                if (
                    not math.isfinite(number)
                    or number <= 0
                    or not unit
                    or reproducibility.ambiguous_unit(unit)
                ):
                    raise ValueError("用量必须为正数和具体单位")
                node.quantity = number
                node.unit = unit
            elif field in ("duration_seconds", "temperature_celsius"):
                number = float(value)
                if not math.isfinite(number) or number <= 0:
                    raise ValueError("参数必须是正数")
                if field == "duration_seconds" and not number.is_integer():
                    raise ValueError("时长必须为整数秒")
                setattr(node, field, int(number) if field == "duration_seconds" else number)
            else:
                old = getattr(node, field) or ""
                if p.position.start is not None:
                    value = old[: p.position.start] + value + old[p.position.end :]
                setattr(node, field, value)
        previous_source = getattr(node, SOURCES[field])
        manual = any(d.decision == "modify" for _, _, d in patches)
        sources = [s for _, s, _ in patches]
        originals = [p.original for p, _, _ in patches if p.original is not None]
        confidence = min(
            (s.confidence for s in sources), key=lambda c: {"low": 0, "medium": 1, "high": 2}[c]
        )
        source = (
            ValueSource(source="author_filled")
            if manual
            else ValueSource(
                source="ai_estimated",
                original="；".join(originals) or None,
                confidence={"low": 0.4, "medium": 0.7, "high": 0.9}[confidence],
                confidence_level=confidence,
                basis="；".join(dict.fromkeys(s.basis for s in sources)),
                baseline="；".join(dict.fromkeys(s.baseline for s in sources if s.baseline))
                or None,
                adjustment="；".join(dict.fromkeys(s.adjustment for s in sources if s.adjustment))
                or None,
            )
        )
        if not manual and previous_source and previous_source.source == "ai_estimated":
            # A later decision on a different fragment must not erase earlier evidence.
            for metadata in ("original", "basis", "baseline", "adjustment"):
                values = [getattr(previous_source, metadata), getattr(source, metadata)]
                setattr(source, metadata, "；".join(dict.fromkeys(v for v in values if v)) or None)
            prior_level = previous_source.confidence_level
            if prior_level:
                level = min(
                    (prior_level, confidence), key=lambda c: {"low": 0, "medium": 1, "high": 2}[c]
                )
                source.confidence_level = level
                source.confidence = {"low": 0.4, "medium": 0.7, "high": 0.9}[level]
        setattr(node, SOURCES[field], source)
    return RecipeSnapshot.model_validate(result.model_dump(mode="json"))


def _retained_problem_ids(
    problems: list[ReproducibilityProblem],
    suggestions: list[QuantificationSuggestion],
    decisions: list[QuantificationDecision],
) -> dict[str, str]:
    """Remap untouched fragment positions after preceding concrete replacements."""
    chosen = {d.problem_id: d for d in decisions}
    by_suggestion = {s.problem_id: s for s in suggestions}
    retained = {}
    for p in problems:
        decision = chosen.get(p.id)
        if decision and decision.decision != "ignore":
            continue
        position = p.position
        offset = position.start
        if offset is not None:
            for other in problems:
                change = chosen.get(other.id)
                if not change or change.decision == "ignore":
                    continue
                op = other.position
                if (op.collection, op.item_id, op.field) != (
                    position.collection,
                    position.item_id,
                    position.field,
                ):
                    continue
                if (
                    op.start is not None
                    and op.end is not None
                    and position.start is not None
                    and op.end <= position.start
                ):
                    replacement = (
                        change.value
                        if change.decision == "modify"
                        else by_suggestion[other.id].value
                    )
                    offset += len(replacement or "") - (op.end - op.start)
        suffix = str(offset) if offset is not None else "field"
        retained[p.id] = (
            f"{position.collection}:{position.item_id}:{position.field}:{p.type}:{suffix}"
        )
    return retained


def decide(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    proposal_id: uuid.UUID,
    body: QuantificationDecisionsInput,
):
    service._owned_recipe(session, owner, recipe_id)
    row = session.scalar(
        select(RecipeQuantification)
        .where(RecipeQuantification.id == proposal_id, RecipeQuantification.recipe_id == recipe_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if row is None:
        raise NotFound()
    canonical = body.model_dump(mode="json")
    if row.saved_version_id:
        if row.decisions != canonical:
            raise ApiError(
                409, "quantification_already_decided", "这批建议已处理，请重新量化剩余问题"
            )
        return service.get_version(session, settings, owner, recipe_id, row.saved_version_id)
    _, version = _current(session, owner, recipe_id, row.base_version_id)
    problems = [ReproducibilityProblem.model_validate(p) for p in row.proposals["problems"]]
    suggestions = [QuantificationSuggestion.model_validate(s) for s in row.proposals["suggestions"]]
    decisions = (
        [QuantificationDecision(problem_id=s.problem_id, decision="accept") for s in suggestions]
        if body.accept_all
        else body.decisions
    )
    snapshot = RecipeSnapshot.model_validate(version.snapshot)
    try:
        changed = _apply(snapshot, problems, suggestions, decisions)
        # Manual values must also be concrete; ignore is the explicit unresolved path.
        decided_targets = {
            (p.position.collection, p.position.item_id, p.position.field)
            for p in problems
            if any(d.problem_id == p.id and d.decision != "ignore" for d in decisions)
        }
        retained_ids = _retained_problem_ids(problems, suggestions, decisions)
        retained_problems = {
            (retained_ids[p.id], p.original) for p in problems if p.id in retained_ids
        }
        if any(
            (p.position.collection, p.position.item_id, p.position.field) in decided_targets
            and (p.id, p.original) not in retained_problems
            for p in reproducibility.check(changed).problems
        ):
            raise ValueError("请填写具体数值或说明")
    except (ValueError, TypeError, StopIteration) as exc:
        raise ApiError(422, "invalid_quantification_decision", "处理参数有误", str(exc)) from exc
    by_problem = {p.id: p for p in problems}
    by_suggestion = {s.problem_id: s for s in suggestions}
    events = []
    for d in decisions:
        p, s = by_problem[d.problem_id], by_suggestion[d.problem_id]
        node = next(
            i for i in getattr(changed, p.position.collection) if i.id == p.position.item_id
        )
        final = getattr(node, p.position.field)
        final_value = f"{final:g}" if isinstance(final, (int, float)) else str(final or "") or None
        final_unit = node.unit if p.position.field == "quantity" else None
        events.append(
            EventInput(
                id=uuid.uuid4(),
                event_type="recipe.quantification_decision",
                type_version=1,
                device_id="server",
                device_time=utcnow(),
                app_version="server",
                correlation={},
                content={
                    "recipe_version_id": "",
                    "problem_id": p.id,
                    "problem_type": p.type,
                    "ai_value": s.value,
                    "ai_unit": s.unit,
                    "ai_confidence": s.confidence,
                    "decision": d.decision,
                    "final_value": final_value,
                    "final_unit": final_unit,
                },
            )
        )
    chosen = {d.problem_id: d for d in decisions}
    ignored_ids = {
        retained_ids[p.id]
        for p in problems
        if p.id in retained_ids
        and (
            (p.id in chosen and chosen[p.id].decision == "ignore")
            or (p.id not in chosen and p.status == "ignored")
        )
    }
    row.decisions = canonical
    # Internal construction allows untouched backend verification; decision
    # requests cannot write source metadata, and changed sources are server-owned.
    create = RecipeVersionCreate.model_construct(
        snapshot=changed,
        base_version_id=version.id,
        ai_assisted=version.ai_assisted or any(d.decision == "accept" for d in decisions),
        change_note="确认 AI 量化建议",
        image_ids=[],
    )
    return service.save_version(
        session,
        redis,
        settings,
        owner,
        recipe_id,
        create,
        trusted_sources=True,
        quantification_record=row,
        decision_events=events,
        ignored_problem_ids=ignored_ids,
    )
