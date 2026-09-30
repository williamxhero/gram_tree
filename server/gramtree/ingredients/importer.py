"""把仓库里的食材库数据文件导入数据库（`gramtree ingredients import <目录>`）。

数据目录的格式：
- `manifest.json`：`{"version": "1.0.0", "changelog": "……", "ambiguous_names": ["葱"]}`，
  整份食材库一个版本号；`ambiguous_names` 可省略，登记允许多种食材共用的别名。
- 其余每个 `*.json` 文件是一个食材列表，按分类分文件只是为了方便评审，导入时不看文件名，
  分类以每条记录自己的 `category` 为准。

每条记录除了身份信息，还可以带 `attributes`（详细属性，全部可选，格式和登记值见
`gramtree/ingredients/attributes.py`）。

导入是幂等的：同一份数据导入多次结果不变。只有内容真的变了的食材（身份信息、别名，或者
任何一个属性的值、来源、校对状态），`version` 才改成本次的版本号（增量更新靠它找出变化，
见 SPEC-002.1）。新增的食材还会记下首次出现的版本（`added_in_version`，只在插入时写一次），
增量接口靠它区分“新增”和“修改”。标准 ID 永不删除：数据库里已有、数据文件里却没有的 ID
会让整次导入失败，一条都不写。任何一条记录不合格，也是整次失败，错误里写明哪个文件第几条、
哪个字段。
"""

import json
import uuid
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, ValidationError
from pydantic_core import ErrorDetails
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from gramtree.core.ids import IdV4
from gramtree.ingredients import versioning
from gramtree.ingredients.attributes import GB_ALLERGENS, IngredientAttributes
from gramtree.ingredients.models import (
    Ingredient,
    IngredientAlias,
    IngredientAttribute,
    IngredientVersion,
)

CATEGORIES = (
    "肉禽",
    "水产",
    "蔬菜",
    "水果",
    "菌菇",
    "豆制品",
    "蛋奶",
    "主食粮面",
    "坚果干货",
    "调料",
    "香料",
    "其他",
)


class IngredientImportError(Exception):
    """数据文件不合格，或者和数据库里已有的数据冲突。"""


class ManifestFile(BaseModel):
    model_config = ConfigDict(extra="forbid")

    version: str = Field(pattern=r"^\d+\.\d+\.\d+$")
    changelog: str = Field(min_length=1, max_length=2000)
    # 确需一名多指的别名（如“葱”既指小葱也指大葱）。只有登记在这里的别名才允许同时属于
    # 多种食材，归一时返回候选列表；标准名永远唯一，不能登记。
    ambiguous_names: list[str] = Field(default_factory=list)


class IngredientRecord(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: IdV4
    standard_name: str = Field(min_length=1, max_length=100)
    aliases: list[str] = Field(default_factory=list)
    pinyin: str = Field(pattern=r"^[a-z]+$", max_length=200)
    pinyin_initials: str = Field(pattern=r"^[a-z]+$", max_length=50)
    category: str
    merged_into: IdV4 | None = None
    # 属性全部可选，没写 attributes 的记录就是空属性
    attributes: IngredientAttributes = Field(default_factory=IngredientAttributes.from_stored_empty)


_BOUNDS = {"gt": "大于", "ge": "大于等于", "lt": "小于", "le": "小于等于"}


def _describe(error: ErrorDetails) -> str:
    """把一条校验错误写成“字段路径：原因（写的是 …）”。"""
    path = ""
    for part in error["loc"]:
        path += f"[{part}]" if isinstance(part, int) else f".{part}" if path else str(part)
    kind = error["type"]
    ctx = error.get("ctx") or {}
    if kind == "missing":
        reason = "有值却缺少来源" if error["loc"][-1] == "source" else "缺少这一项"
        return f"{path}：{reason}"
    if kind == "extra_forbidden":
        return f"{path}：不认识这个字段"
    if kind == "value_error":
        reason = str(ctx.get("error", error["msg"]))
    elif kind == "enum":
        expected = str(ctx.get("expected", "")).replace("'", "")
        reason = "只能是 " + expected.replace(" or ", "、").replace(", ", "、")
    elif kind == "too_short":
        reason = "不能为空"
    elif any(k in ctx for k in _BOUNDS):
        reason = "应当" + "、".join(f"{_BOUNDS[k]} {v}" for k, v in ctx.items() if k in _BOUNDS)
    else:
        reason = error["msg"]
    shown = json.dumps(error["input"], ensure_ascii=False, default=str)
    if len(shown) > 80:
        shown = shown[:77] + "..."
    return f"{path}：{reason}（写的是 {shown}）"


def _record_error(file: str, index: int, item: object, exc: ValidationError) -> str:
    name = item.get("standard_name") if isinstance(item, dict) else None
    label = f"{file} 第 {index + 1} 条" + (f"（{name}）" if isinstance(name, str) else "")
    reasons = "；".join(_describe(e) for e in exc.errors())
    return f"{label}不合格：{reasons}"


def _read_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise IngredientImportError(f"{path.name}：读不出来（{exc}）") from exc


@dataclass(frozen=True)
class _RecordLocation:
    file: str
    index: int
    standard_name: str | None

    def describe(self, field: str | None = None) -> str:
        label = f"{self.file} 第 {self.index + 1} 条"
        if self.standard_name:
            label += f"（{self.standard_name}）"
        if field:
            label += f" {field}"
        return label


def _load_directory_with_locations(
    data_dir: Path,
) -> tuple[ManifestFile, list[IngredientRecord], list[_RecordLocation]]:
    manifest_path = data_dir / "manifest.json"
    if not manifest_path.is_file():
        raise IngredientImportError(f"缺少 {manifest_path}")
    try:
        manifest = ManifestFile.model_validate(_read_json(manifest_path))
    except ValidationError as exc:
        raise IngredientImportError(f"manifest.json 不合格：{exc}") from exc

    records: list[IngredientRecord] = []
    locations: list[_RecordLocation] = []
    for path in sorted(data_dir.glob("*.json")):
        if path.name == "manifest.json":
            continue
        items = _read_json(path)
        if not isinstance(items, list):
            raise IngredientImportError(f"{path.name}：应当是一个食材列表")
        for index, item in enumerate(items):
            try:
                records.append(IngredientRecord.model_validate(item))
            except ValidationError as exc:
                raise IngredientImportError(_record_error(path.name, index, item, exc)) from exc
            locations.append(
                _RecordLocation(
                    file=path.name,
                    index=index,
                    standard_name=(
                        item.get("standard_name")
                        if isinstance(item, dict) and isinstance(item.get("standard_name"), str)
                        else None
                    ),
                )
            )

    _check_consistency(records, set(manifest.ambiguous_names), locations)
    return manifest, records, locations


def load_directory(data_dir: Path) -> tuple[ManifestFile, list[IngredientRecord]]:
    """读取并校验整个数据目录，不碰数据库。"""
    manifest, records, _ = _load_directory_with_locations(data_dir)
    return manifest, records


def _check_consistency(
    records: list[IngredientRecord],
    ambiguous: set[str],
    locations: Sequence[_RecordLocation],
) -> None:
    ids: dict[object, _RecordLocation] = {}
    for location, record in zip(locations, records, strict=True):
        previous = ids.get(record.id)
        if previous is not None:
            raise IngredientImportError(
                f"{location.describe('id')}：标准 ID 重复（也见 {previous.describe('id')}）"
            )
        ids[record.id] = location

    owner: dict[str, tuple[object, _RecordLocation, str]] = {}
    ambiguous_owners: dict[str, set[str]] = {name: set() for name in ambiguous}
    for location, record in zip(locations, records, strict=True):
        if record.category not in CATEGORIES:
            raise IngredientImportError(
                f"{location.describe('category')}：分类“{record.category}”不在登记的分类里"
            )
        if record.standard_name in ambiguous:
            raise IngredientImportError(
                f"{location.describe('standard_name')}：标准名不能登记成歧义名“{record.standard_name}”"
            )
        names = [("standard_name", record.standard_name)] + [
            ("aliases", name) for name in record.aliases
        ]
        for field, name in names:
            if name in ambiguous:
                ambiguous_owners[name].add(str(record.id))
                continue
            previous = owner.get(name)
            if previous is not None and previous[0] != record.id:
                raise IngredientImportError(
                    f"{location.describe(field)}：名称“{name}”同时指向两种食材"
                    f"（也见 {previous[1].describe(previous[2])}）"
                )
            owner[name] = (record.id, location, field)

    for name, owners in ambiguous_owners.items():
        if len(owners) < 2:
            raise IngredientImportError(
                f"manifest.json ambiguous_names[{name}]：歧义名“{name}”只有 "
                f"{len(owners)} 种食材在用"
            )

    targets = {record.id: record.merged_into for record in records}
    for location, record in zip(locations, records, strict=True):
        if record.merged_into is not None:
            if record.merged_into == record.id:
                raise IngredientImportError(f"{location.describe('merged_into')}：不能合并到自己")
            if record.merged_into not in ids:
                raise IngredientImportError(
                    f"{location.describe('merged_into')}：合并目标食材不存在"
                )
            # 合并只能指向一个没有再被合并的食材，读取时一步就能跳到位。
            if targets[record.merged_into] is not None:
                raise IngredientImportError(
                    f"{location.describe('merged_into')}：合并目标自己也被合并了"
                )


def _check_allergen_coverage(
    records: Sequence[IngredientRecord], locations: Sequence[_RecordLocation]
) -> None:
    found: set[str] = set()
    for record in records:
        if record.attributes.allergens is not None:
            found.update(record.attributes.allergens.value)
    missing = [name for name in GB_ALLERGENS if name not in found]
    if missing:
        missing_text = "、".join(missing)
        location = (
            locations[0].describe("attributes.allergens")
            if locations
            else "manifest.json attributes.allergens"
        )
        raise IngredientImportError(f"{location}：全库缺少 GB 7718 过敏原覆盖：{missing_text}")


def validate_directory(
    data_dir: Path, baseline_dir: Path | None = None
) -> tuple[ManifestFile, list[IngredientRecord]]:
    """校验食材库文件及其可选的历史基线，不连接数据库。"""
    manifest, records, locations = _load_directory_with_locations(data_dir)
    _check_allergen_coverage(records, locations)

    if baseline_dir is not None:
        if not (baseline_dir / "manifest.json").is_file():
            raise IngredientImportError(f"基线目录缺少 {baseline_dir / 'manifest.json'}")
        _, baseline_records, baseline_locations = _load_directory_with_locations(baseline_dir)
        current_ids = {record.id for record in records}
        for location, record in zip(baseline_locations, baseline_records, strict=True):
            if record.id not in current_ids:
                raise IngredientImportError(
                    f"{location.describe('id')}：标准 ID 不能删除（基线 ID {record.id} "
                    "不在当前数据里）"
                )

    return manifest, records


def _record_matches(
    row: Ingredient,
    record: IngredientRecord,
    aliases: set[str],
    attributes: Mapping[str, tuple[Any, str, str]],
) -> bool:
    return (
        (
            row.standard_name,
            row.pinyin,
            row.pinyin_initials,
            row.category,
            row.merged_into,
        )
        == (
            record.standard_name,
            record.pinyin,
            record.pinyin_initials,
            record.category,
            record.merged_into,
        )
        and aliases == set(record.aliases)
        and attributes == record.attributes.stored_fields()
    )


def _library_matches(
    existing: Mapping[uuid.UUID, Ingredient],
    records: list[IngredientRecord],
    aliases_by_id: Mapping[uuid.UUID, set[str]],
    attrs_by_id: Mapping[uuid.UUID, Mapping[str, tuple[Any, str, str]]],
) -> bool:
    """比较食材内容，不比较版本元数据（用于同版本幂等重放）。"""
    if set(existing) != {record.id for record in records}:
        return False
    return all(
        _record_matches(
            existing[record.id],
            record,
            aliases_by_id.get(record.id, set()),
            attrs_by_id.get(record.id, {}),
        )
        for record in records
    )


def import_directory(session: Session, data_dir: Path) -> dict[str, int | str]:
    manifest, records = load_directory(data_dir)
    manifest_key = versioning.parse_version(manifest.version)

    releases = list(session.scalars(select(IngredientVersion)))
    latest = versioning.latest_version(release.version for release in releases)

    existing = {i.id: i for i in session.scalars(select(Ingredient))}
    aliases_by_id: dict[uuid.UUID, set[str]] = {}
    for row in session.scalars(select(IngredientAlias)):
        aliases_by_id.setdefault(row.ingredient_id, set()).add(row.alias)

    attrs_by_id: dict[uuid.UUID, dict[str, tuple[Any, str, str]]] = {}
    for row in session.scalars(select(IngredientAttribute)):
        attrs_by_id.setdefault(row.ingredient_id, {})[row.field] = (
            row.value,
            row.source,
            row.status,
        )
    new_attrs = {r.id: r.attributes.stored_fields() for r in records}

    equivalent_release = next(
        (
            release
            for release in releases
            if versioning.parse_version(release.version) == manifest_key
        ),
        None,
    )
    if equivalent_release is not None and equivalent_release.version != manifest.version:
        raise IngredientImportError(
            f"食材库版本 {manifest.version} 与已发布版本 {equivalent_release.version} 重复"
        )

    existing_release = session.get(IngredientVersion, manifest.version)
    if existing_release is not None:
        # 同一版本重放是幂等的；即使调用方带了不同的说明，也不能改写已发布版本的说明。
        # 但同一版本的食材内容一旦变化必须报错，不能让客户端缓存悄悄失效。
        if _library_matches(existing, records, aliases_by_id, attrs_by_id):
            return {"version": manifest.version, "added": 0, "changed": 0}
        raise IngredientImportError(
            f"食材库版本 {manifest.version} 已存在，不能修改已发布的食材内容"
        )

    if latest is not None and manifest_key < versioning.parse_version(latest):
        raise IngredientImportError(
            f"食材库版本 {manifest.version} 早于当前最新版本 {latest}，不能回退"
        )

    missing = set(existing) - {r.id for r in records}
    if missing:
        sample = ", ".join(sorted(str(m) for m in missing)[:5])
        raise IngredientImportError(f"标准 ID 不能删除，数据文件里少了 {len(missing)} 个：{sample}")

    added = changed = 0
    rows: dict[uuid.UUID, Ingredient] = {}
    # 先写不带合并关系的内容，再补 merged_into，避免外键引用还没写进去的食材
    for r in records:
        row = existing.get(r.id)
        if row is None:
            # 新增：第一次出现的版本就是这一版，之后不再改，增量接口靠它区分新增和修改
            row = Ingredient(
                id=r.id,
                version=manifest.version,
                added_in_version=manifest.version,
            )
            session.add(row)
            added += 1
        elif not _record_matches(
            row,
            r,
            aliases_by_id.get(r.id, set()),
            attrs_by_id.get(r.id, {}),
        ):
            row.version = manifest.version
            changed += 1
        row.standard_name = r.standard_name
        row.pinyin = r.pinyin
        row.pinyin_initials = r.pinyin_initials
        row.category = r.category
        rows[r.id] = row
    session.flush()
    for r in records:
        rows[r.id].merged_into = r.merged_into
        if aliases_by_id.get(r.id, set()) != set(r.aliases):
            session.execute(delete(IngredientAlias).where(IngredientAlias.ingredient_id == r.id))
            session.add_all(IngredientAlias(ingredient_id=r.id, alias=a) for a in r.aliases)
        if attrs_by_id.get(r.id, {}) != new_attrs[r.id]:
            session.execute(
                delete(IngredientAttribute).where(IngredientAttribute.ingredient_id == r.id)
            )
            session.add_all(
                IngredientAttribute(
                    ingredient_id=r.id, field=field, value=value, source=source, status=status
                )
                for field, (value, source, status) in new_attrs[r.id].items()
            )

    session.add(IngredientVersion(version=manifest.version, changelog=manifest.changelog))
    session.commit()
    return {"version": manifest.version, "added": added, "changed": changed}
