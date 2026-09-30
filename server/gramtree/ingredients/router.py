"""食材库 HTTP 接口（SPEC-002.1 #19）。"""

from fastapi import APIRouter
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import select

from gramtree.core.errors import ERROR_RESPONSES, ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.deps import SessionDep
from gramtree.ingredients.attributes import IngredientAttributes
from gramtree.ingredients.models import Ingredient, IngredientAlias, IngredientAttribute

router = APIRouter(prefix="/ingredients", tags=["ingredients"])


class IngredientOut(BaseModel):
    id: IdV4
    standard_name: str
    aliases: list[str]
    pinyin: str
    pinyin_initials: str
    category: str
    version: str


class IngredientDetail(IngredientOut):
    """按 ID 读取时的完整数据：身份信息加全部详细属性（#97）。"""

    attributes: IngredientAttributes


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


@router.get("/{ingredient_id}", response_model=IngredientDetail, responses=ERROR_RESPONSES)
def get_ingredient(ingredient_id: IdV4, db: SessionDep) -> IngredientDetail:
    """读取一种食材的完整数据。如果这个 ID 已经合并到另一个,自动返回合并后的食材。

    没经人工校对的属性带 `estimate: true`，计算和显示时按估算处理。
    """
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
    stored = db.scalars(
        select(IngredientAttribute).where(IngredientAttribute.ingredient_id == row.id)
    )
    attributes = IngredientAttributes.from_stored(
        {a.field: (a.value, a.source, a.status) for a in stored}
    )
    return IngredientDetail(
        id=row.id,
        standard_name=row.standard_name,
        aliases=aliases,
        pinyin=row.pinyin,
        pinyin_initials=row.pinyin_initials,
        category=row.category,
        version=row.version,
        attributes=attributes,
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
