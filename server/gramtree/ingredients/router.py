"""食材库 HTTP 接口（SPEC-002.1 #19）。"""

from datetime import UTC, datetime

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.errors import ERROR_RESPONSES, ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.deps import SessionDep
from gramtree.ingredients import matching
from gramtree.ingredients.attributes import IngredientAttributes
from gramtree.ingredients.models import (
    Ingredient,
    IngredientAlias,
    IngredientAttribute,
    UnrecordedIngredient,
)

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


def _to_out(db: Session, row: Ingredient) -> IngredientOut:
    aliases = list(
        db.scalars(select(IngredientAlias.alias).where(IngredientAlias.ingredient_id == row.id))
    )
    return IngredientOut(
        id=row.id,
        standard_name=row.standard_name,
        aliases=aliases,
        pinyin=row.pinyin,
        pinyin_initials=row.pinyin_initials,
        category=row.category,
        version=row.version,
    )


def _to_detail(db: Session, row: Ingredient) -> IngredientDetail:
    stored = db.scalars(
        select(IngredientAttribute).where(IngredientAttribute.ingredient_id == row.id)
    )
    attributes = IngredientAttributes.from_stored(
        {a.field: (a.value, a.source, a.status) for a in stored}
    )
    aliases = list(
        db.scalars(select(IngredientAlias.alias).where(IngredientAlias.ingredient_id == row.id))
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


class UnrecordedIngredientItem(BaseModel):
    """未收录食材统计项 (#102)"""

    name: str
    occurrence_count: int
    first_seen_at: datetime
    last_seen_at: datetime


@router.get("/unrecorded", response_model=list[UnrecordedIngredientItem], responses=ERROR_RESPONSES)
def list_unrecorded_ingredients(
    db: SessionDep,
    limit: int = Query(50, ge=1, le=500, description="最多返回多少条记录"),
) -> list[UnrecordedIngredientItem]:
    """查询未收录食材列表，按出现次数降序排列 (#102)。"""
    stmt = (
        select(UnrecordedIngredient)
        .order_by(UnrecordedIngredient.occurrence_count.desc())
        .limit(limit)
    )
    records = db.scalars(stmt).all()
    return [
        UnrecordedIngredientItem(
            name=r.name,
            occurrence_count=r.occurrence_count,
            first_seen_at=r.first_seen_at,
            last_seen_at=r.last_seen_at,
        )
        for r in records
    ]


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

    return _to_detail(db, row)


@router.post("/search", response_model=SearchResult, responses=ERROR_RESPONSES)
def search_ingredients(query: SearchQuery, db: SessionDep) -> SearchResult:
    """搜索食材。支持标准名、别名、拼音首字母、完整拼音前缀匹配。最多返回 20 个结果。"""
    q = query.query.strip()

    if not q:
        raise ApiError(400, "invalid_request", "查询不能为空")

    return SearchResult(items=[_to_out(db, ing) for ing in matching.search(db, q, limit=20)])


# 一次归一的名称数量上限，超过按 ADR 0002 返回 422 invalid_request
NORMALIZE_MAX_ITEMS = 100


class NormalizeItem(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="菜谱里写的食材名称")
    context: str | None = Field(
        None,
        max_length=200,
        description="上下文，如所在菜名。规则匹配不使用，留给 SPEC-003.1 的 AI 判断",
    )

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("名称不能为空")
        return v


class NormalizeRequest(BaseModel):
    items: list[NormalizeItem] = Field(..., min_length=1, max_length=NORMALIZE_MAX_ITEMS)


class NormalizeCandidate(BaseModel):
    ingredient_id: IdV4
    standard_name: str


class NormalizeResultItem(BaseModel):
    name: str = Field(description="原样返回输入的名称")
    confidence: matching.Confidence = Field(
        description=(
            "exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；"
            "fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；"
            "unrecorded 未收录"
        )
    )
    ingredient_id: IdV4 | None = Field(description="合并后的标准 ID；歧义和未收录时为空")
    standard_name: str | None
    candidates: list[NormalizeCandidate] = Field(description="只有 ambiguous 时非空")


class NormalizeResponse(BaseModel):
    results: list[NormalizeResultItem]


@router.post("/normalize", response_model=NormalizeResponse, responses=ERROR_RESPONSES)
def normalize_ingredients(body: NormalizeRequest, db: SessionDep) -> NormalizeResponse:
    """把一批食材名称归一到标准 ID（只用规则匹配），结果按输入顺序返回。"""
    names = [item.name for item in body.items]
    results = []
    now = datetime.now(UTC)

    for name, n in zip(names, matching.normalize(db, names), strict=True):
        # 当返回 unrecorded 时，记录到未收录统计表 (#102)
        if n.confidence == "unrecorded":
            stmt = select(UnrecordedIngredient).where(UnrecordedIngredient.name == name)
            existing = db.scalars(stmt).first()
            if existing:
                existing.occurrence_count += 1
                existing.last_seen_at = now
            else:
                new_record = UnrecordedIngredient(
                    name=name,
                    occurrence_count=1,
                    first_seen_at=now,
                    last_seen_at=now,
                )
                db.add(new_record)
            db.commit()

        results.append(
            NormalizeResultItem(
                name=name,
                confidence=n.confidence,
                ingredient_id=n.ingredient.id if n.ingredient else None,
                standard_name=n.ingredient.standard_name if n.ingredient else None,
                candidates=[
                    NormalizeCandidate(ingredient_id=c.id, standard_name=c.standard_name)
                    for c in n.candidates
                ],
            )
        )
    return NormalizeResponse(results=results)
