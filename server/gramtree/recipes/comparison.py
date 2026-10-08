"""Directional ingredient comparison, distinct from save-time edit operations.

Only ingredient and recipe-level fields are compared here. No full-version
severity or step/AI conclusion is implied by this deliberately scoped contract.
"""

import math
import unicodedata
import uuid
from collections import defaultdict, deque
from decimal import Decimal
from typing import Any, Literal

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.ingredients.matching import normalize
from gramtree.recipes import service
from gramtree.recipes.models import Dish, Recipe, RecipeVersion
from gramtree.recipes.schemas import RecipeIngredient, RecipeSnapshot
from gramtree.recipes.serving_conversion import ServingIngredientInput, convert_servings

Pairing = Literal["stable_id", "identity_group", "group_replacement", "unpaired"]


class ComparisonVersion(BaseModel):
    recipe_id: IdV4
    version_id: IdV4
    version_number: int
    author: str
    dish_name: str
    servings: int


class ComparisonChange(BaseModel):
    kind: Literal["added", "removed", "replacement", "quantity", "unit", "field", "text"]
    field: str
    before: Any = None
    after: Any = None
    relative_change: float | None = None
    unit: str | None = None
    basis: str


class IngredientComparisonRow(BaseModel):
    before: RecipeIngredient | None = None
    after: RecipeIngredient | None = None
    pairing: Literal["stable_id", "identity_group", "group_replacement", "unpaired"]
    changes: list[ComparisonChange] = Field(default_factory=list)


class RecipeIngredientComparison(BaseModel):
    scope: Literal["ingredients"] = "ingredients"
    from_version: ComparisonVersion
    to_version: ComparisonVersion
    normalized_servings: int
    ingredients: list[IngredientComparisonRow]
    snapshot_fields: list[ComparisonChange] = Field(default_factory=list)


def _normalize_servings(snapshot: RecipeSnapshot, target: int) -> list[RecipeIngredient]:
    conversion = convert_servings(
        original_servings=snapshot.servings,
        target_servings=target,
        min_servings=1,
        max_servings=max(target, snapshot.servings),
        steps=[],
        ingredients=[
            ServingIngredientInput(
                id=i.id,
                display_name=i.display_name,
                quantity=i.quantity,
                unit=i.unit,
                scaling_mode=service._snapshot_scaling_mode(i),
            )
            for i in snapshot.ingredients
        ],
    )
    result = []
    for item, converted in zip(snapshot.ingredients, conversion.ingredients, strict=True):
        base = Decimal(str(item.base_quantity or 0))
        mode = service._snapshot_scaling_mode(item)
        if mode == "proportional":
            # Comparison is not display: do not round tiny amounts into zero or
            # let author's choice of g/kg introduce a false formulation change.
            base *= Decimal(target) / Decimal(snapshot.servings)
        elif mode == "round" and item.quantity:
            base *= Decimal(str(converted.display_quantity)) / Decimal(str(item.quantity))
        result.append(item.model_copy(update={"base_quantity": float(base)}))
    return result


def _name(value: str) -> str:
    return "".join(unicodedata.normalize("NFKC", value).casefold().split())


def _identities(session: Session, items: list[RecipeIngredient]) -> list[str]:
    matches = normalize(session, [i.display_name for i in items])
    return [
        str(i.ingredient_id or (m.ingredient.id if m.ingredient else _name(i.display_name)))
        for i, m in zip(items, matches, strict=True)
    ]


def _pair(
    a: list[RecipeIngredient],
    b: list[RecipeIngredient],
    a_ids: list[str],
    b_ids: list[str],
    *,
    stable: bool,
) -> list[tuple[int | None, int | None, Pairing]]:
    # Queues preserve snapshot order for duplicate identity/group keys. Unlike a
    # dict keyed by ingredient identity, this never silently discards an item.
    matched: dict[int, tuple[int, Pairing]] = {}
    used: set[int] = set()

    def pass_keys(a_keys, b_keys, reason: Pairing):
        candidates = defaultdict(deque)
        for index, key in enumerate(b_keys):
            if index not in used:
                candidates[key].append(index)
        for index, key in enumerate(a_keys):
            if index not in matched and candidates[key]:
                target = candidates[key].popleft()
                matched[index] = (target, reason)
                used.add(target)

    if stable:
        pass_keys([i.id for i in a], [i.id for i in b], "stable_id")
    pass_keys(
        [(identity, i.group or "") for identity, i in zip(a_ids, a, strict=True)],
        [(identity, i.group or "") for identity, i in zip(b_ids, b, strict=True)],
        "identity_group",
    )
    a_groups = defaultdict(list)
    b_groups = defaultdict(list)
    for index, item in enumerate(a):
        if index not in matched:
            a_groups[item.group or ""].append(index)
    for index, item in enumerate(b):
        if index not in used:
            b_groups[item.group or ""].append(index)
    for group, remaining in a_groups.items():
        targets = b_groups[group]
        if len(remaining) == len(targets) == 1:
            matched[remaining[0]] = (targets[0], "group_replacement")
            used.add(targets[0])
    pairs: list[tuple[int | None, int | None, Pairing]] = []
    for i in range(len(a)):
        pairs.append((i, *matched[i]) if i in matched else (i, None, "unpaired"))
    for i in range(len(b)):
        if i not in used:
            pairs.append((None, i, "unpaired"))
    return pairs


def _grams_factor(session: Session, item: RecipeIngredient) -> float | None:
    if item.base_unit == "g":
        return 1.0
    if item.ingredient_id is None:
        return None
    attrs = service._ingredient_attributes(session, item.ingredient_id)
    if item.base_unit == "ml":
        return attrs.density.value if attrs.density else None
    if attrs.count_units:
        return next((u.grams for u in attrs.count_units.value if u.unit == item.unit), None)
    return None


def _quantity_changes(
    session: Session, before: RecipeIngredient, after: RecipeIngredient, *, replacement: bool
) -> list[ComparisonChange]:
    a, b = float(before.base_quantity or 0), float(after.base_quantity or 0)
    same_unit = before.base_unit == after.base_unit and (
        before.base_unit != "count" or before.unit == after.unit
    )
    basis = "按保存的基础量及份数缩放规则比较"
    if not same_unit:
        fa, fb = _grams_factor(session, before), _grams_factor(session, after)
        if fa is None or fb is None or not (math.isfinite(fa) and math.isfinite(fb)):
            return [
                ComparisonChange(
                    kind="unit",
                    field="base_unit",
                    before=before.base_unit if before.base_unit != "count" else before.unit,
                    after=after.base_unit if after.base_unit != "count" else after.unit,
                    basis="单位不同：缺少可靠密度或对应计数单位的单个重量，不能计算百分比",
                )
            ]
        b = b * fb / fa
        if not math.isfinite(b):
            return [
                ComparisonChange(
                    kind="unit",
                    field="base_unit",
                    before=before.base_unit,
                    after=after.base_unit,
                    basis="单位不同：转换结果超出可靠计算范围，不能计算百分比",
                )
            ]
        basis = "按食材库密度或对应计数单位的单个重量换算后比较（转换数据为食材估算）"
    if math.isclose(a, b, rel_tol=1e-10, abs_tol=0):
        return []
    relative = (b - a) / a if a and not replacement else None
    return [
        ComparisonChange(
            kind="quantity",
            field="base_quantity",
            before=a,
            after=b,
            unit=before.base_unit,
            relative_change=relative if relative is not None and math.isfinite(relative) else None,
            basis=basis if a else f"{basis}；原用量为零，不计算相对百分比",
        )
    ]


def _field_changes(
    before: BaseModel, after: BaseModel, *, exclude: set[str]
) -> list[ComparisonChange]:
    a, b = before.model_dump(mode="json"), after.model_dump(mode="json")
    # New snapshot/ingredient execution fields are consumed by the same engine;
    # only explicitly non-execution/provenance fields are excluded.
    return [
        ComparisonChange(
            kind="text"
            if field in {"display_name", "description", "design_rationale"}
            else "field",
            field=field,
            before=a.get(field),
            after=b.get(field),
            basis="只改文字，不计为配方改动"
            if field in {"display_name", "description", "design_rationale"}
            else "执行字段改变",
        )
        for field in sorted(a.keys() | b.keys())
        if field not in exclude and a.get(field) != b.get(field)
    ]


def compare_ingredients(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    from_version_id: uuid.UUID,
    to_version_id: uuid.UUID,
) -> RecipeIngredientComparison:
    anchor = service._owned_recipe(session, owner, recipe_id)

    def visible(version_id: uuid.UUID) -> tuple[Recipe, RecipeVersion]:
        row = session.execute(
            select(Recipe, RecipeVersion)
            .join(RecipeVersion, RecipeVersion.recipe_id == Recipe.id)
            .where(RecipeVersion.id == version_id, Recipe.owner_id == owner.id)
        ).one_or_none()
        if row is None:
            raise NotFound()
        recipe, version = row
        if recipe.dish_id != anchor.dish_id:
            raise ApiError(422, "different_dishes", "只能比较同一道菜的版本")
        return recipe, version

    a_recipe, a_version = visible(from_version_id)
    b_recipe, b_version = visible(to_version_id)
    a = RecipeSnapshot.model_validate(a_version.snapshot)
    b = RecipeSnapshot.model_validate(b_version.snapshot)
    normalized = _normalize_servings(b, a.servings)
    identities = _identities(session, [*a.ingredients, *normalized])
    a_ids, b_ids = identities[: len(a.ingredients)], identities[len(a.ingredients) :]
    stable = (a_recipe.root_recipe_id or a_recipe.id) == (b_recipe.root_recipe_id or b_recipe.id)
    pairs = _pair(a.ingredients, normalized, a_ids, b_ids, stable=stable)
    rows = []
    for ai, bi, reason in pairs:
        before = a.ingredients[ai] if ai is not None else None
        after = normalized[bi] if bi is not None else None
        changes = []
        if before is None or after is None:
            changes.append(
                ComparisonChange(
                    kind="added" if before is None else "removed",
                    field="ingredient",
                    before=before.model_dump(mode="json") if before else None,
                    after=after.model_dump(mode="json") if after else None,
                    basis="未能可靠配对的食材分别列为新增或删除",
                )
            )
        else:
            assert ai is not None and bi is not None
            replacement = a_ids[ai] != b_ids[bi] and not (
                reason == "stable_id"
                and before.ingredient_id is None
                and after.ingredient_id is None
            )
            if replacement:
                changes.append(
                    ComparisonChange(
                        kind="replacement",
                        field="ingredient_id",
                        before=before.display_name,
                        after=after.display_name,
                        basis="稳定食材 ID 的身份改变或同组唯一一删一加",
                    )
                )
            changes.extend(_quantity_changes(session, before, after, replacement=replacement))
            changes.extend(
                _field_changes(
                    before,
                    after,
                    exclude={
                        "id",
                        "ingredient_id",
                        "quantity",
                        "unit",
                        "base_quantity",
                        "base_unit",
                        "quantity_source",
                        "preparation_source",
                        "measure_input_token",
                        "flavor_source",
                        "functional_source",
                    },
                )
            )
        rows.append(
            IngredientComparisonRow(before=before, after=after, pairing=reason, changes=changes)
        )

    def metadata(
        recipe: Recipe, version: RecipeVersion, snapshot: RecipeSnapshot
    ) -> ComparisonVersion:
        dish = session.get(Dish, recipe.dish_id)
        if dish is None:
            raise NotFound()
        return ComparisonVersion(
            recipe_id=recipe.id,
            version_id=version.id,
            version_number=version.version_number,
            author=owner.nickname,
            dish_name=dish.name,
            servings=snapshot.servings,
        )

    return RecipeIngredientComparison(
        from_version=metadata(a_recipe, a_version, a),
        to_version=metadata(b_recipe, b_version, b),
        normalized_servings=a.servings,
        ingredients=rows,
        snapshot_fields=_field_changes(
            a,
            b,
            exclude={
                "ingredients",
                "steps",
                "servings",
                "format_version",
                "text_source",
                "servings_source",
            },
        ),
    )
