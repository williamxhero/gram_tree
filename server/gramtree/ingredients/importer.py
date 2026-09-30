"""把仓库里的食材库数据文件导入数据库（`gramtree ingredients import <目录>`）。

数据目录的格式：
- `manifest.json`：`{"version": "1.0.0", "changelog": "……", "ambiguous_names": ["葱"]}`，
  整份食材库一个版本号；`ambiguous_names` 可省略，登记允许多种食材共用的别名。
- 其余每个 `*.json` 文件是一个食材列表，按分类分文件只是为了方便评审，导入时不看文件名，
  分类以每条记录自己的 `category` 为准。

导入是幂等的：同一份数据导入多次结果不变。只有内容真的变了的食材，`version` 才改成本次
的版本号（增量更新靠它找出变化，见 SPEC-002.1）。标准 ID 永不删除：数据库里已有、数据
文件里却没有的 ID 会让整次导入失败，一条都不写。
"""

import json
from pathlib import Path

from pydantic import BaseModel, ConfigDict, Field, ValidationError
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from gramtree.core.ids import IdV4
from gramtree.ingredients.models import Ingredient, IngredientAlias, IngredientVersion

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


def _read_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise IngredientImportError(f"{path.name}：读不出来（{exc}）") from exc


def load_directory(data_dir: Path) -> tuple[ManifestFile, list[IngredientRecord]]:
    """读取并校验整个数据目录，不碰数据库。"""
    manifest_path = data_dir / "manifest.json"
    if not manifest_path.is_file():
        raise IngredientImportError(f"缺少 {manifest_path}")
    try:
        manifest = ManifestFile.model_validate(_read_json(manifest_path))
    except ValidationError as exc:
        raise IngredientImportError(f"manifest.json 不合格：{exc}") from exc

    records: list[IngredientRecord] = []
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
                raise IngredientImportError(f"{path.name} 第 {index + 1} 条不合格：{exc}") from exc

    _check_consistency(records, set(manifest.ambiguous_names))
    return manifest, records


def _check_consistency(records: list[IngredientRecord], ambiguous: set[str]) -> None:
    ids = {r.id for r in records}
    if len(ids) != len(records):
        raise IngredientImportError("有重复的标准 ID")
    owner: dict[str, str] = {}
    ambiguous_owners: dict[str, set[str]] = {name: set() for name in ambiguous}
    for r in records:
        if r.category not in CATEGORIES:
            raise IngredientImportError(f"{r.standard_name}：分类“{r.category}”不在登记的分类里")
        if r.standard_name in ambiguous:
            raise IngredientImportError(f"“{r.standard_name}”是标准名，不能登记成歧义名")
        for name in (r.standard_name, *r.aliases):
            if name in ambiguous:
                ambiguous_owners[name].add(str(r.id))
                continue
            other = owner.get(name)
            if other is not None and other != str(r.id):
                raise IngredientImportError(f"名称“{name}”同时指向两种食材")
            owner[name] = str(r.id)
        if r.merged_into is not None and (r.merged_into == r.id or r.merged_into not in ids):
            raise IngredientImportError(f"{r.standard_name}：merged_into 指向的食材不存在")
    for name, owners in ambiguous_owners.items():
        if len(owners) < 2:
            raise IngredientImportError(f"歧义名“{name}”只有 {len(owners)} 种食材在用，请删掉登记")
    targets = {r.id: r.merged_into for r in records}
    for r in records:
        # 合并只能指向一个没有再被合并的食材，读取时一步就能跳到位
        if r.merged_into is not None and targets[r.merged_into] is not None:
            raise IngredientImportError(f"{r.standard_name}：合并目标自己也被合并了")


def import_directory(session: Session, data_dir: Path) -> dict[str, int | str]:
    manifest, records = load_directory(data_dir)

    existing = {i.id: i for i in session.scalars(select(Ingredient))}
    missing = set(existing) - {r.id for r in records}
    if missing:
        sample = ", ".join(sorted(str(m) for m in missing)[:5])
        raise IngredientImportError(f"标准 ID 不能删除，数据文件里少了 {len(missing)} 个：{sample}")

    aliases_by_id: dict[object, set[str]] = {}
    for row in session.scalars(select(IngredientAlias)):
        aliases_by_id.setdefault(row.ingredient_id, set()).add(row.alias)

    added = changed = 0
    rows: dict[object, Ingredient] = {}
    # 先写不带合并关系的内容，再补 merged_into，避免外键引用还没写进去的食材
    for r in records:
        row = existing.get(r.id)
        if row is None:
            row = Ingredient(id=r.id, version=manifest.version)
            session.add(row)
            added += 1
        elif (
            row.standard_name,
            row.pinyin,
            row.pinyin_initials,
            row.category,
            row.merged_into,
        ) != (r.standard_name, r.pinyin, r.pinyin_initials, r.category, r.merged_into) or (
            aliases_by_id.get(r.id, set()) != set(r.aliases)
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

    if session.get(IngredientVersion, manifest.version) is None:
        session.add(IngredientVersion(version=manifest.version, changelog=manifest.changelog))
    session.commit()
    return {"version": manifest.version, "added": added, "changed": changed}
