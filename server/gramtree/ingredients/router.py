"""食材库 HTTP 接口（SPEC-002.1 #19, #97）。"""

from fastapi import APIRouter
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import select

from gramtree.core.errors import ERROR_RESPONSES, ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.deps import SessionDep
from gramtree.ingredients.models import (
    Ingredient,
    IngredientAlias,
    IngredientAllergen,
    IngredientAttribute,
    IngredientCountingUnit,
    IngredientFlavorProfile,
    IngredientNutrition,
    IngredientPurchaseUnit,
    IngredientStorage,
)

router = APIRouter(prefix="/ingredients", tags=["ingredients"])


class FlavorProfileOut(BaseModel):
    """单个味型的输出：强度和校对状态（未校对的标记为"估算"）。"""

    strength: int
    verified: bool


class AttributeOut(BaseModel):
    """单值属性的输出：值和校对状态。"""

    value: bool | str | float
    verified: bool


class CountingUnitOut(BaseModel):
    """计数单位的输出。"""

    unit: str
    count: int
    verified: bool


class AllergenOut(BaseModel):
    """过敏原的输出。"""

    allergen_class: str
    verified: bool


class NutritionOut(BaseModel):
    """营养成分的输出。"""

    value: float
    verified: bool


class PurchaseUnitOut(BaseModel):
    """购买单位的输出。"""

    unit: str
    approx_weight_g: float
    verified: bool


class StorageOut(BaseModel):
    """存储方式的输出。"""

    method: str
    days: int
    verified: bool


class IngredientOut(BaseModel):
    id: IdV4
    standard_name: str
    aliases: list[str]
    pinyin: str
    pinyin_initials: str
    category: str
    version: str
    flavor_profiles: dict[str, FlavorProfileOut] | None = None
    is_functional: AttributeOut | None = None
    default_scaling: AttributeOut | None = None
    density_g_ml: AttributeOut | None = None
    individual_weight_g: AttributeOut | None = None
    supermarket_zone: AttributeOut | None = None
    is_staple_condiment: AttributeOut | None = None
    counting_units: list[CountingUnitOut] | None = None
    allergens: list[AllergenOut] | None = None
    nutrition_per_100g: dict[str, NutritionOut] | None = None
    purchase_units: list[PurchaseUnitOut] | None = None
    storage: list[StorageOut] | None = None


class SearchQuery(BaseModel):
    query: str = Field(..., min_length=1, max_length=100)

    @field_validator("query")
    @classmethod
    def validate_query(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("查询不能为空")
        return v


class SearchResult(BaseModel):
    items: list[IngredientOut]


@router.get("/{ingredient_id}", response_model=IngredientOut, responses=ERROR_RESPONSES)
def get_ingredient(ingredient_id: IdV4, db: SessionDep) -> IngredientOut:
    """读取一种食材的信息。如果这个 ID 已经合并到另一个,自动返回合并后的食材。"""
    current = ingredient_id
    for _ in range(10):  # 防止数据错误导致的死循环
        row = db.get(Ingredient, current)
        if row is None:
            raise NotFound()
        if row.merged_into is None:
            break
        current = row.merged_into
    else:
        raise NotFound(f"合并链太长或有循环：{ingredient_id}")

    aliases = list(
        db.scalars(select(IngredientAlias.alias).where(IngredientAlias.ingredient_id == row.id))
    )

    # 读取味型数据（票 #97）
    flavor_profiles = None
    flavor_rows = list(
        db.scalars(select(IngredientFlavorProfile).where(IngredientFlavorProfile.ingredient_id == row.id))
    )
    if flavor_rows:
        flavor_profiles = {
            fp.flavor_type: FlavorProfileOut(strength=fp.strength, verified=fp.verified)
            for fp in flavor_rows
        }

    # 读取单值属性
    attr_rows = list(
        db.scalars(select(IngredientAttribute).where(IngredientAttribute.ingredient_id == row.id))
    )
    attrs = {ar.attr_key: AttributeOut(value=ar.value["value"], verified=ar.value["verified"]) for ar in attr_rows}

    # 读取计数单位
    counting_units = None
    cu_rows = list(
        db.scalars(select(IngredientCountingUnit).where(IngredientCountingUnit.ingredient_id == row.id))
    )
    if cu_rows:
        counting_units = [
            CountingUnitOut(unit=cu.unit, count=cu.count, verified=cu.verified) for cu in cu_rows
        ]

    # 读取过敏原
    allergens = None
    allergen_rows = list(
        db.scalars(select(IngredientAllergen).where(IngredientAllergen.ingredient_id == row.id))
    )
    if allergen_rows:
        allergens = [
            AllergenOut(allergen_class=a.allergen_class, verified=a.verified) for a in allergen_rows
        ]

    # 读取营养成分
    nutrition_per_100g = None
    nutrition_rows = list(
        db.scalars(select(IngredientNutrition).where(IngredientNutrition.ingredient_id == row.id))
    )
    if nutrition_rows:
        nutrition_per_100g = {
            n.nutrient_key: NutritionOut(value=float(n.value), verified=n.verified) for n in nutrition_rows
        }

    # 读取购买单位
    purchase_units = None
    pu_rows = list(
        db.scalars(select(IngredientPurchaseUnit).where(IngredientPurchaseUnit.ingredient_id == row.id))
    )
    if pu_rows:
        purchase_units = [
            PurchaseUnitOut(unit=pu.unit, approx_weight_g=float(pu.approx_weight_g), verified=pu.verified)
            for pu in pu_rows
        ]

    # 读取存储方式
    storage = None
    storage_rows = list(
        db.scalars(select(IngredientStorage).where(IngredientStorage.ingredient_id == row.id))
    )
    if storage_rows:
        storage = [StorageOut(method=s.method, days=s.days, verified=s.verified) for s in storage_rows]

    return IngredientOut(
        id=row.id,
        standard_name=row.standard_name,
        aliases=aliases,
        pinyin=row.pinyin,
        pinyin_initials=row.pinyin_initials,
        category=row.category,
        version=row.version,
        flavor_profiles=flavor_profiles,
        is_functional=attrs.get("is_functional"),
        default_scaling=attrs.get("default_scaling"),
        density_g_ml=attrs.get("density_g_ml"),
        individual_weight_g=attrs.get("individual_weight_g"),
        supermarket_zone=attrs.get("supermarket_zone"),
        is_staple_condiment=attrs.get("is_staple_condiment"),
        counting_units=counting_units,
        allergens=allergens,
        nutrition_per_100g=nutrition_per_100g,
        purchase_units=purchase_units,
        storage=storage,
    )


@router.post("/search", response_model=SearchResult, responses=ERROR_RESPONSES)
def search_ingredients(query: SearchQuery, db: SessionDep) -> SearchResult:
    """搜索食材。支持标准名、别名、拼音首字母、完整拼音前缀匹配。最多返回 20 个结果。"""
    q = query.query.strip()

    if not q:
        raise ApiError(400, "invalid_request", "查询不能为空")

    # 查找未合并的食材
    base_query = select(Ingredient).where(Ingredient.merged_into.is_(None))

    # 匹配策略按优先级排序
    results: list[tuple[int, Ingredient]] = []  # (priority, ingredient)

    # 1. 标准名称前缀匹配 (优先级 1)
    stmt = base_query.where(Ingredient.standard_name.startswith(q))
    for ing in db.scalars(stmt).all():
        results.append((1, ing))

    # 2. 别名前缀匹配 (优先级 2)
    alias_stmt = (
        select(Ingredient)
        .join(IngredientAlias, IngredientAlias.ingredient_id == Ingredient.id)
        .where(Ingredient.merged_into.is_(None))
        .where(IngredientAlias.alias.startswith(q))
    )
    for ing in db.scalars(alias_stmt).all():
        # 避免重复（可能已经通过标准名匹配了）
        if not any(ing.id == r[1].id for r in results):
            results.append((2, ing))

    # 3. 拼音首字母匹配 (优先级 3)
    pinyin_initial_stmt = base_query.where(Ingredient.pinyin_initials.startswith(q.lower()))
    for ing in db.scalars(pinyin_initial_stmt).all():
        if not any(ing.id == r[1].id for r in results):
            results.append((3, ing))

    # 4. 完整拼音前缀匹配 (优先级 4)
    pinyin_stmt = base_query.where(Ingredient.pinyin.startswith(q.lower()))
    for ing in db.scalars(pinyin_stmt).all():
        if not any(ing.id == r[1].id for r in results):
            results.append((4, ing))

    # 按优先级排序并限制为 20 个
    results.sort(key=lambda x: (x[0], x[1].standard_name))
    top_results = results[:20]

    # 为每个食材获取别名
    items = []
    for _, ing in top_results:
        aliases = list(
            db.scalars(select(IngredientAlias.alias).where(IngredientAlias.ingredient_id == ing.id))
        )
        items.append(
            IngredientOut(
                id=ing.id,
                standard_name=ing.standard_name,
                aliases=aliases,
                pinyin=ing.pinyin,
                pinyin_initials=ing.pinyin_initials,
                category=ing.category,
                version=ing.version,
            )
        )

    return SearchResult(items=items)
