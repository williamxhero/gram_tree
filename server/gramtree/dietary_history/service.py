"""Owner dietary statistics computed from authoritative cooking records."""

from collections import Counter
from datetime import UTC, date, datetime, time, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.dietary_history.models import DietaryRange
from gramtree.dietary_history.schemas import (
    DietaryDishCount,
    DietaryDistributionItem,
    DietaryPeriod,
    DietaryStatisticsOut,
    DietaryUnclassifiedDish,
)
from gramtree.ingredients.models import Ingredient
from gramtree.recipes.models import Dish, DishAlias, Recipe, RecipeVersion
from gramtree.records.models import CookingRecord


def period_bounds(period: DietaryPeriod, anchor: date, timezone: str) -> DietaryRange:
    zone = ZoneInfo(timezone)
    if period == "week":
        start = anchor - timedelta(days=anchor.weekday())
        end = start + timedelta(days=7)
    elif period == "month":
        start = anchor.replace(day=1)
        end = (start.replace(day=28) + timedelta(days=4)).replace(day=1)
    else:
        start = anchor.replace(month=1, day=1)
        end = date(start.year + 1, 1, 1)
    start_at = datetime.combine(start, time.min, tzinfo=zone).astimezone(UTC)
    end_at = datetime.combine(end, time.min, tzinfo=zone).astimezone(UTC)
    return DietaryRange(timezone, start, end, start_at, end_at)


def _snapshot_for(row: CookingRecord, versions: dict[Any, RecipeVersion]) -> dict[str, Any] | None:
    if row.recipe_version_id is not None and row.recipe_version_id in versions:
        snapshot = versions[row.recipe_version_id].snapshot
        return snapshot if isinstance(snapshot, dict) else None
    return row.snapshot if isinstance(row.snapshot, dict) else None


def _dish_for(
    row: CookingRecord,
    versions: dict[Any, RecipeVersion],
    recipes: dict[Any, Recipe],
    dishes: dict[Any, Dish],
    names: dict[str, Dish],
) -> tuple[Any, str] | None:
    recipe_id = row.recipe_id
    if recipe_id is None and row.recipe_version_id is not None:
        version = versions.get(row.recipe_version_id)
        recipe_id = version.recipe_id if version is not None else None
    if recipe_id is not None and recipe_id in recipes:
        dish = dishes.get(recipes[recipe_id].dish_id)
        if dish is not None:
            return dish.id, dish.name
    # Versionless manual records can only use an exact canonical or alias resolver.
    name = (row.dish_name or "").strip()
    dish = names.get(name)
    return (dish.id, dish.name) if dish is not None else None


def statistics(
    session: Session,
    owner: User,
    period: DietaryPeriod,
    anchor: date,
    *,
    generated_at: datetime | None = None,
) -> DietaryStatisticsOut:
    bounds = period_bounds(period, anchor, owner.timezone)
    rows = list(
        session.scalars(
            select(CookingRecord).where(
                CookingRecord.owner_id == owner.id,
                CookingRecord.counts_as_cooked.is_(True),
                CookingRecord.occurred_at >= bounds.start_at,
                CookingRecord.occurred_at < bounds.end_at,
            )
        )
    )
    version_ids = {r.recipe_version_id for r in rows if r.recipe_version_id is not None}
    versions = (
        {
            row.id: row
            for row in session.scalars(
                select(RecipeVersion).where(RecipeVersion.id.in_(version_ids))
            )
        }
        if version_ids
        else {}
    )
    recipe_ids = {v.recipe_id for v in versions.values()}
    recipes = (
        {row.id: row for row in session.scalars(select(Recipe).where(Recipe.id.in_(recipe_ids)))}
        if recipe_ids
        else {}
    )
    dish_ids = {r.dish_id for r in recipes.values()}
    dishes = (
        {row.id: row for row in session.scalars(select(Dish).where(Dish.id.in_(dish_ids)))}
        if dish_ids
        else {}
    )
    aliases = list(session.scalars(select(DishAlias)))
    names = {d.name: d for d in session.scalars(select(Dish))}
    for alias in aliases:
        dish = dishes.get(alias.dish_id)
        if dish is not None:
            names[alias.alias] = dish

    category_by_id: dict[Any, str] = {}
    for ingredient in session.scalars(select(Ingredient)):
        category_by_id[ingredient.id] = ingredient.category
        category_by_id[str(ingredient.id)] = ingredient.category
    ingredient_counts: Counter[str] = Counter()
    cuisine_counts: Counter[str] = Counter()
    dish_counts: Counter[Any] = Counter()
    dish_names: dict[Any, str] = {}
    first_seen: dict[Any, datetime] = {}
    unresolved: list[DietaryUnclassifiedDish] = []
    for row in rows:
        snapshot = _snapshot_for(row, versions)
        if snapshot is not None:
            cuisine = snapshot.get("cuisine")
            cuisine_counts[
                str(cuisine) if isinstance(cuisine, str) and cuisine else "unclassified"
            ] += 1
            categories: set[str] = set()
            for item in snapshot.get("ingredients", []):
                if not isinstance(item, dict) or item.get("group") != "主料":
                    continue
                ingredient_id = item.get("ingredient_id")
                category = category_by_id.get(ingredient_id)
                if category:
                    categories.add(category)
            for category in categories:
                ingredient_counts[category] += 1
        else:
            cuisine_counts["unclassified"] += 1
        identity = _dish_for(row, versions, recipes, dishes, names)
        if identity is None:
            unresolved.append(
                DietaryUnclassifiedDish(
                    record_id=row.id, name=row.dish_name, occurred_at=row.occurred_at
                )
            )
            continue
        dish_id, name = identity
        dish_counts[dish_id] += 1
        dish_names[dish_id] = name
        first_seen[dish_id] = min(first_seen.get(dish_id, row.occurred_at), row.occurred_at)

    historical_first = _historical_first_seen(session, owner.id, set(dish_counts), names)
    frequent = _dish_items(dish_counts, dish_names, first_seen)
    new = _dish_items(
        {
            dish_id: count
            for dish_id, count in dish_counts.items()
            if historical_first.get(dish_id) == first_seen[dish_id]
        },
        dish_names,
        first_seen,
    )
    now = generated_at or datetime.now(UTC)
    return DietaryStatisticsOut(
        period=period,
        timezone=owner.timezone,
        local_start=bounds.local_start,
        local_end=bounds.local_end,
        start_at=bounds.start_at,
        end_at=bounds.end_at,
        generated_at=now,
        cooking_count=len(rows),
        ingredient_record_count=sum(
            1 for row in rows if _has_main_ingredient(_snapshot_for(row, versions), category_by_id)
        ),
        ingredient_distribution=_distribution(ingredient_counts),
        cuisine_distribution=_distribution(cuisine_counts),
        frequent_dishes=frequent[:5],
        new_dishes=new,
        unclassified_dish_count=len(unresolved),
        unclassified_dishes=unresolved[:50],
    )


def _has_main_ingredient(snapshot: dict[str, Any] | None, categories: dict[Any, str]) -> bool:
    return bool(
        snapshot
        and any(
            isinstance(item, dict)
            and item.get("group") == "主料"
            and categories.get(item.get("ingredient_id"))
            for item in snapshot.get("ingredients", [])
        )
    )


def _historical_first_seen(
    session: Session, owner_id: Any, dish_ids: set[Any], names: dict[str, Dish]
) -> dict[Any, datetime]:
    if not dish_ids:
        return {}
    rows = session.scalars(
        select(CookingRecord).where(
            CookingRecord.owner_id == owner_id, CookingRecord.counts_as_cooked.is_(True)
        )
    )
    result: dict[Any, datetime] = {}
    recipe_rows = session.execute(
        select(CookingRecord, Recipe)
        .join(RecipeVersion, CookingRecord.recipe_version_id == RecipeVersion.id)
        .join(Recipe, RecipeVersion.recipe_id == Recipe.id)
        .where(CookingRecord.owner_id == owner_id, CookingRecord.counts_as_cooked.is_(True))
    )
    for record, recipe in recipe_rows:
        if recipe.dish_id in dish_ids:
            result[recipe.dish_id] = min(
                result.get(recipe.dish_id, record.occurred_at), record.occurred_at
            )
    for record in rows:
        dish = names.get((record.dish_name or "").strip())
        if dish is not None and dish.id in dish_ids:
            result[dish.id] = min(result.get(dish.id, record.occurred_at), record.occurred_at)
    return result


def _distribution(values: Counter[str]) -> list[DietaryDistributionItem]:
    return [
        DietaryDistributionItem(key=key, count=count)
        for key, count in sorted(values.items(), key=lambda p: (-p[1], p[0]))
    ]


def _dish_items(
    counts: dict[Any, int], names: dict[Any, str], first: dict[Any, datetime]
) -> list[DietaryDishCount]:
    return [
        DietaryDishCount(
            dish_id=dish_id, name=names[dish_id], count=count, first_cooked_at=first[dish_id]
        )
        for dish_id, count in sorted(counts.items(), key=lambda p: (-p[1], names[p[0]]))
    ]
