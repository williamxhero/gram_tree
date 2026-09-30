"""按名称找食材：搜索（#99）和归一（#100）共用的匹配规则。

两者都用 `find_matches` 在同一组名称列（标准名、别名、拼音首字母、完整拼音）上查：搜索按
前缀查并把旧食材命中转到当前身份；归一按整名查，也看已合并的旧食材，再转到合并后的新 ID。
"""

import re
import uuid
from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Literal

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from gramtree.ingredients.models import Ingredient, IngredientAlias


class MatchKind(StrEnum):
    STANDARD_NAME = "standard_name"
    ALIAS = "alias"
    PINYIN_INITIALS = "pinyin_initials"
    PINYIN = "pinyin"


_COLUMNS = {
    MatchKind.STANDARD_NAME: Ingredient.standard_name,
    MatchKind.ALIAS: IngredientAlias.alias,
    MatchKind.PINYIN_INITIALS: Ingredient.pinyin_initials,
    MatchKind.PINYIN: Ingredient.pinyin,
}
_PINYIN_KINDS = (MatchKind.PINYIN_INITIALS, MatchKind.PINYIN)


@dataclass(frozen=True)
class NameMatch:
    kind: MatchKind
    # 命中的查询文本（拼音类已转成小写）
    text: str
    # 命中的那条记录本身，可能是已合并的旧食材
    ingredient: Ingredient
    # 命中列的原始叫法，搜索返回它，而不是用户输入的前缀
    value: str


def find_matches(
    db: Session,
    kind: MatchKind,
    texts: Iterable[str],
    *,
    prefix: bool = False,
    include_merged: bool = True,
    case_insensitive: bool = False,
) -> list[NameMatch]:
    """在一种名称列上查一批文本；`prefix` 为真时按前缀匹配，否则按整名匹配。"""
    queries = [t.lower() if case_insensitive or kind in _PINYIN_KINDS else t for t in texts]
    queries = list(dict.fromkeys(q for q in queries if q))
    if not queries:
        return []

    column = _COLUMNS[kind]
    stmt = select(Ingredient, column)
    if kind is MatchKind.ALIAS:
        stmt = stmt.join(IngredientAlias, IngredientAlias.ingredient_id == Ingredient.id)
    if not include_merged:
        stmt = stmt.where(Ingredient.merged_into.is_(None))
    compared = func.lower(column) if case_insensitive else column
    if prefix:
        stmt = stmt.where(or_(*(compared.startswith(q) for q in queries)))
    else:
        stmt = stmt.where(compared.in_(queries))

    matches: list[NameMatch] = []
    for ingredient, value in db.execute(stmt):
        compared_value = value.lower() if case_insensitive else value
        for q in queries:
            if compared_value.startswith(q) if prefix else compared_value == q:
                matches.append(NameMatch(kind, q, ingredient, value))
    return matches


# 搜索结果的排序：标准名 > 别名 > 拼音首字母 > 完整拼音
_SEARCH_ORDER = (
    MatchKind.STANDARD_NAME,
    MatchKind.ALIAS,
    MatchKind.PINYIN_INITIALS,
    MatchKind.PINYIN,
)

# 搜索结果的排序（#99）：标准名完全一致 > 别名完全一致 > 前缀（标准名 > 别名）> 拼音
# （拼音首字母 > 完整拼音）。第一层是整名命中还是前缀命中，第二层才是命中在哪一列，
# 这样“番茄”查出来的“西红柿”（它的别名就叫番茄）排在“番茄酱”这种前缀命中前面。
_MATCH_TIER = {
    (MatchKind.STANDARD_NAME, True): 0,
    (MatchKind.ALIAS, True): 1,
    (MatchKind.STANDARD_NAME, False): 2,
    (MatchKind.ALIAS, False): 3,
    (MatchKind.PINYIN_INITIALS, False): 4,
    (MatchKind.PINYIN, False): 5,
}


def _search_priority(m: NameMatch) -> int:
    """命中的档位，数字越小排得越前。"""
    if m.kind in _PINYIN_KINDS:
        return _MATCH_TIER[(m.kind, False)]
    return _MATCH_TIER[(m.kind, m.text == m.value.lower())]


@dataclass(frozen=True)
class SearchMatch:
    ingredient: Ingredient
    matched_name: str
    rank: int

    @property
    def key(self) -> tuple[int, str, str]:
        return self.rank, self.ingredient.standard_name, str(self.ingredient.id)


def search(
    db: Session,
    query: str,
    limit: int,
    *,
    after: tuple[int, str, str] | None = None,
) -> tuple[list[SearchMatch], bool]:
    """按匹配质量和现行身份定序，保留最佳命中的原始叫法，按排序键续页。"""
    matches = [
        m
        for kind in _SEARCH_ORDER
        for m in find_matches(db, kind, [query.strip()], prefix=True, case_insensitive=True)
    ]
    targets = _resolve_merged(db, matches)
    best: dict[uuid.UUID, SearchMatch] = {}
    for m in matches:
        ingredient = targets[m.ingredient.merged_into] if m.ingredient.merged_into else m.ingredient
        hit = SearchMatch(ingredient, m.value, _search_priority(m))
        current = best.get(ingredient.id)
        if current is None or (hit.rank, hit.matched_name) < (
            current.rank,
            current.matched_name,
        ):
            best[ingredient.id] = hit
    ranked = sorted(best.values(), key=lambda hit: hit.key)
    if after is not None:
        ranked = [hit for hit in ranked if hit.key > after]
    return ranked[:limit], len(ranked) > limit


Confidence = Literal["exact", "alias", "fuzzy", "ambiguous", "unrecorded"]


@dataclass(frozen=True)
class Normalized:
    confidence: Confidence
    ingredient: Ingredient | None = None
    # 只有歧义名才有，按标准名排序
    candidates: list[Ingredient] = field(default_factory=list)


_UNRECORDED = Normalized("unrecorded")


def _resolve_merged(db: Session, matches: Sequence[NameMatch]) -> dict[uuid.UUID, Ingredient]:
    """已合并的旧食材 → 合并后的新食材。导入时保证合并只有一层。"""
    target_ids = {m.ingredient.merged_into for m in matches if m.ingredient.merged_into}
    if not target_ids:
        return {}
    targets = db.scalars(select(Ingredient).where(Ingredient.id.in_(target_ids)))
    return {t.id: t for t in targets}


def _group(
    db: Session, matches: Sequence[NameMatch]
) -> dict[str, list[tuple[NameMatch, Ingredient]]]:
    """按查询文本分组，每个命中附上转到合并后的食材。"""
    targets = _resolve_merged(db, matches)
    grouped: dict[str, list[tuple[NameMatch, Ingredient]]] = {}
    for m in matches:
        merged_into = m.ingredient.merged_into
        resolved = targets[merged_into] if merged_into else m.ingredient
        grouped.setdefault(m.text, []).append((m, resolved))
    return grouped


def _distinct(hits: Sequence[tuple[NameMatch, Ingredient]]) -> list[Ingredient]:
    unique = {resolved.id: resolved for _, resolved in hits}
    return sorted(unique.values(), key=lambda i: (i.standard_name, str(i.id)))


def _classify_whole_name(hits: Sequence[tuple[NameMatch, Ingredient]]) -> Normalized:
    ingredients = _distinct(hits)
    if len(ingredients) > 1:
        return Normalized("ambiguous", candidates=ingredients)
    # 只有命中现行食材的标准名才算精确；命中别名或已合并旧食材的名字都算别名
    exact = any(
        m.kind is MatchKind.STANDARD_NAME and m.ingredient.merged_into is None for m, _ in hits
    )
    return Normalized("exact" if exact else "alias", ingredients[0])


_BRACKETS = re.compile(r"[（(【\[].*?[）)】\]]")
# 常见修饰词：去掉之后还是同一种食材
_PREFIXES = ("新鲜的", "新鲜", "鲜", "适量的", "适量", "少许", "少量", "有机", "特级", "优质")
_SUFFIXES = ("适量", "少许", "少量", "丝", "末", "碎", "丁", "片", "段", "块", "粒", "泥", "花")
_ASCII = re.compile(r"[a-z' ]+")


def _variants(name: str) -> list[str]:
    """去掉括号内容、空格、常见修饰词和切法后缀，得到可能是标准叫法的候选写法（含中间结果）。"""
    out: list[str] = []
    base = name
    while True:
        if base != name and base not in out:
            out.append(base)
        stripped = _BRACKETS.sub("", base).strip()
        if stripped == base:
            stripped = base.replace(" ", "")
        if stripped == base:
            for prefix in _PREFIXES:
                if base.startswith(prefix) and len(base) > len(prefix):
                    stripped = base[len(prefix) :]
                    break
            else:
                for suffix in _SUFFIXES:
                    if base.endswith(suffix) and len(base) > len(suffix):
                        stripped = base[: -len(suffix)]
                        break
        if stripped == base or not stripped:
            break
        base = stripped
    return out


def _classify_fuzzy(hits: Sequence[tuple[NameMatch, Ingredient]]) -> Normalized:
    ingredients = _distinct(hits)
    # 只有唯一候选才敢认；落到歧义名上或撞上多个食材都不认
    return Normalized("fuzzy", ingredients[0]) if len(ingredients) == 1 else _UNRECORDED


def normalize(db: Session, names: Sequence[str]) -> list[Normalized]:
    """把一批名称归一到标准食材，结果和输入一一对应、顺序相同。

    先按整名匹配标准名和别名（含已合并食材的旧名），没命中的再按去掉修饰词后的写法和
    拼音（完整拼音，要求输入本来就是拼音）匹配，只有唯一候选才算模糊匹配。
    """
    keys = [n.strip() for n in names]
    by_text = _group(
        db,
        [
            *find_matches(db, MatchKind.STANDARD_NAME, keys),
            *find_matches(db, MatchKind.ALIAS, keys),
        ],
    )

    unresolved = [k for k in keys if k not in by_text]
    variants: dict[str, list[str]] = {}
    for key in unresolved:
        variants[key] = _variants(key)
    variant_keys = list(dict.fromkeys(v for vs in variants.values() for v in vs))

    by_variant = _group(
        db,
        [
            *find_matches(db, MatchKind.STANDARD_NAME, variant_keys),
            *find_matches(db, MatchKind.ALIAS, variant_keys),
        ],
    )
    pinyin_keys = [k for k in unresolved if _ASCII.fullmatch(k.lower())]
    by_pinyin = _group(db, find_matches(db, MatchKind.PINYIN, pinyin_keys))

    results: list[Normalized] = []
    for key in keys:
        if key in by_text:
            results.append(_classify_whole_name(by_text[key]))
            continue
        found = _UNRECORDED
        # 先试修得最少的写法，命中就不再往下试；命中多个候选按规则判为未收录
        for variant in variants[key]:
            if variant in by_variant:
                found = _classify_fuzzy(by_variant[variant])
                break
        else:
            # 拼音类匹配统一按小写查，分组也用的小写
            if (pinyin := by_pinyin.get(key.lower())) is not None:
                found = _classify_fuzzy(pinyin)
        results.append(found)
    return results
