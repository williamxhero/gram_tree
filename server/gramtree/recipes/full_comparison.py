"""Deterministic full comparison; the legacy ingredient engine remains authoritative."""

import hashlib
import json
import math
import uuid
from decimal import Decimal
from typing import Any, Literal

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError, NotFound
from gramtree.recipes import service
from gramtree.recipes.comparison import (
    ComparisonChange,
    ComparisonVersion,
    Pairing,
    compare_ingredients,
)
from gramtree.recipes.models import Recipe, RecipeComparisonCache, RecipeVersion
from gramtree.recipes.schemas import ChangeConclusion, RecipeIngredient, RecipeSnapshot, RecipeStep
from gramtree.runtime_config import service as config

Grade = Literal["excluded", "minor", "general", "significant"]


class GradedComparisonChange(ComparisonChange):
    grade: Grade
    rule_id: str
    rules_version: str


class StepComparisonChange(BaseModel):
    kind: Literal["added", "removed", "field", "text", "order"]
    field: str
    before: Any = None
    after: Any = None
    relative_change: float | None = None
    unit: str | None = None
    basis: str
    grade: Grade
    rule_id: str
    rules_version: str


class GradedIngredientComparisonRow(BaseModel):
    before: RecipeIngredient | None = None
    after: RecipeIngredient | None = None
    pairing: Pairing
    changes: list[GradedComparisonChange] = Field(default_factory=list)


class StepComparisonRow(BaseModel):
    before: RecipeStep | None = None
    after: RecipeStep | None = None
    before_index: int | None = None
    after_index: int | None = None
    alignment: Literal["deterministic", "uncertain", "unpaired"]
    confidence: float = Field(ge=0, le=1)
    basis: str
    changes: list[StepComparisonChange] = Field(default_factory=list)


class RecipeFullComparison(BaseModel):
    scope: Literal["full"] = "full"
    from_version: ComparisonVersion
    to_version: ComparisonVersion
    normalized_servings: int
    ingredients: list[GradedIngredientComparisonRow]
    snapshot_fields: list[GradedComparisonChange]
    steps: list[StepComparisonRow]
    method_changes: list[GradedComparisonChange]
    conclusion: ChangeConclusion
    rules_version: str
    basis: list[str]


class Rules(BaseModel):
    minor_threshold: float = Field(ge=0, le=1, allow_inf_nan=False)
    main_groups: list[str]
    heating_actions: list[str]
    alignment_threshold: float = Field(ge=0, le=1, allow_inf_nan=False)
    alignment_margin: float = Field(ge=0, le=1, allow_inf_nan=False)
    numerical_relative_tolerance: float = 1e-10

    @property
    def version(self) -> str:
        payload = json.dumps(self.model_dump(), sort_keys=True, ensure_ascii=False)
        return "full-v2-" + hashlib.sha256(payload.encode()).hexdigest()[:32]


def rules(session: Session) -> Rules:
    return Rules(
        minor_threshold=config.get(session, "recipe.comparison_minor_threshold"),
        main_groups=config.get(session, "recipe.comparison_main_groups")["values"],
        heating_actions=config.get(session, "recipe.comparison_heating_actions")["values"],
        alignment_threshold=config.get(session, "recipe.comparison_alignment_threshold"),
        alignment_margin=config.get(session, "recipe.comparison_alignment_margin"),
    )


def _relative_grade(change: ComparisonChange, policy: Rules) -> tuple[Grade, str, str]:
    # Decimal makes the inclusive boundary independent of floating-point noise.
    relative = None
    if change.relative_change is not None:
        before, after = Decimal(str(change.before)), Decimal(str(change.after))
        if before:
            relative = abs((after - before) / before)
    at_boundary = relative is not None and math.isclose(
        float(relative),
        policy.minor_threshold,
        rel_tol=policy.numerical_relative_tolerance,
        abs_tol=0,
    )
    # Use the same comparison tolerance as the legacy quantity engine. Unit
    # conversion can turn an exact 20% reduction into 19.99999999999999%.
    if relative is not None and relative < Decimal(str(policy.minor_threshold)) and not at_boundary:
        return (
            "minor",
            "relative_below_threshold",
            f"相对变化绝对值小于 {policy.minor_threshold:.0%}，单条为微调；不累计升级",
        )
    if change.relative_change is None:
        return (
            "general",
            "relative_unavailable",
            "原值为零、替换或无法可靠换算，不计算百分比；执行变化按一般改动",
        )
    return (
        "general",
        "relative_at_threshold",
        f"相对变化绝对值达到 {policy.minor_threshold:.0%}，为一般改动；"
        f"换算边界采用与食材引擎一致的相对容差 {policy.numerical_relative_tolerance:g}",
    )


def _grade(
    change: ComparisonChange, policy: Rules, *, main: bool = False
) -> GradedComparisonChange:
    grade: Grade = "general"
    rule_id, reason = "execution_change", "执行字段变化为一般改动"
    if change.kind == "text":
        grade, rule_id, reason = (
            "excluded",
            "wording_only",
            "纯显示名、说明或要点文字，不计配方幅度",
        )
    elif main and (change.kind in {"added", "removed", "replacement"} or change.field == "group"):
        grade, rule_id, reason = (
            "significant",
            "main_ingredient_change",
            "配置的主料分组发生新增、删除或替换",
        )
    elif change.kind == "quantity":
        grade, rule_id, reason = _relative_grade(change, policy)
    elif change.field == "cookware":
        grade, rule_id, reason = "significant", "cookware_change", "厨具改变为显著改动"
    elif change.kind == "unit":
        rule_id, reason = "unconvertible_unit", "无法可靠换算的单位按一般执行变化；不计算百分比"
    return GradedComparisonChange(
        **change.model_dump(exclude={"basis"}),
        grade=grade,
        rule_id=rule_id,
        rules_version=policy.version,
        basis=change.basis + "；" + reason,
    )


def _step_change(
    kind: Literal["added", "removed", "field", "text", "order"],
    field: str,
    before: Any,
    after: Any,
    policy: Rules,
    *,
    relative: float | None = None,
) -> StepComparisonChange:
    change = ComparisonChange(
        kind="quantity" if field == "duration_seconds" else "field" if kind == "order" else kind,
        field=field,
        before=before,
        after=after,
        relative_change=relative,
        basis="确定性步骤对齐后比较原始字段"
        if kind not in {"added", "removed"}
        else "确定算法未对齐，按删除或新增计算；不采用模型对齐",
    )
    graded = _grade(change, policy)
    return StepComparisonChange(**{**graded.model_dump(), "kind": kind})


def _align_steps(
    a: list[RecipeStep],
    b: list[RecipeStep],
    a_refs: dict[str, int],
    b_refs: dict[str, int],
    policy: Rules,
) -> tuple[dict[int, int], list[list[float]]]:
    """Weighted monotone sequence alignment, followed by unique moved-step recovery.

    Forward/backward scores expose all near-optimal edges, not just an arbitrary
    traceback. IDs and prose are never matching signals. A moved step is recovered
    only when both sides have one clearly best semantic candidate.
    """

    def refs(step: RecipeStep, mapping: dict[str, int]) -> set[int]:
        return {mapping[ref] for ref in step.ingredient_ids}

    def similarity(left: RecipeStep, right: RecipeStep) -> float:
        action = bool(left.action and left.action == right.action)
        x, y = refs(left, a_refs), refs(right, b_refs)
        overlap = len(x & y) / len(x | y) if x | y else 0
        return 0.6 * action + 0.4 * overlap

    scores = [[similarity(left, right) for right in b] for left in a]
    n, m = len(a), len(b)
    forward = [[0.0] * (m + 1) for _ in range(n + 1)]
    backward = [[0.0] * (m + 1) for _ in range(n + 1)]
    for i in range(n):
        for j in range(m):
            match = (
                scores[i][j]
                if scores[i][j] >= policy.alignment_threshold and scores[i][j] > 0
                else -math.inf
            )
            forward[i + 1][j + 1] = max(forward[i][j + 1], forward[i + 1][j], forward[i][j] + match)
    for i in range(n - 1, -1, -1):
        for j in range(m - 1, -1, -1):
            match = (
                scores[i][j]
                if scores[i][j] >= policy.alignment_threshold and scores[i][j] > 0
                else -math.inf
            )
            backward[i][j] = max(
                backward[i + 1][j], backward[i][j + 1], backward[i + 1][j + 1] + match
            )
    best = forward[n][m]
    possible_a: list[list[int]] = [[] for _ in a]
    possible_b: list[list[int]] = [[] for _ in b]
    for i in range(n):
        for j in range(m):
            if (
                scores[i][j] > 0
                and scores[i][j] >= policy.alignment_threshold
                and best - (forward[i][j] + scores[i][j] + backward[i + 1][j + 1])
                <= policy.alignment_margin + 1e-10
            ):
                possible_a[i].append(j)
                possible_b[j].append(i)
    pairs: dict[int, int] = {}
    for i, candidates in enumerate(possible_a):
        if len(candidates) != 1:
            continue
        j = candidates[0]
        deleted_score = max(forward[i][k] + backward[i + 1][k] for k in range(m + 1))
        added_score = max(forward[k][j] + backward[k][j + 1] for k in range(n + 1))
        if (
            len(possible_b[j]) == 1
            and best - max(deleted_score, added_score) > policy.alignment_margin + 1e-10
        ):
            pairs[i] = j
    # Sequence inversion may have two equally good monotone paths. Recover only
    # globally unique mutual semantic matches; repeated candidates stay uncertain.
    for i in range(n):
        if i in pairs or not m:
            continue
        ranked = sorted(range(m), key=lambda j: (-scores[i][j], j))
        j = ranked[0]
        score = scores[i][j]
        column = sorted((scores[k][j] for k in range(n)), reverse=True)
        if (
            j not in pairs.values()
            and score > 0
            and score >= policy.alignment_threshold
            and (m == 1 or score - scores[i][ranked[1]] > policy.alignment_margin + 1e-10)
            and (n == 1 or score - column[1] > policy.alignment_margin + 1e-10)
            and score == column[0]
        ):
            pairs[i] = j
    return pairs, scores


def _compare_steps(
    a: RecipeSnapshot,
    b: RecipeSnapshot,
    ingredients: list[GradedIngredientComparisonRow],
    policy: Rules,
) -> tuple[list[StepComparisonRow], list[GradedComparisonChange]]:
    a_refs = {row.before.id: i for i, row in enumerate(ingredients) if row.before}
    b_refs = {row.after.id: i for i, row in enumerate(ingredients) if row.after}
    pairs, scores = _align_steps(a.steps, b.steps, a_refs, b_refs, policy)

    # An instruction-only sequence with unchanged execution structure has no
    # method evidence to align, but a no-op or prose edit must not invent a
    # deletion/addition. Compare its unchanged positional slots without using
    # IDs/prose as a method signal. Different execution fields remain uncertain.
    def execution_shape(snapshot: RecipeSnapshot, refs: dict[str, int]) -> list[dict[str, Any]]:
        positions = {step.id: i for i, step in enumerate(snapshot.steps)}
        result = []
        for step in snapshot.steps:
            fields = step.model_dump(mode="json", exclude={"id", "instruction", "notes", "why"})
            fields = {key: value for key, value in fields.items() if not key.endswith("_source")}
            fields["ingredient_ids"] = sorted({refs[r] for r in step.ingredient_ids})
            fields["depends_on"] = sorted({positions[r] for r in step.depends_on})
            result.append(fields)
        return result

    unchanged_structure = execution_shape(a, a_refs) == execution_shape(b, b_refs)
    if unchanged_structure:
        for i, (left, right) in enumerate(zip(a.steps, b.steps, strict=True)):
            if (
                not left.action
                and not right.action
                and not left.ingredient_ids
                and not right.ingredient_ids
            ):
                pairs[i] = i
    a_steps = {a.steps[i].id: i for i in range(len(a.steps))}
    b_steps = {b.steps[j].id: i for i, j in pairs.items()}
    rows = []
    for i, before in enumerate(a.steps):
        j = pairs.get(i)
        if j is None:
            confidence = max(scores[i], default=0)
            rows.append(
                StepComparisonRow(
                    before=before,
                    before_index=i + 1,
                    alignment="uncertain" if b.steps else "unpaired",
                    confidence=confidence,
                    basis="动作及配对食材不足或存在接近对法，保留原始步骤",
                    changes=[
                        _step_change(
                            "removed", "step", before.model_dump(mode="json"), None, policy
                        )
                    ],
                )
            )
            continue
        after = b.steps[j]
        changes = []
        left, right = before.model_dump(mode="json"), after.model_dump(mode="json")
        for field in sorted(left):
            if field == "id" or field.endswith("_source"):
                continue
            semantic_change = False
            before_value, after_value = left[field], right[field]
            if field == "ingredient_ids":
                if {a_refs[r] for r in before.ingredient_ids} == {
                    b_refs[r] for r in after.ingredient_ids
                }:
                    continue
                semantic_change = True
                before_value = [
                    {"id": item.id, "display_name": item.display_name}
                    for item in a.ingredients
                    if item.id in before.ingredient_ids
                ]
                after_value = [
                    {"id": item.id, "display_name": item.display_name}
                    for item in b.ingredients
                    if item.id in after.ingredient_ids
                ]
            if field == "depends_on":
                x = {
                    ("paired", a_steps[r]) if a_steps[r] in pairs else ("before", r)
                    for r in before.depends_on
                }
                y = {
                    ("paired", b_steps[r]) if r in b_steps else ("after", r)
                    for r in after.depends_on
                }
                if x == y:
                    continue
                semantic_change = True
                before_value = [
                    {"id": s.id, "action": s.action} for s in a.steps if s.id in before.depends_on
                ]
                after_value = [
                    {"id": s.id, "action": s.action} for s in b.steps if s.id in after.depends_on
                ]
            if semantic_change or left[field] != right[field]:
                relative = (
                    (after.duration_seconds - before.duration_seconds) / before.duration_seconds
                    if field == "duration_seconds" and before.duration_seconds
                    else None
                )
                change = _step_change(
                    "text" if field in {"instruction", "notes", "why"} else "field",
                    field,
                    before_value,
                    after_value,
                    policy,
                    relative=relative,
                )
                if semantic_change:
                    change.basis += "；按配对后的引用目标比较，原 ID 字符串相同也可能引用不同目标"
                changes.append(change)
        if any((i - k) * (j - target) < 0 for k, target in pairs.items()):
            changes.append(_step_change("order", "order", i + 1, j + 1, policy))
        rows.append(
            StepComparisonRow(
                before=before,
                after=after,
                before_index=i + 1,
                after_index=j + 1,
                alignment="deterministic",
                confidence=scores[i][j],
                basis="动作和引用未填写，顺序及执行结构完全一致，仅对照文字，不推断烹饪方法"
                if not scores[i][j]
                else "按动作类型和已配对食材引用做确定性序列对齐；不使用编号或说明措辞",
                changes=changes,
            )
        )
    for j, after in enumerate(b.steps):
        if j not in pairs.values():
            confidence = max((scores[i][j] for i in range(len(a.steps))), default=0)
            rows.append(
                StepComparisonRow(
                    after=after,
                    after_index=j + 1,
                    alignment="uncertain" if a.steps else "unpaired",
                    confidence=confidence,
                    basis="未能确定对齐，保留原始新增步骤",
                    changes=[
                        _step_change("added", "step", None, after.model_dump(mode="json"), policy)
                    ],
                )
            )

    def heating(snapshot: RecipeSnapshot) -> list[str]:
        main = {item.id for item in snapshot.ingredients if item.group in policy.main_groups}
        return sorted(
            {
                step.action
                for step in snapshot.steps
                if step.action in policy.heating_actions and main.intersection(step.ingredient_ids)
            }
        )

    method_changes = []
    for field, left, right, rule_id, basis in (
        (
            "main_heating_actions",
            heating(a),
            heating(b),
            "main_heating_methods",
            "引用主料的配置加热动作集合改变，为显著改动",
        ),
        (
            "cookware",
            sorted({s.cookware for s in a.steps if s.cookware}),
            sorted({s.cookware for s in b.steps if s.cookware}),
            "cookware_change",
            "厨具集合改变，为显著改动",
        ),
    ):
        if left != right:
            method_changes.append(
                GradedComparisonChange(
                    kind="field",
                    field=field,
                    before=left,
                    after=right,
                    basis=basis,
                    grade="significant",
                    rule_id=rule_id,
                    rules_version=policy.version,
                )
            )
    return rows, method_changes


def _visible_pair(
    session: Session, owner: User, recipe_id: uuid.UUID, from_id: uuid.UUID, to_id: uuid.UUID
) -> tuple[RecipeVersion, RecipeVersion]:
    anchor = service._owned_recipe(session, owner, recipe_id)
    versions = []
    for version_id in (from_id, to_id):
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
        versions.append(version)
    return versions[0], versions[1]


def compare_full(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    from_version_id: uuid.UUID,
    to_version_id: uuid.UUID,
    *,
    commit: bool = True,
) -> RecipeFullComparison:
    # Permission checks must precede EVERY cache read, including save-time reuse.
    a_version, b_version = _visible_pair(session, owner, recipe_id, from_version_id, to_version_id)
    policy = rules(session)
    key = (from_version_id, to_version_id, policy.version)
    cached = session.get(RecipeComparisonCache, key)
    if cached is not None:
        return RecipeFullComparison.model_validate(cached.result)
    ingredient_result = compare_ingredients(
        session, owner, recipe_id, from_version_id, to_version_id
    )
    a, b = (
        RecipeSnapshot.model_validate(a_version.snapshot),
        RecipeSnapshot.model_validate(b_version.snapshot),
    )
    ingredients = []
    for row in ingredient_result.ingredients:
        main = any(
            item is not None and item.group in policy.main_groups
            for item in (row.before, row.after)
        )
        changes = [_grade(change, policy, main=main) for change in row.changes]
        after = row.after
        if row.before is not None and after is not None:
            original_after = next(item for item in b.ingredients if item.id == after.id)
            unresolved = (
                row.before.base_quantity is None
                or row.before.base_unit is None
                or original_after.base_quantity is None
                or original_after.base_unit is None
            )
            if unresolved:
                # Legacy ingredient comparison deliberately retains its scope and
                # response. Full comparison must not treat unresolved amounts as
                # numerical zero or hide changes to the original household amount.
                if original_after.base_quantity is None:
                    after = after.model_copy(update={"base_quantity": None})
                changed = (row.before.quantity, row.before.unit) != (
                    original_after.quantity,
                    original_after.unit,
                )
                scaled_unknown = (
                    a.servings != b.servings
                    and service._snapshot_scaling_mode(original_after) != "unchanged"
                )
                if (changed or scaled_unknown) and not any(c.kind == "unit" for c in changes):
                    changes.append(
                        _grade(
                            ComparisonChange(
                                kind="unit",
                                field="quantity_unit",
                                before={"quantity": row.before.quantity, "unit": row.before.unit},
                                after={
                                    "quantity": original_after.quantity,
                                    "unit": original_after.unit,
                                },
                                basis="基础量未知，保留原始用量；不能可靠归一或换算，不把未知量当零",
                            ),
                            policy,
                        )
                    )
        ingredients.append(
            GradedIngredientComparisonRow(
                before=row.before, after=after, pairing=row.pairing, changes=changes
            )
        )
    snapshot_fields = [_grade(change, policy) for change in ingredient_result.snapshot_fields]
    steps, method_changes = _compare_steps(a, b, ingredients, policy)
    all_changes: list[GradedComparisonChange | StepComparisonChange] = (
        [c for row in ingredients for c in row.changes] + snapshot_fields + method_changes
    )
    all_changes.extend(c for row in steps for c in row.changes)
    grades = {change.grade for change in all_changes}
    conclusion: ChangeConclusion = (
        "significant"
        if "significant" in grades
        else "general"
        if "general" in grades
        else "minor_only"
        if all_changes
        else "no_change"
    )
    determining = [
        c for c in all_changes if c.grade == ("minor" if conclusion == "minor_only" else conclusion)
    ]
    if not determining:
        determining = all_changes
    result = RecipeFullComparison(
        from_version=ingredient_result.from_version,
        to_version=ingredient_result.to_version,
        normalized_servings=ingredient_result.normalized_servings,
        ingredients=ingredients,
        snapshot_fields=snapshot_fields,
        steps=steps,
        method_changes=method_changes,
        conclusion=conclusion,
        rules_version=policy.version,
        basis=list(dict.fromkeys(c.basis for c in determining)) or ["归一化后没有差异"],
    )
    session.execute(
        insert(RecipeComparisonCache)
        .values(
            from_version_id=from_version_id,
            to_version_id=to_version_id,
            rules_version=policy.version,
            result=result.model_dump(mode="json"),
        )
        .on_conflict_do_nothing()
    )
    if commit:
        session.commit()
    return result
