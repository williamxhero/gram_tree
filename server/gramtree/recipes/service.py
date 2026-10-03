"""菜谱持久化、结构校验、派生信息和私有可见性规则。"""

from __future__ import annotations

import hashlib
import hmac
import io
import logging
import uuid
import warnings
from collections.abc import Iterable
from datetime import UTC, datetime, timedelta
from typing import Any, Literal, cast

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
from gramtree.recipes.measure_display import display_amount, quantity_text
from gramtree.recipes.measure_models import PersonalMeasure
from gramtree.recipes.models import (
    Dish,
    DishAlias,
    Recipe,
    RecipeImage,
    RecipeImageStaging,
    RecipeSaveOutbox,
    RecipeVersion,
)
from gramtree.recipes.mold_conversion import (
    ConvertedMoldIngredient,
    MoldConversion,
    MoldConversionError,
    MoldIngredientInput,
    MoldInput,
    MoldStepInput,
    convert_mold,
)
from gramtree.recipes.schemas import (
    DishInput,
    DishOut,
    MoldSpec,
    NutritionEstimate,
    RecipeAuthor,
    RecipeCreate,
    RecipeDerived,
    RecipeDetail,
    RecipeDisplayedIngredient,
    RecipeImageOut,
    RecipeImageStagedOut,
    RecipeIngredient,
    RecipeIngredientDisplay,
    RecipeIngredientDisplayOut,
    RecipeList,
    RecipeListItem,
    RecipeMoldConversionOut,
    RecipeServingConversionOut,
    RecipeSnapshot,
    RecipeVersionCreate,
    RecipeVersionHistory,
    RecipeVersionOut,
    RecipeVersionSummary,
)
from gramtree.recipes.schemas import MoldConversion as MoldConversionSchema
from gramtree.recipes.schemas import (
    ServingConversion as ServingConversionSchema,
)
from gramtree.recipes.serving_conversion import (
    ConvertedIngredient,
    ServingConversion,
    ServingConversionError,
    ServingIngredientInput,
    ServingStepInput,
    convert_servings,
)
from gramtree.recipes.storage import make_recipe_storage
from gramtree.runtime_config import service as config
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
_SCALING_MODE_BY_ATTRIBUTE: dict[str, Literal["proportional", "unchanged", "round"]] = {
    "线性": "proportional",
    "固定": "unchanged",
    "阶梯": "round",
}
_MAX_IMAGE_BYTES = 15 * 1024 * 1024
_MAX_IMAGE_PIXELS = 40_000_000
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


def _effective_scaling_mode(
    session: Session, ingredient: RecipeIngredient
) -> Literal["proportional", "unchanged", "round"]:
    """Resolve an unset recipe mode from the standard ingredient attribute.

    An omitted or null ``scaling_mode`` means the author did not choose one;
    the saved snapshot always stores the resolved mode so a version keeps
    converting the same way even if the ingredient library changes later.
    """
    if ingredient.scaling_mode is not None:
        return ingredient.scaling_mode
    if ingredient.ingredient_id is None:
        return "proportional"
    attributes = _ingredient_data(session, ingredient.ingredient_id)
    if attributes.scaling is None:
        return "proportional"
    return _SCALING_MODE_BY_ATTRIBUTE.get(attributes.scaling.value, "proportional")


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
    return ingredient.model_copy(
        update={
            "base_quantity": base_quantity,
            "base_unit": base_unit,
            "scaling_mode": _effective_scaling_mode(session, ingredient),
        }
    )


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
    replacement_ids = {
        ingredient.replacement.ingredient_id
        for ingredient in snapshot.ingredients
        if ingredient.replacement is not None
        and not isinstance(ingredient.replacement, str)
        and ingredient.replacement.ingredient_id is not None
    }
    missing_replacements = [
        str(ingredient_id)
        for ingredient_id in replacement_ids
        if session.get(Ingredient, ingredient_id) is None
    ]
    if missing_replacements:
        raise ApiError(
            422,
            "invalid_recipe",
            "菜谱结构有误",
            "ingredients.replacement.ingredient_id 不存在：" + ", ".join(missing_replacements),
        )
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
    step_indexes = {step.id: index for index, step in enumerate(snapshot.steps)}
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(step_id: str) -> None:
        if step_id in visiting:
            raise ApiError(
                422,
                "invalid_recipe",
                "菜谱结构有误",
                f"steps[{step_indexes[step_id]}].depends_on 形成循环依赖",
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
    nutrition_totals: dict[str, float | None] = {
        field: 0.0 for field in ("energy_kcal", "protein_g", "fat_g", "carbohydrate_g", "sodium_mg")
    }
    nutrition_available = False
    nutrition_incomplete = False

    def mark_nutrition_unknown() -> None:
        for field in nutrition_totals:
            nutrition_totals[field] = None

    for item in snapshot.ingredients:
        if item.ingredient_id is None or item.base_quantity is None:
            allergens_incomplete = True
            nutrition_incomplete = True
            mark_nutrition_unknown()
            continue
        attrs = _ingredient_data(session, item.ingredient_id)
        if attrs.allergens is None:
            allergens_incomplete = True
        else:
            allergens.update(attrs.allergens.value)
        if attrs.nutrition is None:
            nutrition_incomplete = True
            mark_nutrition_unknown()
            continue
        if item.base_unit == "g":
            grams = item.base_quantity
        elif item.base_unit == "ml" and attrs.density is not None:
            grams = item.base_quantity * attrs.density.value
        else:
            nutrition_incomplete = True
            mark_nutrition_unknown()
            continue
        nutrition_available = True
        nutrition = attrs.nutrition.value
        for field in nutrition_totals:
            value = getattr(nutrition, field)
            if value is None:
                nutrition_incomplete = True
                nutrition_totals[field] = None
            elif nutrition_totals[field] is not None:
                nutrition_totals[field] += value * grams / 100

    nutrition = None
    if nutrition_available or snapshot.ingredients:
        nutrition = NutritionEstimate(
            **{
                field: None if value is None else round(value / snapshot.servings, 2)
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


def _signed_url(
    settings: Settings,
    recipe_id: uuid.UUID,
    image_id: uuid.UUID,
    storage_key: str,
) -> tuple[str, int]:
    expires_in = settings.recipe_image_url_ttl_seconds or _SIGNED_URL_TTL
    storage = make_recipe_storage(settings)
    object_url = storage.signed_get_url(storage_key, expires_in)
    if object_url is not None:
        return object_url, expires_in
    expires = int((datetime.now(UTC) + timedelta(seconds=expires_in)).timestamp())
    payload = f"{recipe_id}:{image_id}:{expires}".encode()
    signature = hmac.new(_image_secret(settings).encode(), payload, hashlib.sha256).hexdigest()
    return (
        f"/v1/recipes/{recipe_id}/images/{image_id}?expires={expires}&signature={signature}",
        expires_in,
    )


def _image_out(settings: Settings, row: RecipeImage) -> RecipeImageOut:
    url, expires_in = _signed_url(settings, row.recipe_id, row.id, row.storage_key)
    return RecipeImageOut(
        id=row.id,
        version_id=row.version_id,
        content_type=row.content_type,
        byte_size=row.byte_size,
        width=row.width,
        height=row.height,
        url=url,
        expires_in_seconds=expires_in,
    )


def _staged_image_out(settings: Settings, row: RecipeImageStaging) -> RecipeImageStagedOut:
    # Staged URLs are only previews for the owner; the object remains private.
    url, expires_in = _staged_signed_url(settings, row.id, row.storage_key)
    return RecipeImageStagedOut(
        id=row.id,
        content_type=row.content_type,
        byte_size=row.byte_size,
        width=row.width,
        height=row.height,
        url=url,
        expires_in_seconds=expires_in,
    )


def _staged_signed_url(
    settings: Settings, image_id: uuid.UUID, storage_key: str
) -> tuple[str, int]:
    expires_in = settings.recipe_image_url_ttl_seconds or _SIGNED_URL_TTL
    storage = make_recipe_storage(settings)
    object_url = storage.signed_get_url(storage_key, expires_in)
    if object_url is not None:
        return object_url, expires_in
    expires = int((datetime.now(UTC) + timedelta(seconds=expires_in)).timestamp())
    payload = f"staged:{image_id}:{expires}".encode()
    signature = hmac.new(_image_secret(settings).encode(), payload, hashlib.sha256).hexdigest()
    return (
        f"/v1/recipes/images/staging/{image_id}?expires={expires}&signature={signature}",
        expires_in,
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


def _staged_rows(
    session: Session, owner: User, image_ids: Iterable[uuid.UUID]
) -> list[RecipeImageStaging]:
    ids = list(dict.fromkeys(image_ids))
    if len(ids) > 10:
        raise ApiError(422, "invalid_image", "图片数量不能超过 10 张")
    if not ids:
        return []
    rows = list(
        session.scalars(
            select(RecipeImageStaging).where(
                RecipeImageStaging.owner_id == owner.id,
                RecipeImageStaging.id.in_(ids),
            )
        )
    )
    if len(rows) != len(ids):
        # Do not disclose whether an ID exists under another account.
        raise NotFound("图片暂存记录不存在")
    by_id = {row.id: row for row in rows}
    return [by_id[image_id] for image_id in ids]


def _attach_staged_images(
    session: Session,
    owner: User,
    recipe: Recipe,
    version: RecipeVersion,
    image_ids: Iterable[uuid.UUID],
) -> list[RecipeImage]:
    staged = _staged_rows(session, owner, image_ids)
    attached: list[RecipeImage] = []
    for row in staged:
        attached_row = RecipeImage(
            id=row.id,
            recipe_id=recipe.id,
            version_id=version.id,
            storage_key=row.storage_key,
            content_type=row.content_type,
            byte_size=row.byte_size,
            width=row.width,
            height=row.height,
            created_at=row.created_at,
        )
        session.add(attached_row)
        session.delete(row)
        attached.append(attached_row)
    return attached


def _storage_key(
    owner_id: uuid.UUID, image_id: uuid.UUID, content_type: str, *, staged: bool
) -> str:
    extension = {"image/png": "png", "image/webp": "webp"}.get(content_type, "jpg")
    prefix = "staging" if staged else "recipes"
    return f"{prefix}/{owner_id}/{image_id}.{extension}"


def _enqueue_save_event(
    session: Session, owner: User, recipe: Recipe, version: RecipeVersion
) -> None:
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


def _drain_save_events(session: Session, redis: Redis, owner: User) -> int:
    """Best-effort delivery with a durable row left for the next save to retry."""
    pending = list(
        session.scalars(
            select(RecipeSaveOutbox)
            .where(RecipeSaveOutbox.owner_id == owner.id, RecipeSaveOutbox.delivered_at.is_(None))
            .order_by(RecipeSaveOutbox.created_at)
        )
    )
    delivered = 0
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
            delivered += 1
        except Exception:
            logger.warning("recipe save event delivery deferred", exc_info=True)
            session.rollback()
            return delivered
    return delivered


def create_recipe(
    session: Session, redis: Redis, settings: Settings, owner: User, body: RecipeCreate
) -> RecipeDetail:
    snapshot = _validate_snapshot(session, body.snapshot)
    staged = _staged_rows(session, owner, body.image_ids)
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
    _attach_staged_images(session, owner, recipe, version, [row.id for row in staged])
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


def _field_operations(
    before: dict[str, Any], after: dict[str, Any], *, item_id: str, kind: str
) -> list[dict[str, Any]]:
    if kind == "ingredient":
        type_by_field = {
            "ingredient_id": "replace_ingredient",
            "display_name": "change_display_name",
            "quantity": "change_quantity",
            "unit": "change_quantity",
            "base_quantity": "change_quantity",
            "base_unit": "change_quantity",
            "preparation": "change_preparation",
            "group": "change_group_or_optional",
            "optional": "change_group_or_optional",
            "functional": "change_functional",
            "scaling_mode": "change_scaling",
            "replacement": "change_replacement",
        }
    else:
        type_by_field = {
            "action": "change_step_field",
            "instruction": "change_step_field",
            "ingredient_ids": "change_step_ingredients",
            "duration_seconds": "change_step_duration",
            "unattended": "change_step_field",
            "heat": "change_step_heat",
            "temperature_celsius": "change_step_heat",
            "cookware": "change_step_field",
            "doneness": "change_step_field",
            "depends_on": "change_step_dependencies",
            "notes": "change_step_field",
            "why": "change_step_field",
        }
    operations = []
    for field, operation_type in type_by_field.items():
        if before.get(field) != after.get(field):
            operations.append(
                {
                    "type": operation_type,
                    "id": item_id,
                    "field": field,
                    "before": before.get(field),
                    "after": after.get(field),
                    "intent": "作者手动修改",
                }
            )
    return operations


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
        operations.extend(
            _field_operations(
                _value_for_diff(previous_ingredients[item_id]),
                _value_for_diff(current_ingredients[item_id]),
                item_id=item_id,
                kind="ingredient",
            )
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
        operations.extend(
            _field_operations(
                _value_for_diff(previous_steps[item_id]),
                _value_for_diff(current_steps[item_id]),
                item_id=item_id,
                kind="step",
            )
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
        "base_mold",
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


def _copy_version_images(
    session: Session, recipe: Recipe, source: RecipeVersion, target: RecipeVersion
) -> None:
    for image in session.scalars(select(RecipeImage).where(RecipeImage.version_id == source.id)):
        session.add(
            RecipeImage(
                id=uuid.uuid4(),
                recipe_id=recipe.id,
                version_id=target.id,
                storage_key=image.storage_key,
                content_type=image.content_type,
                byte_size=image.byte_size,
                width=image.width,
                height=image.height,
                created_at=image.created_at,
            )
        )


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
    staged = _staged_rows(session, owner, body.image_ids)
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
    _copy_version_images(session, recipe, baseline, version)
    _attach_staged_images(session, owner, recipe, version, [row.id for row in staged])
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


def _owned_version(
    session: Session, owner: User, recipe_id: uuid.UUID, version_id: uuid.UUID | None
) -> tuple[Recipe, RecipeVersion]:
    """Resolve an owned recipe and one of its immutable versions (current by default)."""
    recipe = _owned_recipe(session, owner, recipe_id)
    if version_id is None:
        version = session.get(RecipeVersion, recipe.current_version_id)
    else:
        version = session.scalar(
            select(RecipeVersion).where(
                RecipeVersion.id == version_id,
                RecipeVersion.recipe_id == recipe.id,
            )
        )
    if version is None:
        raise NotFound("菜谱版本不存在")
    return recipe, version


def _convert_snapshot_servings(
    session: Session,
    snapshot: RecipeSnapshot,
    derived: RecipeDerived,
    target_servings: int,
) -> ServingConversion:
    try:
        return convert_servings(
            original_servings=snapshot.servings,
            target_servings=target_servings,
            ingredients=[
                ServingIngredientInput(
                    id=item.id,
                    display_name=item.display_name,
                    quantity=item.quantity,
                    unit=item.unit,
                    scaling_mode=_effective_scaling_mode(session, item),
                )
                for item in snapshot.ingredients
            ],
            steps=[
                ServingStepInput(
                    id=step.id,
                    instruction=step.instruction,
                    ingredient_ids=tuple(step.ingredient_ids),
                    duration_seconds=step.duration_seconds,
                    temperature_celsius=step.temperature_celsius,
                    heat=step.heat,
                    unattended=step.unattended,
                    depends_on=tuple(step.depends_on),
                )
                for step in snapshot.steps
            ],
            min_servings=int(config.get(session, "recipe.servings_min")),
            max_servings=int(config.get(session, "recipe.servings_max")),
            round_deviation_threshold=float(
                config.get(session, "recipe.scaling_round_deviation_threshold")
            ),
            batch_multiplier=float(config.get(session, "recipe.scaling_batch_multiplier")),
            total_time_seconds=derived.total_time_seconds,
            active_time_seconds=derived.active_time_seconds,
        )
    except ServingConversionError as exc:
        raise ApiError(422, exc.code, exc.message, exc.detail) from exc


def _convert_snapshot_mold(
    session: Session, snapshot: RecipeSnapshot, target_mold: MoldSpec
) -> MoldConversion:
    if snapshot.base_mold is None:
        raise ApiError(422, "missing_base_mold", "这份菜谱没有记录基准模具")
    try:
        return convert_mold(
            original_mold=MoldInput(**snapshot.base_mold.model_dump(mode="json")),
            target_mold=MoldInput(**target_mold.model_dump(mode="json")),
            round_deviation_threshold=float(
                config.get(session, "recipe.scaling_round_deviation_threshold")
            ),
            ingredients=[
                MoldIngredientInput(
                    id=item.id,
                    display_name=item.display_name,
                    quantity=item.quantity,
                    unit=item.unit,
                    scaling_mode=_effective_scaling_mode(session, item),
                )
                for item in snapshot.ingredients
            ],
            steps=[
                MoldStepInput(
                    id=step.id,
                    instruction=step.instruction,
                    duration_seconds=step.duration_seconds,
                    temperature_celsius=step.temperature_celsius,
                    heat=step.heat,
                    action=step.action,
                    cookware=step.cookware,
                    doneness=step.doneness,
                )
                for step in snapshot.steps
            ],
        )
    except MoldConversionError as exc:
        raise ApiError(422, exc.code, exc.message, exc.detail) from exc


_ConversionRule = Literal["base", "proportional", "unchanged", "round", "mold_ratio"]


def display_recipe_ingredients(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    mode: Literal["base", "standard", "home"],
    measure_id: uuid.UUID | None = None,
    version_id: uuid.UUID | None = None,
    target_servings: int | None = None,
    target_mold: MoldSpec | None = None,
) -> RecipeIngredientDisplayOut:
    """Return display amounts for an owned immutable recipe version.

    Callers receive the source amount alongside the rendered amount, while
    density and personal-measure ownership stay server-side.
    """
    recipe, version = _owned_version(session, owner, recipe_id, version_id)
    if target_servings is not None and target_mold is not None:
        raise ApiError(422, "invalid_request", "请求参数有误", "份数换算和模具换算不能同时使用")

    snapshot = RecipeSnapshot.model_validate(version.snapshot)
    conversion_by_id: dict[str, tuple[float, str, _ConversionRule]] = {
        item.id: (float(item.quantity), item.unit, "base") for item in snapshot.ingredients
    }
    converted: Iterable[ConvertedIngredient | ConvertedMoldIngredient] = ()
    if target_servings is not None:
        derived = RecipeDerived.model_validate(version.derived)
        converted = _convert_snapshot_servings(
            session, snapshot, derived, target_servings
        ).ingredients
    elif target_mold is not None:
        converted = _convert_snapshot_mold(session, snapshot, target_mold).ingredients
    for item in converted:
        conversion_by_id[item.id] = (
            item.display_quantity,
            item.unit,
            cast(_ConversionRule, item.rule),
        )

    personal_measure: PersonalMeasure | None = None
    if measure_id is not None:
        personal_measure = session.scalar(
            select(PersonalMeasure).where(
                PersonalMeasure.id == measure_id,
                PersonalMeasure.owner_id == owner.id,
            )
        )
        if personal_measure is None:
            raise NotFound()
    if mode == "home" and personal_measure is None:
        raise ApiError(422, "invalid_request", "请求参数有误", "自家量具模式需要 measure_id")

    measure = (
        {
            "name": personal_measure.name,
            "kind": personal_measure.kind,
            "capacity_ml": personal_measure.capacity_ml,
        }
        if personal_measure is not None
        else None
    )
    amounts: list[RecipeDisplayedIngredient] = []
    for item in snapshot.ingredients:
        original_quantity = float(item.quantity)
        original_unit = item.unit
        converted_quantity, converted_unit, conversion_rule = conversion_by_id[item.id]
        base_quantity = item.base_quantity
        base_unit = item.base_unit
        # Versions written before normalization can still be read safely.
        if base_quantity is None or base_unit is None:
            normalized = _display_base_quantity(original_quantity, original_unit)
            if normalized is None:
                base_quantity, base_unit = original_quantity, "count"
            else:
                base_quantity, base_unit = normalized
        if original_unit.strip().casefold() in _COUNT_UNITS:
            # Counted items (eggs, garlic cloves) are cooked by count, so every
            # display mode keeps the rounded count instead of library grams.
            base_quantity, base_unit = converted_quantity, "count"
        elif base_unit == "count":
            base_quantity = converted_quantity
        elif original_quantity != 0:
            base_quantity = float(base_quantity) * converted_quantity / original_quantity
        if base_unit == "count":
            result = {
                "text": f"{quantity_text(float(base_quantity))} {original_unit}",
                "display_quantity": float(base_quantity),
                "display_unit": original_unit,
                "grams": None,
                "rule": "base",
            }
        else:
            density = None
            if item.ingredient_id is not None:
                attributes = _ingredient_data(session, item.ingredient_id)
                if attributes.density is not None:
                    density = attributes.density.value
            result = display_amount(
                base_quantity=float(base_quantity),
                base_unit=base_unit,
                density=density,
                mode=mode,
                measure=measure,
            )
        amounts.append(
            RecipeDisplayedIngredient(
                id=item.id,
                display_name=item.display_name,
                original_quantity=original_quantity,
                original_unit=original_unit,
                converted_quantity=converted_quantity,
                converted_unit=converted_unit,
                conversion_rule=conversion_rule,
                **result,
            )
        )
    return RecipeIngredientDisplayOut(
        display=RecipeIngredientDisplay(
            recipe_id=recipe.id,
            version_id=version.id,
            mode=mode,
            measure_id=measure_id,
            ingredients=amounts,
        )
    )


def _display_base_quantity(quantity: float, unit: str) -> tuple[float, str] | None:
    normalized = unit.strip().casefold()
    if normalized in _MASS_UNITS:
        return quantity * _MASS_UNITS[normalized], "g"
    if normalized in _VOLUME_UNITS:
        return quantity * _VOLUME_UNITS[normalized], "ml"
    if normalized in _VOLUME_SPOONS:
        return quantity * _VOLUME_SPOONS[normalized], "ml"
    return None


def convert_recipe_servings(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    target_servings: int,
    version_id: uuid.UUID | None = None,
) -> RecipeServingConversionOut:
    """Return a deterministic, read-only conversion for an owned recipe version."""
    recipe, version = _owned_version(session, owner, recipe_id, version_id)
    snapshot = RecipeSnapshot.model_validate(version.snapshot)
    derived = RecipeDerived.model_validate(version.derived)
    conversion = _convert_snapshot_servings(session, snapshot, derived, target_servings)
    return RecipeServingConversionOut(
        recipe_id=recipe.id,
        version_id=version.id,
        conversion=ServingConversionSchema.model_validate(conversion.as_dict()),
    )


def convert_recipe_mold(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    target_mold: MoldSpec,
    version_id: uuid.UUID | None = None,
) -> RecipeMoldConversionOut:
    """Return a deterministic, read-only bottom-area conversion for an owned version."""
    recipe, version = _owned_version(session, owner, recipe_id, version_id)
    snapshot = RecipeSnapshot.model_validate(version.snapshot)
    conversion = _convert_snapshot_mold(session, snapshot, target_mold)
    return RecipeMoldConversionOut(
        recipe_id=recipe.id,
        version_id=version.id,
        conversion=MoldConversionSchema.model_validate(conversion.as_dict()),
    )


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
            query.order_by(RecipeVersion.created_at.desc(), RecipeVersion.id.desc()).limit(
                limit + 1
            )
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
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if has_more and rows else None,
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
    image_keys = [
        image.storage_key
        for image in session.scalars(select(RecipeImage).where(RecipeImage.recipe_id == recipe.id))
    ]
    # current_version_id points into the versions table; clear it before deleting snapshots.
    session.execute(update(Recipe).where(Recipe.id == recipe.id).values(current_version_id=None))
    session.execute(delete(RecipeImage).where(RecipeImage.recipe_id == recipe.id))
    session.execute(delete(RecipeVersion).where(RecipeVersion.recipe_id == recipe.id))
    session.delete(recipe)
    session.commit()
    # Remove objects only after the metadata transaction succeeds. A database
    # failure must not leave a committed row pointing at a deleted object.
    for key in image_keys:
        _delete_storage_object(settings, key)


def _delete_storage_object(settings: Settings, key: str) -> None:
    make_recipe_storage(settings).delete(key)


def _sanitize_image(content: bytes, content_type: str) -> tuple[bytes, str, int, int]:
    if len(content) > _MAX_IMAGE_BYTES:
        raise ApiError(422, "image_too_large", "图片太大，请选择 15 MB 以内的图片")
    if content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise ApiError(422, "unsupported_image", "只支持 JPG、PNG 或 WebP 图片")
    try:
        from PIL import Image
    except ImportError as exc:
        raise ApiError(500, "image_processing_unavailable", "图片处理服务暂时不可用") from exc

    try:
        # Treat Pillow's decompression-bomb warning as a hard rejection.  The
        # second open/load is intentional: verify() consumes the decoder.
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            source = Image.open(io.BytesIO(content))
            source_format = source.format
            if source_format not in {"JPEG", "PNG", "WEBP"}:
                raise ApiError(422, "unsupported_image", "只支持 JPG、PNG 或 WebP 图片")
            if source.width * source.height > _MAX_IMAGE_PIXELS:
                raise ApiError(422, "unsafe_image", "图片尺寸过大，无法安全处理")
            source.verify()
            source = Image.open(io.BytesIO(content))
            if source.width * source.height > _MAX_IMAGE_PIXELS:
                raise ApiError(422, "unsafe_image", "图片尺寸过大，无法安全处理")
            source.load()
    except ApiError:
        raise
    except (ImportError, OSError, ValueError, Image.DecompressionBombError) as exc:
        raise ApiError(422, "unsafe_image", "图片无法安全处理，请换一张图片") from exc

    source.thumbnail((2048, 2048))
    width, height = source.size
    # Rebuild the image instead of copying metadata; this removes EXIF GPS,
    # comments, ICC profiles, and any application-specific metadata.
    if source.mode not in {"RGB", "RGBA"}:
        source = source.convert("RGBA" if "transparency" in source.info else "RGB")
    output = io.BytesIO()
    if source.mode == "RGBA":
        source.save(output, format="PNG", optimize=True)
        result_type = "image/png"
    else:
        source.save(output, format="JPEG", quality=85, optimize=True, exif=b"")
        result_type = "image/jpeg"
    return output.getvalue(), result_type, width, height


def _stage_image_record(
    session: Session,
    settings: Settings,
    owner: User,
    normalized: bytes,
    content_type: str,
    width: int,
    height: int,
) -> RecipeImageStaging:
    image_id = uuid.uuid4()
    key = _storage_key(owner.id, image_id, content_type, staged=True)
    storage = make_recipe_storage(settings)
    storage.put(key, normalized, content_type)
    row = RecipeImageStaging(
        id=image_id,
        owner_id=owner.id,
        storage_key=key,
        content_type=content_type,
        byte_size=len(normalized),
        width=width,
        height=height,
    )
    try:
        session.add(row)
        session.flush()
    except Exception:
        make_recipe_storage(settings).delete(key)
        raise
    return row


def stage_image(
    session: Session,
    settings: Settings,
    owner: User,
    content: bytes,
    content_type: str,
) -> RecipeImageStagedOut:
    normalized, actual_type, width, height = _sanitize_image(content, content_type)
    row: RecipeImageStaging | None = None
    try:
        row = _stage_image_record(session, settings, owner, normalized, actual_type, width, height)
        session.commit()
    except Exception:
        session.rollback()
        if row is not None:
            _delete_storage_object(settings, row.storage_key)
        raise
    return _staged_image_out(settings, row)


def save_image(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    content: bytes,
    content_type: str,
    version_id: uuid.UUID | None = None,
) -> RecipeImageOut:
    """Upload a photo as a new immutable recipe version.

    The old version is never mutated.  The temporary object is attached to a
    newly-created version in the same database transaction as the version save.
    """
    recipe = _owned_recipe(session, owner, recipe_id)
    if version_id is not None and version_id != recipe.current_version_id:
        raise ApiError(409, "immutable_version", "旧版本不能追加图片，请基于当前版本保存")
    current = session.get(RecipeVersion, recipe.current_version_id)
    if current is None:
        raise NotFound("菜谱当前版本不存在")
    normalized, actual_type, width, height = _sanitize_image(content, content_type)
    staged: RecipeImageStaging | None = None
    try:
        staged = _stage_image_record(
            session, settings, owner, normalized, actual_type, width, height
        )
        detail = save_version(
            session,
            redis,
            settings,
            owner,
            recipe_id,
            RecipeVersionCreate(
                snapshot=RecipeSnapshot.model_validate(current.snapshot),
                change_note="更新成品图",
                image_ids=[staged.id],
            ),
        )
    except Exception:
        session.rollback()
        if staged is not None:
            attached = session.get(RecipeImage, staged.id)
            if attached is None:
                _delete_storage_object(settings, staged.storage_key)
        raise
    if not detail.version.images:
        raise ApiError(500, "storage_error", "图片关联失败")
    return detail.version.images[-1]


def signed_image_file(
    session: Session,
    settings: Settings,
    recipe_id: uuid.UUID,
    image_id: uuid.UUID,
    expires: int,
    signature: str,
) -> tuple[bytes, str]:
    payload = f"{recipe_id}:{image_id}:{expires}".encode()
    expected = hmac.new(_image_secret(settings).encode(), payload, hashlib.sha256).hexdigest()
    if expires < int(datetime.now(UTC).timestamp()) or not hmac.compare_digest(signature, expected):
        raise NotFound()
    image = session.scalar(
        select(RecipeImage).where(RecipeImage.id == image_id, RecipeImage.recipe_id == recipe_id)
    )
    if image is None:
        raise NotFound()
    return make_recipe_storage(settings).get(image.storage_key), image.content_type


def signed_staged_image_file(
    session: Session,
    settings: Settings,
    image_id: uuid.UUID,
    expires: int,
    signature: str,
) -> tuple[bytes, str]:
    payload = f"staged:{image_id}:{expires}".encode()
    expected = hmac.new(_image_secret(settings).encode(), payload, hashlib.sha256).hexdigest()
    if expires < int(datetime.now(UTC).timestamp()) or not hmac.compare_digest(signature, expected):
        raise NotFound()
    image = session.get(RecipeImageStaging, image_id)
    if image is None:
        raise NotFound()
    return make_recipe_storage(settings).get(image.storage_key), image.content_type
