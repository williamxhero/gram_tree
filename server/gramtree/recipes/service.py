"""菜谱持久化、结构校验、派生信息和私有可见性规则。"""

from __future__ import annotations

import hashlib
import hmac
import io
import logging
import uuid
from collections.abc import Iterable
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from redis import Redis
from sqlalchemy import delete, or_, select, update
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError, NotFound
from gramtree.core.pagination import decode_cursor, encode_cursor
from gramtree.core.time import utcnow
from gramtree.events import service as event_service
from gramtree.ingredients.attributes import IngredientAttributes
from gramtree.ingredients.models import Ingredient, IngredientAttribute
from gramtree.recipes.models import (
    Dish,
    DishAlias,
    Recipe,
    RecipeImage,
    RecipeSaveOutbox,
    RecipeVersion,
)
from gramtree.recipes.schemas import (
    DishInput,
    DishOut,
    NutritionEstimate,
    RecipeAuthor,
    RecipeCreate,
    RecipeDerived,
    RecipeDetail,
    RecipeImageOut,
    RecipeIngredient,
    RecipeList,
    RecipeListItem,
    RecipeSnapshot,
    RecipeVersionCreate,
    RecipeVersionHistory,
    RecipeVersionOut,
    RecipeVersionSummary,
)
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.recipes")

# Common kitchen units. The stored base unit is always g, ml or count.
_MASS_UNITS = {"g": 1.0, "克": 1.0, "kg": 1000.0, "千克": 1000.0, "公斤": 1000.0}
_VOLUME_UNITS = {"ml": 1.0, "毫升": 1.0, "l": 1000.0, "升": 1000.0}
_COUNT_UNITS = {"个", "只", "颗", "粒", "瓣", "头", "根", "条", "片", "块", "张", "棵", "朵", "枚"}
_VOLUME_SPOONS = {
    "勺": 15.0,
    "大勺": 15.0,
    "汤匙": 15.0,
    "tbsp": 15.0,
    "小勺": 5.0,
    "茶匙": 5.0,
    "tsp": 5.0,
}
_MAX_IMAGE_BYTES = 15 * 1024 * 1024
_SIGNED_URL_TTL = 900


def _clean_dish_input(value: DishInput) -> DishInput:
    aliases = [alias for alias in value.aliases if alias != value.name]
    return DishInput(name=value.name, aliases=list(dict.fromkeys(aliases)))


def _find_dish(session: Session, names: Iterable[str]) -> Dish | None:
    names = list(names)
    row = session.scalars(select(Dish).where(Dish.name.in_(names))).first()
    if row is not None:
        return row
    return session.scalars(select(Dish).join(DishAlias).where(DishAlias.alias.in_(names))).first()


def _dish(session: Session, value: DishInput) -> Dish:
    value = _clean_dish_input(value)
    row = _find_dish(session, [value.name, *value.aliases])
    if row is None:
        row = Dish(name=value.name)
        session.add(row)
        session.flush()
    elif row.name != value.name:
        existing_name = session.scalar(select(Dish).where(Dish.name == value.name))
        if existing_name is not None and existing_name.id != row.id:
            raise ApiError(409, "dish_name_taken", "这个菜名已经属于另一道菜")

    for alias in value.aliases:
        if alias == row.name:
            continue
        existing = session.scalar(select(DishAlias).where(DishAlias.alias == alias))
        if existing is not None:
            if existing.dish_id != row.id:
                raise ApiError(409, "dish_alias_taken", "这个菜名别名已经属于另一道菜")
            continue
        session.add(DishAlias(dish_id=row.id, alias=alias))
    session.flush()
    return row


def _ingredient_attributes(session: Session, ingredient_id: uuid.UUID) -> IngredientAttributes:
    rows = session.scalars(
        select(IngredientAttribute).where(IngredientAttribute.ingredient_id == ingredient_id)
    )
    return IngredientAttributes.from_stored(
        {row.field: (row.value, row.source, row.status) for row in rows}
    )


def _base_quantity(session: Session, ingredient: RecipeIngredient) -> tuple[float, str]:
    """Convert a kitchen quantity to g/ml/count and reject unknown conversions."""
    unit = ingredient.unit.strip().casefold()
    if unit in _MASS_UNITS:
        return ingredient.quantity * _MASS_UNITS[unit], "g"
    if unit in _VOLUME_UNITS:
        return ingredient.quantity * _VOLUME_UNITS[unit], "ml"
    if unit in _VOLUME_SPOONS:
        return ingredient.quantity * _VOLUME_SPOONS[unit], "ml"
    if unit in _COUNT_UNITS:
        if ingredient.ingredient_id is None:
            return ingredient.quantity, "count"
        attributes = _ingredient_attributes(session, ingredient.ingredient_id)
        if attributes.count_units is not None:
            for item in attributes.count_units.value:
                if item.unit == ingredient.unit:
                    return ingredient.quantity * item.grams, "g"
        return ingredient.quantity, "count"
    if ingredient.ingredient_id is not None:
        attributes = _ingredient_attributes(session, ingredient.ingredient_id)
        if attributes.base_unit is not None and attributes.base_unit.value == "克":
            raise ApiError(
                422,
                "invalid_recipe",
                "菜谱结构有误",
                f"ingredients[{ingredient.id}].unit 无法换算为克：{ingredient.unit}",
            )
    raise ApiError(
        422,
        "invalid_recipe",
        "菜谱结构有误",
        f"ingredients[{ingredient.id}].unit 不支持：{ingredient.unit}",
    )


def _normalize_ingredient(session: Session, ingredient: RecipeIngredient) -> RecipeIngredient:
    base_quantity, base_unit = _base_quantity(session, ingredient)
    return ingredient.model_copy(update={"base_quantity": base_quantity, "base_unit": base_unit})


def _validate_snapshot(session: Session, snapshot: RecipeSnapshot) -> RecipeSnapshot:
    ingredient_ids = [ingredient.id for ingredient in snapshot.ingredients]
    if len(set(ingredient_ids)) != len(ingredient_ids):
        raise ApiError(422, "invalid_recipe", "菜谱结构有误", "ingredients.id 不能重复")
    standard_ids = {
        item.ingredient_id for item in snapshot.ingredients if item.ingredient_id is not None
    }
    missing = [
        str(ingredient_id)
        for ingredient_id in standard_ids
        if session.get(Ingredient, ingredient_id) is None
    ]
    if missing:
        raise ApiError(
            422,
            "invalid_recipe",
            "菜谱结构有误",
            f"ingredients.ingredient_id 不存在：{', '.join(missing)}",
        )

    normalized_ingredients = [
        _normalize_ingredient(session, ingredient) for ingredient in snapshot.ingredients
    ]
    step_ids = [step.id for step in snapshot.steps]
    if len(set(step_ids)) != len(step_ids):
        raise ApiError(422, "invalid_recipe", "菜谱结构有误", "steps.id 不能重复")
    known_steps = set(step_ids)
    known_ingredients = set(ingredient_ids)
    for index, step in enumerate(snapshot.steps):
        missing_refs = set(step.ingredient_ids) - known_ingredients
        if missing_refs:
            raise ApiError(
                422,
                "invalid_recipe",
                "菜谱结构有误",
                (
                    f"steps[{index}].ingredient_ids 引用了不存在的食材："
                    f"{', '.join(sorted(missing_refs))}"
                ),
            )
        missing_deps = set(step.depends_on) - known_steps
        if missing_deps:
            raise ApiError(
                422,
                "invalid_recipe",
                "菜谱结构有误",
                f"steps[{index}].depends_on 依赖了不存在的步骤：{', '.join(sorted(missing_deps))}",
            )
        if step.id in step.depends_on:
            raise ApiError(
                422,
                "invalid_recipe",
                "菜谱结构有误",
                f"steps[{index}].depends_on 不能依赖自己：{step.id}",
            )

    edges = {step.id: set(step.depends_on) for step in snapshot.steps}
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(step_id: str) -> None:
        if step_id in visiting:
            raise ApiError(
                422,
                "invalid_recipe",
                "菜谱结构有误",
                f"steps[{step_id}].depends_on 形成循环依赖",
            )
        if step_id in visited:
            return
        visiting.add(step_id)
        for dependency in edges[step_id]:
            visit(dependency)
        visiting.remove(step_id)
        visited.add(step_id)

    for step_id in edges:
        visit(step_id)
    return snapshot.model_copy(update={"ingredients": normalized_ingredients})


def _ingredient_data(session: Session, ingredient_id: uuid.UUID) -> IngredientAttributes:
    try:
        return _ingredient_attributes(session, ingredient_id)
    except Exception:
        return IngredientAttributes.from_stored_empty()


def _derived(session: Session, snapshot: RecipeSnapshot) -> RecipeDerived:
    finish: dict[str, int] = {}
    step_by_id = {step.id: step for step in snapshot.steps}

    def finish_at(step_id: str) -> int:
        if step_id in finish:
            return finish[step_id]
        step = step_by_id[step_id]
        value = step.duration_seconds + max(
            (finish_at(dependency) for dependency in step.depends_on), default=0
        )
        finish[step_id] = value
        return value

    total = max((finish_at(step.id) for step in snapshot.steps), default=0)
    active = sum(step.duration_seconds for step in snapshot.steps if not step.unattended)
    total = snapshot.total_time_seconds or total
    active = snapshot.active_time_seconds or active
    cookware = sorted({step.cookware for step in snapshot.steps if step.cookware})

    allergens: set[str] = set()
    allergens_incomplete = False
    nutrition_totals = {
        field: 0.0 for field in ("energy_kcal", "protein_g", "fat_g", "carbohydrate_g", "sodium_mg")
    }
    nutrition_available = False
    nutrition_incomplete = False
    for item in snapshot.ingredients:
        if item.ingredient_id is None or item.base_quantity is None:
            allergens_incomplete = True
            nutrition_incomplete = True
            continue
        attrs = _ingredient_data(session, item.ingredient_id)
        if attrs.allergens is None:
            allergens_incomplete = True
        else:
            allergens.update(attrs.allergens.value)
        if attrs.nutrition is None:
            nutrition_incomplete = True
            continue
        if item.base_unit == "g":
            grams = item.base_quantity
        elif item.base_unit == "ml" and attrs.density is not None:
            grams = item.base_quantity * attrs.density.value
        else:
            nutrition_incomplete = True
            continue
        nutrition_available = True
        nutrition = attrs.nutrition.value
        for field in nutrition_totals:
            value = getattr(nutrition, field)
            if value is None:
                nutrition_incomplete = True
            else:
                nutrition_totals[field] += value * grams / 100

    nutrition = None
    if nutrition_available or snapshot.ingredients:
        nutrition = NutritionEstimate(
            **{
                field: round(value / snapshot.servings, 2)
                for field, value in nutrition_totals.items()
            },
            estimated=True,
            incomplete=nutrition_incomplete,
        )
    return RecipeDerived(
        total_time_seconds=total,
        active_time_seconds=active,
        cookware=cookware,
        allergens=sorted(allergens),
        allergens_incomplete=allergens_incomplete,
        nutrition_per_serving=nutrition,
    )


def _dish_out(session: Session, dish: Dish) -> DishOut:
    aliases = list(
        session.scalars(
            select(DishAlias.alias).where(DishAlias.dish_id == dish.id).order_by(DishAlias.alias)
        )
    )
    return DishOut(id=dish.id, name=dish.name, aliases=aliases)


def _image_secret(settings: Settings) -> str:
    """Use an explicit image secret in deployed environments; dev derives it safely."""
    return settings.image_signing_secret or settings.auth_secret


def _signed_url(settings: Settings, recipe_id: uuid.UUID, image_id: uuid.UUID) -> str:
    expires = int((datetime.now(UTC) + timedelta(seconds=_SIGNED_URL_TTL)).timestamp())
    payload = f"{recipe_id}:{image_id}:{expires}".encode()
    signature = hmac.new(
        _image_secret(settings).encode(), payload, hashlib.sha256
    ).hexdigest()
    return f"/v1/recipes/{recipe_id}/images/{image_id}?expires={expires}&signature={signature}"


def _image_out(settings: Settings, row: RecipeImage) -> RecipeImageOut:
    return RecipeImageOut(
        id=row.id,
        version_id=row.version_id,
        content_type=row.content_type,
        byte_size=row.byte_size,
        width=row.width,
        height=row.height,
        url=_signed_url(settings, row.recipe_id, row.id),
        expires_in_seconds=_SIGNED_URL_TTL,
    )


def _version_out(
    session: Session, settings: Settings, row: RecipeVersion, recipe_id: uuid.UUID
) -> RecipeVersionOut:
    images = list(
        session.scalars(
            select(RecipeImage)
            .where(RecipeImage.version_id == row.id)
            .order_by(RecipeImage.created_at)
        )
    )
    return RecipeVersionOut(
        id=row.id,
        version_number=row.version_number,
        previous_version_id=row.previous_version_id,
        snapshot=RecipeSnapshot.model_validate(row.snapshot),
        derived=RecipeDerived.model_validate(row.derived),
        edit_operations=row.edit_operations or [],
        change_note=row.change_note,
        ai_assisted=row.ai_assisted,
        created_at=row.created_at,
        images=[_image_out(settings, image) for image in images],
    )


def _detail(
    session: Session,
    settings: Settings,
    recipe: Recipe,
    version: RecipeVersion | None = None,
) -> RecipeDetail:
    dish = session.get(Dish, recipe.dish_id)
    author = session.get(User, recipe.owner_id)
    version = version or session.get(RecipeVersion, recipe.current_version_id)
    if dish is None or author is None or version is None:
        raise NotFound("菜谱关联数据不存在")
    return RecipeDetail(
        id=recipe.id,
        dish=_dish_out(session, dish),
        author=RecipeAuthor(id=author.id, nickname=author.nickname),
        visibility="private",
        source_version_id=recipe.source_version_id,
        root_recipe_id=recipe.root_recipe_id,
        created_at=recipe.created_at,
        updated_at=recipe.updated_at,
        version=_version_out(session, settings, version, recipe.id),
    )


def _snapshot_json(snapshot: RecipeSnapshot) -> dict[str, Any]:
    return snapshot.model_dump(mode="json")


def _enqueue_save_event(session: Session, owner: User, recipe: Recipe, version: RecipeVersion) -> None:
    session.add(
        RecipeSaveOutbox(
            recipe_id=recipe.id,
            version_id=version.id,
            owner_id=owner.id,
            previous_version_id=version.previous_version_id,
            edit_operations=version.edit_operations,
            ai_assisted=version.ai_assisted,
        )
    )


def _drain_save_events(session: Session, redis: Redis, owner: User) -> None:
    """Best-effort delivery with a durable row left for the next save to retry."""
    pending = list(
        session.scalars(
            select(RecipeSaveOutbox)
            .where(RecipeSaveOutbox.owner_id == owner.id, RecipeSaveOutbox.delivered_at.is_(None))
            .order_by(RecipeSaveOutbox.created_at)
        )
    )
    for outbox in pending:
        try:
            event_service.record_recipe_version_saved(
                session,
                redis,
                owner.id,
                outbox.version_id,
                outbox.previous_version_id,
                outbox.edit_operations,
                outbox.ai_assisted,
                now=outbox.created_at,
            )
            outbox.delivered_at = utcnow()
            session.commit()
        except Exception:
            logger.warning("recipe save event delivery deferred", exc_info=True)
            session.rollback()
            return


def create_recipe(
    session: Session, redis: Redis, settings: Settings, owner: User, body: RecipeCreate
) -> RecipeDetail:
    snapshot = _validate_snapshot(session, body.snapshot)
    dish = _dish(session, body.dish_input())
    recipe = Recipe(dish_id=dish.id, owner_id=owner.id, visibility="private")
    session.add(recipe)
    session.flush()
    version = RecipeVersion(
        recipe_id=recipe.id,
        version_number=1,
        snapshot=_snapshot_json(snapshot),
        derived=_derived(session, snapshot).model_dump(mode="json"),
        edit_operations=[],
        change_note=body.change_note,
        ai_assisted=body.ai_assisted,
    )
    session.add(version)
    session.flush()
    recipe.current_version_id = version.id
    recipe.updated_at = version.created_at
    _enqueue_save_event(session, owner, recipe, version)
    session.commit()
    _drain_save_events(session, redis, owner)
    return _detail(session, settings, recipe, version)


def _owned_recipe(session: Session, owner: User, recipe_id: uuid.UUID) -> Recipe:
    row = session.scalar(select(Recipe).where(Recipe.id == recipe_id, Recipe.owner_id == owner.id))
    if row is None:
        # Do not disclose whether a private recipe exists under another owner.
        raise NotFound()
    return row


def _value_for_diff(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if isinstance(value, list):
        return [_value_for_diff(item) for item in value]
    return value


def _operations(previous: RecipeSnapshot, current: RecipeSnapshot) -> list[dict[str, Any]]:
    operations: list[dict[str, Any]] = []
    previous_ingredients = {item.id: item for item in previous.ingredients}
    current_ingredients = {item.id: item for item in current.ingredients}
    for item_id in previous_ingredients.keys() - current_ingredients.keys():
        operations.append(
            {
                "type": "remove_ingredient",
                "id": item_id,
                "before": _value_for_diff(previous_ingredients[item_id]),
                "intent": "作者手动修改",
            }
        )
    for item_id in current_ingredients.keys() - previous_ingredients.keys():
        operations.append(
            {
                "type": "add_ingredient",
                "id": item_id,
                "after": _value_for_diff(current_ingredients[item_id]),
                "intent": "作者手动修改",
            }
        )
    for item_id in previous_ingredients.keys() & current_ingredients.keys():
        before = _value_for_diff(previous_ingredients[item_id])
        after = _value_for_diff(current_ingredients[item_id])
        if before != after:
            operations.append(
                {
                    "type": "change_ingredient",
                    "id": item_id,
                    "before": before,
                    "after": after,
                    "intent": "作者手动修改",
                }
            )
    previous_steps = {item.id: item for item in previous.steps}
    current_steps = {item.id: item for item in current.steps}
    for item_id in previous_steps.keys() - current_steps.keys():
        operations.append(
            {
                "type": "remove_step",
                "id": item_id,
                "before": _value_for_diff(previous_steps[item_id]),
                "intent": "作者手动修改",
            }
        )
    for item_id in current_steps.keys() - previous_steps.keys():
        operations.append(
            {
                "type": "add_step",
                "id": item_id,
                "after": _value_for_diff(current_steps[item_id]),
                "intent": "作者手动修改",
            }
        )
    for item_id in previous_steps.keys() & current_steps.keys():
        before = _value_for_diff(previous_steps[item_id])
        after = _value_for_diff(current_steps[item_id])
        if before != after:
            operations.append(
                {
                    "type": "change_step",
                    "id": item_id,
                    "before": before,
                    "after": after,
                    "intent": "作者手动修改",
                }
            )
    if [item.id for item in previous.ingredients] != [item.id for item in current.ingredients]:
        operations.append(
            {
                "type": "reorder_ingredients",
                "before": [item.id for item in previous.ingredients],
                "after": [item.id for item in current.ingredients],
                "intent": "作者手动修改",
            }
        )
    if [item.id for item in previous.steps] != [item.id for item in current.steps]:
        operations.append(
            {
                "type": "reorder_steps",
                "before": [item.id for item in previous.steps],
                "after": [item.id for item in current.steps],
                "intent": "作者手动修改",
            }
        )
    for field in (
        "servings",
        "total_time_seconds",
        "active_time_seconds",
        "difficulty",
        "dish_type",
        "tags",
    ):
        before = _value_for_diff(getattr(previous, field))
        after = _value_for_diff(getattr(current, field))
        if before != after:
            operations.append(
                {
                    "type": "change_recipe_info",
                    "field": field,
                    "before": before,
                    "after": after,
                    "intent": "作者手动修改",
                }
            )
    return operations


def save_version(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    body: RecipeVersionCreate,
) -> RecipeDetail:
    recipe = _owned_recipe(session, owner, recipe_id)
    snapshot = _validate_snapshot(session, body.snapshot)
    previous = session.get(RecipeVersion, recipe.current_version_id)
    if previous is None:
        raise NotFound("菜谱当前版本不存在")
    baseline = session.get(RecipeVersion, body.base_version_id or previous.id)
    if baseline is None or baseline.recipe_id != recipe.id:
        raise NotFound("菜谱基准版本不存在")
    previous_snapshot = RecipeSnapshot.model_validate(baseline.snapshot)
    version = RecipeVersion(
        recipe_id=recipe.id,
        version_number=previous.version_number + 1,
        previous_version_id=previous.id,
        snapshot=_snapshot_json(snapshot),
        derived=_derived(session, snapshot).model_dump(mode="json"),
        edit_operations=_operations(previous_snapshot, snapshot),
        change_note=body.change_note,
        ai_assisted=body.ai_assisted,
    )
    session.add(version)
    session.flush()
    recipe.current_version_id = version.id
    recipe.updated_at = version.created_at
    _enqueue_save_event(session, owner, recipe, version)
    session.commit()
    _drain_save_events(session, redis, owner)
    return _detail(session, settings, recipe, version)


def get_recipe(
    session: Session, settings: Settings, owner: User, recipe_id: uuid.UUID
) -> RecipeDetail:
    recipe = _owned_recipe(session, owner, recipe_id)
    return _detail(session, settings, recipe)


def get_version(
    session: Session,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    version_id: uuid.UUID,
) -> RecipeDetail:
    recipe = _owned_recipe(session, owner, recipe_id)
    version = session.scalar(
        select(RecipeVersion).where(
            RecipeVersion.id == version_id, RecipeVersion.recipe_id == recipe.id
        )
    )
    if version is None:
        raise NotFound()
    return _detail(session, settings, recipe, version)


def list_versions(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    *,
    cursor: str | None,
    limit: int,
    maximum: int,
) -> RecipeVersionHistory:
    if limit > maximum:
        raise ApiError(422, "invalid_request", "请求参数有误", f"limit 不能超过 {maximum}")
    recipe = _owned_recipe(session, owner, recipe_id)
    after = decode_cursor(cursor) if cursor else None
    query = select(RecipeVersion).where(RecipeVersion.recipe_id == recipe.id)
    if after is not None:
        timestamp, row_id = after
        query = query.where(
            or_(
                RecipeVersion.created_at < timestamp,
                (RecipeVersion.created_at == timestamp) & (RecipeVersion.id < row_id),
            )
        )
    rows = list(
        session.scalars(
            query.order_by(RecipeVersion.created_at.desc(), RecipeVersion.id.desc()).limit(limit + 1)
        )
    )
    has_more = len(rows) > limit
    rows = rows[:limit]
    return RecipeVersionHistory(
        items=[
            RecipeVersionSummary(
                id=row.id,
                version_number=row.version_number,
                previous_version_id=row.previous_version_id,
                change_note=row.change_note,
                ai_assisted=row.ai_assisted,
                created_at=row.created_at,
            )
            for row in rows
        ],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id)
        if has_more and rows
        else None,
    )


def list_recipes(
    session: Session, owner: User, *, cursor: str | None, limit: int, maximum: int
) -> RecipeList:
    if limit > maximum:
        raise ApiError(422, "invalid_request", "请求参数有误", f"limit 不能超过 {maximum}")
    after = decode_cursor(cursor) if cursor else None
    query = select(Recipe).where(Recipe.owner_id == owner.id)
    if after is not None:
        timestamp, row_id = after
        query = query.where(
            or_(
                Recipe.updated_at < timestamp,
                (Recipe.updated_at == timestamp) & (Recipe.id < row_id),
            )
        )
    rows = list(
        session.scalars(query.order_by(Recipe.updated_at.desc(), Recipe.id.desc()).limit(limit + 1))
    )
    has_more = len(rows) > limit
    rows = rows[:limit]
    items: list[RecipeListItem] = []
    for recipe in rows:
        dish = session.get(Dish, recipe.dish_id)
        version = session.get(RecipeVersion, recipe.current_version_id)
        if dish is None or version is None:
            continue
        snapshot = RecipeSnapshot.model_validate(version.snapshot)
        derived = RecipeDerived.model_validate(version.derived)
        items.append(
            RecipeListItem(
                id=recipe.id,
                dish=_dish_out(session, dish),
                visibility="private",
                version_number=version.version_number,
                servings=snapshot.servings,
                difficulty=snapshot.difficulty,
                total_time_seconds=derived.total_time_seconds,
                active_time_seconds=derived.active_time_seconds,
                updated_at=recipe.updated_at,
            )
        )
    next_cursor = encode_cursor(rows[-1].updated_at, rows[-1].id) if has_more and rows else None
    return RecipeList(items=items, next_cursor=next_cursor)


def delete_recipe(session: Session, owner: User, recipe_id: uuid.UUID, settings: Settings) -> None:
    recipe = _owned_recipe(session, owner, recipe_id)
    images = list(session.scalars(select(RecipeImage).where(RecipeImage.recipe_id == recipe.id)))
    for image in images:
        _delete_storage_file(settings, image.storage_key)
    # current_version_id points into the versions table; clear it before deleting snapshots.
    session.execute(update(Recipe).where(Recipe.id == recipe.id).values(current_version_id=None))
    session.execute(delete(RecipeImage).where(RecipeImage.recipe_id == recipe.id))
    session.execute(delete(RecipeVersion).where(RecipeVersion.recipe_id == recipe.id))
    session.delete(recipe)
    session.commit()


def _storage_path(settings: Settings, key: str) -> Path:
    root = Path(settings.recipe_media_dir)
    path = (root / key).resolve()
    if root.resolve() not in path.parents:
        raise ApiError(500, "storage_error", "图片存储配置有误")
    return path


def _delete_storage_file(settings: Settings, key: str) -> None:
    try:
        _storage_path(settings, key).unlink(missing_ok=True)
    except OSError:
        logger.warning("could not delete recipe image", extra={"storage_key": key}, exc_info=True)


def _sanitize_image(content: bytes, content_type: str) -> tuple[bytes, str, int, int]:
    if len(content) > _MAX_IMAGE_BYTES:
        raise ApiError(422, "image_too_large", "图片太大，请选择 15 MB 以内的图片")
    try:
        from PIL import Image

        source = Image.open(io.BytesIO(content))
        source.verify()
        source = Image.open(io.BytesIO(content))
        source.load()
    except (ImportError, OSError, ValueError) as exc:
        raise ApiError(422, "unsafe_image", "图片无法安全处理，请换一张图片") from exc
    if source.format not in {"JPEG", "PNG", "WEBP"}:
        raise ApiError(422, "unsupported_image", "只支持 JPG、PNG 或 WebP 图片")
    source.thumbnail((2048, 2048))
    width, height = source.size
    # Rebuild the image instead of copying metadata; this removes EXIF GPS and comments.
    if source.mode not in {"RGB", "RGBA"}:
        source = source.convert("RGBA")
    output = io.BytesIO()
    if source.mode == "RGBA":
        source.save(output, format="PNG", optimize=True)
        result_type = "image/png"
    else:
        source.save(output, format="JPEG", quality=85, optimize=True, exif=b"")
        result_type = "image/jpeg"
    return output.getvalue(), result_type, width, height


def save_image(
    session: Session,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    content: bytes,
    content_type: str,
    version_id: uuid.UUID | None = None,
) -> RecipeImageOut:
    recipe = _owned_recipe(session, owner, recipe_id)
    version = session.get(RecipeVersion, version_id or recipe.current_version_id)
    if version is None or version.recipe_id != recipe.id:
        raise NotFound("菜谱版本不存在")
    normalized, actual_type, width, height = _sanitize_image(content, content_type)
    image_id = uuid.uuid4()
    extension = "png" if actual_type == "image/png" else "jpg"
    key = f"recipes/{owner.id}/{recipe.id}/{version.id}/{image_id}.{extension}"
    path = _storage_path(settings, key)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(normalized)
        image = RecipeImage(
            id=image_id,
            recipe_id=recipe.id,
            version_id=version.id,
            storage_key=key,
            content_type=actual_type,
            byte_size=len(normalized),
            width=width,
            height=height,
        )
        session.add(image)
        session.commit()
    except OSError as exc:
        session.rollback()
        raise ApiError(503, "storage_unavailable", "图片暂时无法保存，请稍后再试") from exc
    return _image_out(settings, image)


def signed_image_file(
    session: Session,
    settings: Settings,
    recipe_id: uuid.UUID,
    image_id: uuid.UUID,
    expires: int,
    signature: str,
) -> tuple[Path, str]:
    payload = f"{recipe_id}:{image_id}:{expires}".encode()
    expected = hmac.new(_image_secret(settings).encode(), payload, hashlib.sha256).hexdigest()
    if expires < int(datetime.now(UTC).timestamp()) or not hmac.compare_digest(signature, expected):
        raise NotFound()
    image = session.scalar(
        select(RecipeImage).where(RecipeImage.id == image_id, RecipeImage.recipe_id == recipe_id)
    )
    if image is None:
        raise NotFound()
    path = _storage_path(settings, image.storage_key)
    if not path.is_file():
        raise NotFound()
    return path, image.content_type
