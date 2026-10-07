"""Retrieval-first orchestration; existing recipe contracts remain the save boundary."""

import json
import re
import uuid
from typing import Any

from pydantic import ValidationError
from redis import Redis
from sqlalchemy import String, cast, or_, select, text
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.ai import gateway
from gramtree.ai.models import GenerationRequest
from gramtree.ai.schemas import (
    AIStatus,
    GeneratedDraft,
    GenerateInput,
    GenerationResult,
    Question,
    RecipeIntent,
    RetrievalResult,
    SimilarRecipe,
)
from gramtree.core.errors import ApiError, NotFound
from gramtree.core.time import utcnow
from gramtree.events import service as events
from gramtree.events.registry import BY_KEY
from gramtree.ingredients import matching
from gramtree.recipes import food_safety
from gramtree.recipes import service as recipes
from gramtree.recipes.models import Dish, DishAlias, Recipe, RecipeVersion
from gramtree.recipes.schemas import RecipeCreate, RecipeSnapshot, ValueSource
from gramtree.settings import Settings


def record_event(
    session: Session,
    redis: Redis,
    owner: User,
    request_id: uuid.UUID,
    stage: str,
    details: dict[str, Any],
) -> None:
    content = {"request_id": str(request_id), "stage": stage, **details}
    spec = BY_KEY[("ai.recipe_generation", 1)]
    if spec.content_schema is not None:
        content = spec.content_schema.model_validate(content).model_dump(
            mode="json", exclude_none=True
        )
    now = utcnow()
    events.upload(
        session,
        redis,
        owner.id,
        [
            events.EventInput(
                id=uuid.uuid4(),
                event_type="ai.recipe_generation",
                type_version=1,
                device_id="server",
                device_time=now,
                app_version="server",
                correlation={},
                content=content,
            )
        ],
        now,
    )


def _risk(session: Session, title: str) -> None:
    result = food_safety.check(session, RecipeSnapshot(servings=2), title)
    if result.high_risk:
        raise ApiError(
            422,
            "unsafe_ai_request",
            "不能用 AI 设计这类高风险菜谱",
            "；".join(f.message for f in result.findings if f.severity == "high_risk"),
        )


def local_intent(session: Session, owner: User, request: str) -> RecipeIntent:
    # Cold-start fallback is intentionally only intent/keyword retrieval, never a
    # fabricated recipe. It does not claim to understand arbitrary constraints.
    names = session.scalars(select(Dish.name).join(Recipe).where(Recipe.owner_id == owner.id))
    dish = next(
        (name for name in sorted(set(names), key=len, reverse=True) if name in request), None
    )
    dish = dish or next(
        (name for name in ("宫保鸡丁", "番茄炒蛋", "炒青菜") if name in request), request[:200]
    )
    servings_match = re.search(r"(\d{1,3})\s*(?:人|份)", request)
    return RecipeIntent(
        dish_name=dish,
        servings=int(servings_match[1]) if servings_match else None,
        taste=["不辣"] if "不辣" in request else [],
        restrictions=["儿童"] if "小朋友" in request or "儿童" in request else [],
    )


def _similar(
    session: Session, settings: Settings, owner: User, intent: RecipeIntent
) -> list[SimilarRecipe]:
    keyword_ids = set(
        session.scalars(
            select(Recipe.id)
            .join(Dish)
            .join(RecipeVersion, Recipe.current_version_id == RecipeVersion.id)
            .where(
                Recipe.owner_id == owner.id,
                or_(
                    Dish.name.contains(intent.dish_name),
                    Dish.id.in_(
                        select(DishAlias.dish_id).where(DishAlias.alias.contains(intent.dish_name))
                    ),
                    cast(RecipeVersion.snapshot, String).contains(intent.dish_name),
                ),
            )
            .limit(5)
        )
    )
    ranked = list(keyword_ids)
    try:
        model, _ = gateway.route(session, "embedding")
        vector = gateway.embedding(
            gateway.call(
                session, settings, owner.id, "embedding", {"text": intent.dish_name}, uuid.uuid4()
            )
        )
        # Owner filtering happens inside the vector query. Dimension/model changes
        # cannot mix incompatible spaces; keyword retrieval remains available.
        rows = session.execute(
            text(
                "SELECT r.id FROM recipes r JOIN recipe_embeddings e "
                "ON e.version_id = r.current_version_id "
                "WHERE r.owner_id = :owner AND e.status = 'ready' AND e.model = :model "
                "AND CASE WHEN vector_dims(e.vector) = :dims THEN "
                "e.vector <=> CAST(:vector AS vector) ELSE NULL END < 0.5 "
                "ORDER BY CASE WHEN vector_dims(e.vector) = :dims THEN "
                "e.vector <=> CAST(:vector AS vector) ELSE NULL END, r.id LIMIT 5"
            ),
            {
                "owner": owner.id,
                "model": model.model,
                "dims": len(vector),
                "vector": json.dumps(vector),
            },
        )
        ranked.extend(row[0] for row in rows)
    except (gateway.Unavailable, ValueError, TypeError):
        pass
    result = []
    for recipe_id in dict.fromkeys(ranked):
        recipe = session.get(Recipe, recipe_id)
        if recipe is None or recipe.owner_id != owner.id:
            continue
        dish = session.get(Dish, recipe.dish_id)
        version = session.get(RecipeVersion, recipe.current_version_id)
        if dish is None or version is None:
            continue
        result.append(
            SimilarRecipe(
                recipe_id=recipe.id,
                version_id=version.id,
                dish_name=dish.name,
                servings=version.snapshot["servings"],
                ai_assisted=version.ai_assisted,
                basis="菜名或食材相似" if recipe_id in keyword_ids else "向量检索相似",
            )
        )
        if len(result) == 5:
            break
    return result


def begin(
    session: Session, redis: Redis, settings: Settings, owner: User, request: str
) -> RetrievalResult:
    _risk(session, request)
    fallback = False
    failure = None
    try:
        raw = gateway.call(session, settings, owner.id, "intent", {"text": request}, uuid.uuid4())
        intent = (
            RecipeIntent.model_validate_json(raw)
            if isinstance(raw, str)
            else RecipeIntent.model_validate(raw)
        )
    except (gateway.Unavailable, ValueError, TypeError) as exc:
        intent = local_intent(session, owner, request)
        fallback = True
        failure = exc.reason if isinstance(exc, gateway.Unavailable) else "invalid_intent"
    _risk(session, intent.dish_name)
    questions = []
    if intent.servings is None:
        questions.append(
            Question(key="servings", text="做几人份？可以跳过，默认 2 人份。", default="2")
        )
    if not intent.cookware:
        questions.append(
            Question(
                key="cookware", text="有什么厨具？可以跳过，默认常用锅具。", default="常用锅具"
            )
        )
    row = GenerationRequest(
        user_id=owner.id,
        text=request,
        intent=intent.model_dump(mode="json"),
        questions=[q.model_dump() for q in questions],
    )
    session.add(row)
    session.commit()
    results = _similar(session, settings, owner, intent)
    constraints = intent.model_dump(mode="json")
    if fallback and intent.dish_name == request[:200]:
        constraints["dish_name"] = "未识别菜名"
    record_event(session, redis, owner, row.id, "request", {"constraints": constraints})
    status = AIStatus.model_validate(gateway.availability(session, settings, owner.id))
    if failure:
        status.available = False
        status.reason = failure
    return RetrievalResult(
        request_id=row.id,
        text=request,
        intent=intent,
        recipes=results,
        questions=questions,
        status=status,
        local_fallback=fallback,
    )


def owned_request(session: Session, owner: User, request_id: uuid.UUID) -> GenerationRequest:
    row = session.scalar(
        select(GenerationRequest).where(
            GenerationRequest.id == request_id, GenerationRequest.user_id == owner.id
        )
    )
    if row is None:
        raise NotFound()
    return row


def choose_existing(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    request_id: uuid.UUID,
    recipe_id: uuid.UUID,
):
    row = owned_request(session, owner, request_id)
    detail = recipes.get_recipe(session, settings, owner, recipe_id)
    row.selected_recipe_id = recipe_id
    session.commit()
    record_event(
        session,
        redis,
        owner,
        request_id,
        "choice",
        {"choice": "existing", "recipe_id": str(recipe_id)},
    )
    return detail


def _json_model(value: Any) -> GeneratedDraft:
    return (
        GeneratedDraft.model_validate_json(value)
        if isinstance(value, str)
        else GeneratedDraft.model_validate(value)
    )


def _normalize(
    session: Session,
    settings: Settings,
    owner: User,
    draft: GeneratedDraft,
    operation_id: uuid.UUID,
) -> list[str]:
    ingredients = draft.recipe.snapshot.ingredients
    matches = matching.normalize(session, [i.display_name for i in ingredients])
    unresolved = [
        i.display_name
        for i, m in zip(ingredients, matches, strict=True)
        if m.confidence not in ("exact", "alias")
    ]
    decisions: dict[str, Any] = {}
    if unresolved:
        candidates = sorted({c.standard_name for m in matches for c in m.candidates})
        try:
            raw = gateway.call(
                session,
                settings,
                owner.id,
                "normalize",
                {"names": unresolved, "candidates": candidates},
                operation_id,
            )
            value = json.loads(raw) if isinstance(raw, str) else raw
            decisions = {d["name"]: d for d in value["matches"]}
        except (gateway.Unavailable, ValueError, TypeError, KeyError):
            pass
    confirmations = []
    for item, match in zip(ingredients, matches, strict=True):
        # Ignore UUIDs invented by the model. Only library matches may supply them.
        item.ingredient_id = None
        if match.confidence in ("exact", "alias") and match.ingredient:
            item.ingredient_id = match.ingredient.id
        else:
            decision = decisions.get(item.display_name, {})
            name = decision.get("standard_name")
            confidence = decision.get("confidence", 0)
            if (
                isinstance(confidence, (int, float))
                and 0.9 <= confidence <= 1
                and isinstance(name, str)
            ):
                accepted = matching.normalize(session, [name])[0]
                if accepted.confidence == "exact" and accepted.ingredient:
                    # Ambiguities must resolve to one of the known candidates.
                    allowed = not match.candidates or accepted.ingredient.id in {
                        c.id for c in match.candidates
                    }
                    if allowed:
                        item.ingredient_id = accepted.ingredient.id
            if item.ingredient_id is None:
                confirmations.append(f"{item.display_name}：请确认食材；无法匹配时按未收录食材保存")
    return confirmations


def _validate_draft(session: Session, draft: GeneratedDraft, intent: RecipeIntent):
    snapshot = draft.recipe.snapshot
    if (
        not snapshot.ingredients
        or not snapshot.steps
        or not snapshot.dish_type
        or not snapshot.tags
    ):
        raise ValueError("需要食材、步骤、菜型和标签")
    if snapshot.servings != intent.servings:
        raise ValueError("人数与请求不一致")
    for step in snapshot.steps:
        if not step.why or step.duration_seconds <= 0 or not step.cookware:
            raise ValueError("每步需要原理、具体时长和厨具")
    for ingredient in snapshot.ingredients:
        if ingredient.quantity <= 0:
            raise ValueError("食材用量必须为正数")
    snapshot = recipes._validate_snapshot(session, snapshot)
    draft.recipe.snapshot = snapshot
    result = food_safety.check(
        session,
        snapshot,
        draft.recipe.dish_input().name,
        descriptions=[
            draft.rationale,
            draft.cuisine,
            draft.recipe.change_note,
            *draft.recipe.dish_aliases,
        ],
    )
    if result.high_risk:
        raise ApiError(422, "unsafe_ai_output", "AI 不能生成高风险菜谱")
    if not result.can_save:
        raise ValueError("禁止疗效措辞：" + "、".join(result.prohibited_claims))
    if ("不辣" in intent.taste or "不辣" in intent.restrictions) and any(
        "辣椒" in i.display_name or "辣椒" in (i.preparation or "") for i in snapshot.ingredients
    ):
        raise ValueError("不辣的请求不能加入辣椒")
    return result


def _mark_sources(draft: GeneratedDraft) -> None:
    source = ValueSource(source="ai_estimated", basis="一般经验；尚未做过验证")
    draft.recipe.ai_assisted = True
    draft.recipe.snapshot.cuisine = draft.cuisine
    draft.recipe.snapshot.design_rationale = draft.rationale
    draft.recipe.snapshot.text_source = source
    draft.recipe.snapshot.servings_source = source
    for item in draft.recipe.snapshot.ingredients:
        item.quantity_source = source
    for step in draft.recipe.snapshot.steps:
        step.duration_source = source
        step.heat_source = source if step.heat else None
        step.temperature_source = source if step.temperature_celsius is not None else None


def numeric_warnings(draft: GeneratedDraft) -> list[str]:
    from pathlib import Path

    policy = json.loads(
        Path(__file__)
        .with_name("data")
        .joinpath("numeric_guardrails.json")
        .read_text(encoding="utf-8")
    )
    quantities = {
        i.display_name: i.base_quantity
        for i in draft.recipe.snapshot.ingredients
        if i.base_unit == "g"
    }
    warnings = []
    for rule in policy["rules"]:
        numerator = sum(
            float(q or 0)
            for name, q in quantities.items()
            if any(t in name for t in rule["numerator_terms"])
        )
        denominator = sum(
            float(q or 0)
            for name, q in quantities.items()
            if (
                any(t in name for t in rule["denominator_terms"])
                if rule["denominator_terms"]
                else not any(t in name for t in rule["numerator_terms"])
            )
        )
        if denominator and numerator / denominator > rule["maximum_ratio"]:
            warnings.append(rule["message"])
    return warnings


def generate(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    request_id: uuid.UUID,
    answers: GenerateInput,
) -> GenerationResult:
    row = owned_request(session, owner, request_id)
    if row.saved_recipe_id:
        raise ApiError(409, "generation_already_saved", "这份生成结果已经保存")
    intent = RecipeIntent.model_validate(row.intent)
    intent.servings = answers.servings or intent.servings or 2
    if answers.cookware:
        intent.cookware = [answers.cookware]
    _risk(session, row.text)
    _risk(session, intent.dish_name)
    payload = {
        "text": row.text,
        "intent": intent.model_dump(mode="json"),
        "profile": None,
        "family": None,
        "cookware_profile": None,
    }
    record_event(session, redis, owner, request_id, "choice", {"choice": "new"})
    record_event(
        session, redis, owner, request_id, "questions", {"answers": answers.model_dump(mode="json")}
    )
    operation_id = uuid.uuid4()
    confirmations = []
    try:
        for repair in range(2):
            raw = gateway.call(
                session,
                settings,
                owner.id,
                "generate",
                payload,
                operation_id,
                content_id=request_id,
            )
            try:
                draft = _json_model(raw)
                confirmations = _normalize(session, settings, owner, draft, operation_id)
                _mark_sources(draft)
                safety = _validate_draft(session, draft, intent)
                break
            except (ValueError, ApiError) as exc:
                if isinstance(exc, ApiError) and exc.code == "unsafe_ai_output":
                    raise
                if repair:
                    raise gateway.Unavailable("invalid_output") from exc
                if isinstance(exc, ValidationError):
                    errors = [
                        ".".join(str(p) for p in e["loc"]) + ":" + e["type"] for e in exc.errors()
                    ]
                else:
                    errors = [str(exc)]
                payload = {**payload, "repair": {"errors": errors, "previous": raw}}
        else:
            raise gateway.Unavailable("invalid_output")
        row.draft = draft.model_dump(mode="json")
        session.commit()
        record_event(session, redis, owner, request_id, "result", {"saved": False})
        return GenerationResult(
            request_id=request_id,
            status=AIStatus.model_validate(gateway.availability(session, settings, owner.id)),
            draft=draft,
            safety=safety,
            numeric_warnings=numeric_warnings(draft),
            ingredient_confirmations=confirmations,
        )
    except gateway.Unavailable as exc:
        return GenerationResult(
            request_id=request_id,
            status=AIStatus(
                remaining=gateway.availability(session, settings, owner.id)["remaining"],
                available=False,
                reason=exc.reason,
            ),
            error=exc.reason,
        )


def save(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    request_id: uuid.UUID,
    body: RecipeCreate,
):
    row = session.scalar(
        select(GenerationRequest)
        .where(GenerationRequest.id == request_id, GenerationRequest.user_id == owner.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if row is None:
        raise NotFound()
    if row.saved_recipe_id:
        return recipes.get_recipe(session, settings, owner, row.saved_recipe_id)
    if not row.draft:
        raise ApiError(409, "generation_required", "请先生成并检查菜谱")
    body.ai_assisted = True
    original = GeneratedDraft.model_validate(row.draft)
    # Keep server-owned provenance. Edited fields get author attribution while
    # the recipe remains AI-assisted; callers cannot erase the AI origin.
    body.snapshot.cuisine = original.cuisine
    body.snapshot.design_rationale = original.rationale
    body.snapshot.text_source = original.recipe.snapshot.text_source
    body.snapshot.servings_source = (
        original.recipe.snapshot.servings_source
        if body.snapshot.servings == original.recipe.snapshot.servings
        else ValueSource(source="author_filled")
    )
    old_items = {i.id: i for i in original.recipe.snapshot.ingredients}
    for item in body.snapshot.ingredients:
        old = old_items.get(item.id)
        item.quantity_source = (
            old.quantity_source
            if old
            and (old.quantity, old.unit, old.display_name)
            == (item.quantity, item.unit, item.display_name)
            else ValueSource(source="author_filled")
        )
    old_steps = {s.id: s for s in original.recipe.snapshot.steps}
    for step in body.snapshot.steps:
        old = old_steps.get(step.id)
        for field, source_field in (
            ("duration_seconds", "duration_source"),
            ("heat", "heat_source"),
            ("temperature_celsius", "temperature_source"),
        ):
            setattr(
                step,
                source_field,
                getattr(old, source_field)
                if old and getattr(step, field) == getattr(old, field)
                else ValueSource(source="author_filled"),
            )
    safety = food_safety.check(session, body.snapshot, body.dish_input().name)
    if safety.high_risk:
        raise ApiError(422, "unsafe_ai_output", "AI 辅助菜谱不能保存高风险食材")
    detail = recipes.create_recipe(
        session, redis, settings, owner, body, generation_request_id=request_id
    )
    record_event(
        session,
        redis,
        owner,
        request_id,
        "result",
        {"saved": True, "recipe_id": str(detail.id), "version_id": str(detail.version.id)},
    )
    return detail
