"""食材库 HTTP 接口（SPEC-002.1 #19）。

路由注册顺序有讲究：字面路径（`/unrecorded`、`/changes`、`/batch`、`/search`、`/normalize`）
必须全部排在通配的 `GET /{ingredient_id}` 前面，否则 Starlette 会把字面段当成 UUID 解析回 422。
下面的顺序就是这个顺序，加新接口时插在 `get_ingredient` 之前。
"""

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field, TypeAdapter, ValidationError, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.errors import ERROR_RESPONSES, ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.deps import SessionDep
from gramtree.ingredients import matching, versioning
from gramtree.ingredients.attributes import IngredientAttributes
from gramtree.ingredients.models import (
    Ingredient,
    IngredientAlias,
    IngredientAttribute,
    IngredientVersion,
    UnrecordedIngredient,
)

router = APIRouter(prefix="/ingredients", tags=["ingredients"])

# 一次批量读取的 ID 数量上限，超过按 ADR 0002 返回 422 invalid_request
BATCH_MAX_IDS = 100


class IngredientOut(BaseModel):
    id: IdV4
    standard_name: str
    aliases: list[str]
    pinyin: str
    pinyin_initials: str
    category: str
    version: str


class IngredientDetail(IngredientOut):
    """按 ID 读取时的完整数据：身份信息加全部详细属性（#97），每个属性带估算标记。"""

    attributes: IngredientAttributes
    # 只有批量读取报了一个已合并的旧 ID 时才非空（#101），标明这条是从哪个旧 ID 转过来的
    requested_id: IdV4 | None = Field(
        None,
        description="请求里写的 ID；和 id 不同时说明这个 ID 已经合并，只批量读取会带上",
    )


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


def _to_detail(
    db: Session, row: Ingredient, requested_id: uuid.UUID | None = None
) -> IngredientDetail:
    stored = db.scalars(
        select(IngredientAttribute).where(IngredientAttribute.ingredient_id == row.id)
    )
    attributes = IngredientAttributes.from_stored(
        {a.field: (a.value, a.source, a.status) for a in stored}
    )
    aliases = list(
        db.scalars(select(IngredientAlias.alias).where(IngredientAlias.ingredient_id == row.id))
    )
    # 请求的旧 ID 和实际返回的 ID 不同时才写 requested_id（只有批量读取会传）
    merged_from = requested_id if requested_id is not None and requested_id != row.id else None
    return IngredientDetail(
        id=row.id,
        standard_name=row.standard_name,
        aliases=aliases,
        pinyin=row.pinyin,
        pinyin_initials=row.pinyin_initials,
        category=row.category,
        version=row.version,
        attributes=attributes,
        requested_id=merged_from,
    )


class MergeRelation(BaseModel):
    """一次合并：旧 ID 指向新 ID（#101）。"""

    from_id: IdV4 = Field(description="被合并掉的旧标准 ID")
    to_id: IdV4 = Field(description="合并后的标准 ID")


class ReleaseNote(BaseModel):
    """一次发布的版本号和变更说明（#101）。"""

    version: str
    changelog: str


class ChangesResponse(BaseModel):
    """某个版本之后的食材变化（#101），App 用它增量更新本机缓存。"""

    current_version: str = Field(
        description="服务端当前的食材库版本，App 存下来当下次请求的 since_version"
    )
    added: list[IngredientDetail] = Field(description="这个区间里新增的食材，含全部详细属性")
    modified: list[IngredientDetail] = Field(description="这个区间里改动过的食材，含全部详细属性")
    merged: list[MergeRelation] = Field(description="这个区间里生效的合并关系，旧 ID → 新 ID")
    releases: list[ReleaseNote] = Field(
        description="这个区间内每次发布的版本号和变更说明，按版本从早到晚"
    )


def _resolve(db: Session, ingredient_id: uuid.UUID) -> Ingredient | None:
    """跟随合并链找到当前有效的食材；不存在或链太长（有环）时返回 None。"""
    current = ingredient_id
    for _ in range(10):  # 防止数据错误导致的死循环
        row = db.get(Ingredient, current)
        if row is None:
            return None
        if row.merged_into is None:
            return row
        current = row.merged_into
    return None


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


@router.get("/changes", response_model=ChangesResponse, responses=ERROR_RESPONSES)
def get_ingredient_changes(
    db: SessionDep,
    since_version: str | None = Query(
        None,
        description="App 手上食材库的版本号；不给表示首次下载，返回整份食材库",
    ),
) -> ChangesResponse:
    """返回指定版本之后的全部变化：新增、修改的食材完整数据，合并关系，以及每次发布的说明。

    版本号是 `主.次.修`，按数字比大小，不看导入时间。不给 `since_version` 时返回整份食材库
    （App 首次下载用，全部算“新增”）；给最新版本时返回空变化；给不存在的版本返回 404。
    """
    releases = list(db.scalars(select(IngredientVersion)))
    versions = [r.version for r in releases]
    current = versioning.latest_version(versions)
    if current is None:
        raise NotFound("食材库还没有导入过任何版本")

    if since_version is None:
        since_key = None
    else:
        try:
            since_key = versioning.parse_version(since_version)
        except ValueError as exc:
            raise ApiError(
                422,
                "invalid_request",
                "请求参数有误",
                f"since_version 应当是 主.次.修 形式的版本号：{since_version}",
            ) from exc
        if since_version not in versions:
            raise NotFound(f"没有这个食材库版本：{since_version}")

    # 区间内的版本按数字大小筛，字符串比会把 2.10.0 排到 2.9.0 前面
    in_range = {v for v in versions if since_key is None or versioning.parse_version(v) > since_key}
    release_notes = sorted(
        (
            ReleaseNote(version=r.version, changelog=r.changelog)
            for r in releases
            if r.version in in_range
        ),
        key=lambda r: versioning.parse_version(r.version),
    )

    rows = list(
        db.scalars(
            select(Ingredient)
            .where(Ingredient.version.in_(in_range))
            .order_by(Ingredient.standard_name)
        )
    )

    added: list[IngredientDetail] = []
    modified: list[IngredientDetail] = []
    merged: list[MergeRelation] = []
    for row in rows:
        if row.merged_into is not None:
            # 已合并的食材只报合并关系：它的数据不再有价值，App 按这个关系改写本机缓存的旧 ID
            merged.append(MergeRelation(from_id=row.id, to_id=row.merged_into))
            continue
        # 首次出现的版本晚于客户端手上的版本才是新增，否则是修改。
        # 首次出现的版本为空表示这条早于 #101 的版本追踪，一律按修改处理（多报不漏报）。
        first_seen = row.added_in_version
        is_new = since_key is None or (
            first_seen is not None and versioning.parse_version(first_seen) > since_key
        )
        (added if is_new else modified).append(_to_detail(db, row))

    return ChangesResponse(
        current_version=current,
        added=added,
        modified=modified,
        merged=merged,
        releases=release_notes,
    )


class BatchRequest(BaseModel):
    """批量读取的请求体（#101）。"""

    ids: list[IdV4] = Field(
        ...,
        min_length=1,
        max_length=BATCH_MAX_IDS,
        description=f"要读取的标准 ID，最多 {BATCH_MAX_IDS} 个",
    )


class BatchResponse(BaseModel):
    """批量读取的结果（#101）。"""

    items: list[IngredientDetail] = Field(
        description="读到完整数据的食材，按请求里的顺序；已合并的旧 ID 返回合并后的新食材"
    )
    missing_ids: list[IdV4] = Field(description="库里没有的 ID，单独列出，不影响整次请求")


def _read_batch(db: Session, ids: list[uuid.UUID]) -> BatchResponse:
    items: list[IngredientDetail] = []
    missing: list[uuid.UUID] = []
    seen: set[uuid.UUID] = set()
    for ingredient_id in ids:
        if ingredient_id in seen:  # 同一个 ID 只返回一次
            continue
        seen.add(ingredient_id)
        row = _resolve(db, ingredient_id)
        if row is None:
            missing.append(ingredient_id)
            continue
        items.append(_to_detail(db, row, requested_id=ingredient_id))
    return BatchResponse(items=items, missing_ids=missing)


@router.post("/batch", response_model=BatchResponse, responses=ERROR_RESPONSES)
def batch_get_ingredients(body: BatchRequest, db: SessionDep) -> BatchResponse:
    """按一组 ID 读取多种食材的完整数据（含详细属性和估算标记）。

    命中已合并的旧 ID 时返回合并后的新食材，并在 `requested_id` 里标明是从哪个旧 ID 转过来的；
    库里没有的 ID 收在 `missing_ids` 里单独返回，不让整次请求失败。
    """
    return _read_batch(db, list(body.ids))


@router.get("/batch", response_model=BatchResponse, responses=ERROR_RESPONSES)
def batch_get_ingredients_by_query(
    db: SessionDep,
    ids: str = Query(..., description=f"逗号分隔的标准 ID，最多 {BATCH_MAX_IDS} 个"),
) -> BatchResponse:
    """批量读取的 GET 版本，参数是逗号分隔的 ID；除此之外和 POST 完全一样。

    给不方便发请求体的客户端用。ID 数量、格式不对时按 ADR 0002 返回 422。
    """
    parts = [p.strip() for p in ids.split(",") if p.strip()]
    if len(parts) > BATCH_MAX_IDS:
        raise ApiError(
            422, "invalid_request", "请求参数有误", f"一次最多读取 {BATCH_MAX_IDS} 个食材"
        )
    try:
        parsed = TypeAdapter(list[IdV4]).validate_python(parts)
    except ValidationError as exc:
        raise ApiError(
            422,
            "invalid_request",
            "请求参数有误",
            f"ID 必须是 UUID v4：{exc}",
        ) from exc
    return _read_batch(db, parsed)


@router.get("/{ingredient_id}", response_model=IngredientDetail, responses=ERROR_RESPONSES)
def get_ingredient(ingredient_id: IdV4, db: SessionDep) -> IngredientDetail:
    """读取一种食材的完整数据。如果这个 ID 已经合并到另一个,自动返回合并后的食材。

    没经人工校对的属性带 `estimate: true`，计算和显示时按估算处理。
    """
    row = _resolve(db, ingredient_id)
    if row is None:
        raise NotFound()
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
