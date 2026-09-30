"""食材库 HTTP 接口（SPEC-002.1 #19）。

路由注册顺序有讲究：字面路径（`/unrecorded`、`/changes`、`/batch`、`/search`、`/normalize`）
必须全部排在通配的 `GET /{ingredient_id}` 前面，否则 Starlette 会把字面段当成 UUID 解析回 422。
下面的顺序就是这个顺序，加新接口时插在 `get_ingredient` 之前。
"""

import logging
import unicodedata
import uuid
from collections import Counter
from collections.abc import Callable, Mapping
from datetime import UTC, datetime
from typing import Annotated, TypeAlias

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, TypeAdapter, ValidationError, field_validator
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import (
    Page,
    PageParams,
    check_limit,
    decode_parts,
    encode_parts,
    page_params,
)
from gramtree.core.time import Timestamp
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
from gramtree.runtime_config import service as config

logger = logging.getLogger("gramtree.ingredients")

router = APIRouter(prefix="/ingredients", tags=["ingredients"])
INGREDIENT_ERROR_RESPONSES = {
    **ERROR_RESPONSES,
    404: {"model": ErrorResponse, "description": "资源不存在"},
}

# 一次批量读取的 ID 数量上限，超过按 ADR 0002 返回 422 invalid_request
BATCH_MAX_IDS = 100
PageDep = Annotated[PageParams, Depends(page_params)]


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


class SearchIngredientOut(IngredientOut):
    matched_name: str = Field(description="实际命中的叫法；已合并食材保留旧叫法")


class SearchResult(BaseModel):
    items: list[SearchIngredientOut]
    next_cursor: str | None = None


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
    first_seen_at: Timestamp
    last_seen_at: Timestamp


def _search_after(cursor: str | None, query: str) -> tuple[int, str, str] | None:
    if not cursor:
        return None
    parts = decode_parts(cursor)
    normalized_query = query.strip().casefold()
    if (
        len(parts) != 5
        or parts[0] != "search"
        or parts[1] != normalized_query
        or type(parts[2]) is not int
        or not 0 <= parts[2] <= 5
        or not isinstance(parts[3], str)
        or not parts[3]
        or not isinstance(parts[4], str)
    ):
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析")
    try:
        ingredient_id = uuid.UUID(parts[4])
        if ingredient_id.version != 4:
            raise ValueError("ID 必须是 UUID v4")
    except ValueError as exc:
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析") from exc
    return parts[2], parts[3], str(ingredient_id)


def _unrecorded_after(cursor: str | None) -> tuple[int, str] | None:
    if not cursor:
        return None
    parts = decode_parts(cursor)
    if (
        len(parts) != 3
        or parts[0] != "unrecorded"
        or type(parts[1]) is not int
        or parts[1] < 1
        or not isinstance(parts[2], str)
        or not parts[2]
    ):
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析")
    return parts[1], parts[2]


def _normalize_unrecorded_name(name: str) -> str:
    return unicodedata.normalize("NFKC", name).strip()


def _still_unrecorded(db: Session, names: list[str]) -> set[str]:
    normalized = matching.normalize(db, names)
    return {
        name
        for name, result in zip(names, normalized, strict=True)
        if result.confidence == "unrecorded"
    }


@router.get(
    "/unrecorded",
    response_model=Page[UnrecordedIngredientItem],
    responses=INGREDIENT_ERROR_RESPONSES,
)
def list_unrecorded_ingredients(
    db: SessionDep, page: PageDep, auth: CurrentAuth
) -> Page[UnrecordedIngredientItem]:
    """按出现次数降序查询仍未收录的食材，使用稳定游标分页 (#102)。"""
    del auth
    check_limit(page.limit, config.get(db, "api.page_size_max"))
    after = _unrecorded_after(page.cursor)
    rows = list(
        db.scalars(
            select(UnrecordedIngredient).order_by(
                UnrecordedIngredient.occurrence_count.desc(),
                UnrecordedIngredient.name.asc(),
            )
        )
    )
    active_names = _still_unrecorded(db, [row.name for row in rows])
    items = [
        UnrecordedIngredientItem(
            name=row.name,
            occurrence_count=row.occurrence_count,
            first_seen_at=row.first_seen_at,
            last_seen_at=row.last_seen_at,
        )
        for row in rows
        if row.name in active_names
    ]
    items.sort(key=lambda item: (-item.occurrence_count, item.name))
    if after is not None:
        count, name = after
        items = [item for item in items if (-item.occurrence_count, item.name) > (-count, name)]
    next_cursor = None
    if len(items) > page.limit:
        items = items[: page.limit]
        last = items[-1]
        next_cursor = encode_parts(["unrecorded", last.occurrence_count, last.name])
    return Page[UnrecordedIngredientItem](items=items, next_cursor=next_cursor)


@router.get("/changes", response_model=ChangesResponse, responses=INGREDIENT_ERROR_RESPONSES)
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
    for ingredient_id in ids:
        row = _resolve(db, ingredient_id)
        if row is None:
            missing.append(ingredient_id)
            continue
        # 保留输入中的重复 ID 和顺序；调用方可以用 requested_id 对每个请求项逐一对应。
        items.append(_to_detail(db, row, requested_id=ingredient_id))
    return BatchResponse(items=items, missing_ids=missing)


@router.post("/batch", response_model=BatchResponse, responses=INGREDIENT_ERROR_RESPONSES)
def batch_get_ingredients(body: BatchRequest, db: SessionDep) -> BatchResponse:
    """按一组 ID 读取多种食材的完整数据（含详细属性和估算标记）。

    命中已合并的旧 ID 时返回合并后的新食材，并在 `requested_id` 里标明是从哪个旧 ID 转过来的；
    库里没有的 ID 收在 `missing_ids` 里单独返回，不让整次请求失败。
    """
    return _read_batch(db, list(body.ids))


@router.get("/batch", response_model=BatchResponse, responses=INGREDIENT_ERROR_RESPONSES)
def batch_get_ingredients_by_query(
    db: SessionDep,
    ids: str = Query(..., description=f"逗号分隔的标准 ID，最多 {BATCH_MAX_IDS} 个"),
) -> BatchResponse:
    """批量读取的 GET 版本，参数是逗号分隔的 ID；除此之外和 POST 完全一样。

    给不方便发请求体的客户端用。ID 数量、格式不对时按 ADR 0002 返回 422。
    """
    parts = ids.split(",")
    if not ids.strip() or any(not part.strip() for part in parts):
        raise ApiError(422, "invalid_request", "请求参数有误", "ids 不能为空且不能包含空项")
    parts = [part.strip() for part in parts]
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


@router.get(
    "/{ingredient_id}", response_model=IngredientDetail, responses=INGREDIENT_ERROR_RESPONSES
)
def get_ingredient(ingredient_id: IdV4, db: SessionDep) -> IngredientDetail:
    """读取一种食材的完整数据。如果这个 ID 已经合并到另一个,自动返回合并后的食材。

    没经人工校对的属性带 `estimate: true`，计算和显示时按估算处理。
    """
    row = _resolve(db, ingredient_id)
    if row is None:
        raise NotFound()
    return _to_detail(db, row)


@router.post("/search", response_model=SearchResult, responses=INGREDIENT_ERROR_RESPONSES)
def search_ingredients(query: SearchQuery, db: SessionDep, page: PageDep) -> SearchResult:
    """搜索食材并按匹配质量返回稳定分页结果。"""
    check_limit(page.limit, config.get(db, "api.page_size_max"))
    after = _search_after(page.cursor, query.query)
    hits, has_more = matching.search(db, query.query, page.limit, after=after)
    next_cursor = (
        encode_parts(["search", query.query.strip().casefold(), *hits[-1].key])
        if has_more
        else None
    )
    return SearchResult(
        items=[
            SearchIngredientOut(
                **_to_out(db, hit.ingredient).model_dump(),
                matched_name=hit.matched_name,
            )
            for hit in hits
        ],
        next_cursor=next_cursor,
    )


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


StatisticsWriter: TypeAlias = Callable[[Session, Mapping[str, int]], None]


def _write_unrecorded_statistics(db: Session, counts: Mapping[str, int]) -> None:
    now = datetime.now(UTC)
    values = [
        {
            "id": uuid.uuid4(),
            "name": name,
            "occurrence_count": count,
            "first_seen_at": now,
            "last_seen_at": now,
        }
        for name, count in counts.items()
    ]
    statement = pg_insert(UnrecordedIngredient).values(values)
    statement = statement.on_conflict_do_update(
        index_elements=[UnrecordedIngredient.name],
        set_={
            "occurrence_count": UnrecordedIngredient.occurrence_count
            + statement.excluded.occurrence_count,
            "last_seen_at": statement.excluded.last_seen_at,
        },
    )
    try:
        with db.begin_nested():
            db.execute(statement)
            db.flush()
        db.commit()
    except SQLAlchemyError:
        db.rollback()
        raise


def get_unrecorded_statistics_writer() -> StatisticsWriter:
    """Dependency seam so the HTTP test can inject a failed statistics writer."""
    return _write_unrecorded_statistics


StatisticsWriterDep = Annotated[StatisticsWriter, Depends(get_unrecorded_statistics_writer)]


@router.post("/normalize", response_model=NormalizeResponse, responses=INGREDIENT_ERROR_RESPONSES)
def normalize_ingredients(
    body: NormalizeRequest, db: SessionDep, write_stats: StatisticsWriterDep
) -> NormalizeResponse:
    """把一批食材名称归一到标准 ID，并尽力记录未收录名称。"""
    names = [item.name for item in body.items]
    normalized = matching.normalize(db, names)
    results = [
        NormalizeResultItem(
            name=name,
            confidence=result.confidence,
            ingredient_id=result.ingredient.id if result.ingredient else None,
            standard_name=result.ingredient.standard_name if result.ingredient else None,
            candidates=[
                NormalizeCandidate(ingredient_id=c.id, standard_name=c.standard_name)
                for c in result.candidates
            ],
        )
        for name, result in zip(names, normalized, strict=True)
    ]

    # 统计不是归一化主链路：先构造完整响应，再尽力写入，写失败不能改变响应。
    counts = Counter(
        _normalize_unrecorded_name(name)
        for name, result in zip(names, normalized, strict=True)
        if result.confidence == "unrecorded"
    )
    if counts:
        try:
            write_stats(db, counts)
        except Exception:
            logger.warning("unrecorded ingredient statistics write failed", exc_info=True)
    return NormalizeResponse(results=results)
