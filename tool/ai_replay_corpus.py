"""Materialize the sanitized SPEC-003.1 corpus as semantic-key replay files.

Run from any directory: uv run --directory server python tool/ai_replay_corpus.py --out ...
Record mode can refresh the same files using ONLY these synthetic requests.
"""

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEXT = "想做一道小朋友能吃的、不辣的宫保鸡丁"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    corpus = json.loads((ROOT / "server/tests/fixtures/ai/recipe_corpus.json").read_text("utf-8"))
    records = [
        ("intent", {"text": TEXT}, corpus["intent"]),
        (
            "generate",
            {
                "text": TEXT,
                "intent": {**corpus["intent"], "servings": 2},
                "profile": None,
                "family": None,
                "cookware_profile": None,
            },
            corpus["valid"],
        ),
        ("normalize", {"names": ["鸡腿肉", "盐"], "candidates": []}, corpus["normalization"]),
        ("embedding", {"text": "宫保鸡丁"}, corpus["embedding"]),
        ("embedding", {"text": "宫保鸡丁 鸡腿肉 盐 鸡腿肉切丁 炒"}, corpus["embedding"]),
    ]
    # The browser journey saves the synthetic draft after confirming 320 g.
    # Use the public snapshot contract's defaults, never a production recording.
    from gramtree.ai.answers import cooking_context
    from gramtree.recipes.schemas import RecipeSnapshot

    snapshot = RecipeSnapshot.model_validate(corpus["valid"]["recipe"]["snapshot"])
    snapshot.ingredients[0].quantity = 320
    context = cooking_context(snapshot, "宫保鸡丁")
    answers = json.loads((ROOT / "server/tests/fixtures/ai/answer_corpus.json").read_text("utf-8"))
    for case in answers["cases"]:
        records.append(
            (
                "explain",
                {
                    "stage": "recipe_question",
                    "question": case["question"],
                    "context": context,
                    "basis": "general_experience",
                    "evidence": None,
                    "policy_version": "recipe-answer-v1",
                },
                case["output"],
            )
        )
    from gramtree.recipes.provenance import normalize_sources
    from gramtree.recipes.reproducibility import check

    quantification = json.loads(
        (ROOT / "server/tests/fixtures/ai/quantification_corpus.json").read_text("utf-8")
    )
    snapshot = normalize_sources(
        RecipeSnapshot.model_validate(quantification["recipe"]["snapshot"])
    )
    # Manual double.toString() author evidence differs across Dart targets:
    # web emits "0", native emits "0.0". Preserve both exact synthetic inputs;
    # replay must never fall back to a different payload or a live provider.
    snapshots = [snapshot]
    native_snapshot = snapshot.model_copy(deep=True)
    for ingredient in native_snapshot.ingredients:
        source = ingredient.quantity_source
        if source is not None and source.source == "author_filled":
            source.original = str(ingredient.quantity)
    if native_snapshot != snapshot:
        snapshots.append(native_snapshot)
    for snapshot in snapshots:
        records.append(
            (
                "quantify",
                {
                    "snapshot": snapshot.model_dump(mode="json"),
                    "problems": [p.model_dump(mode="json") for p in check(snapshot).problems],
                    "ingredient_context": [
                        {
                            "id": i.id,
                            "role": i.group or "未指定",
                            "functional": i.functional,
                            "category": None,
                            "density": None,
                            "unit_weight": None,
                        }
                        for i in snapshot.ingredients
                    ],
                },
                quantification["output"],
            )
        )
    batch = json.loads(
        (ROOT / "server/tests/fixtures/ai/batch_advice_corpus.json").read_text("utf-8")
    )
    records.append(
        (
            "batch_advice",
            {"snapshot": batch["snapshot"], "target_servings": batch["target_servings"]},
            batch["valid"],
        )
    )
    from gramtree.ai.schemas import GeneratedDraft
    from gramtree.ai.service import _mark_sources

    modification = json.loads(
        (ROOT / "server/tests/fixtures/ai/modification_corpus.json").read_text("utf-8")
    )
    draft = GeneratedDraft.model_validate(corpus["valid"])
    _mark_sources(draft)
    for ingredient in draft.recipe.snapshot.ingredients:
        ingredient.base_quantity = ingredient.quantity
        ingredient.base_unit = "g"
        ingredient.scaling_mode = "proportional"
        ingredient.ingredient_id = None
    # Generation previews retain model provenance; first saves also normalize
    # missing author sources. The editor serializes unset difficulty as "",
    # so register that exact saved input without weakening semantic replay keys.
    saved_modification_snapshot = normalize_sources(draft.recipe.snapshot)
    editor_modification_snapshot = saved_modification_snapshot.model_copy(deep=True)
    editor_modification_snapshot.difficulty = ""
    modification_snapshots = [
        draft.recipe.snapshot,
        saved_modification_snapshot,
        editor_modification_snapshot,
    ]
    records.append(("modify_intent", {"text": modification["text"]}, modification["intent"]))
    for modification_snapshot in modification_snapshots:
        records.append(
            (
                "modify",
                {
                    "text": modification["text"],
                    "snapshot": modification_snapshot.model_dump(mode="json"),
                    "intent": modification["intent"],
                },
                modification["output"],
            )
        )
    # Consequential-edit browser journeys use the same synthetic first draft.
    # Materialize exact semantic inputs at both generation and saved-editor seams.
    cookware = json.loads(
        (ROOT / "server/tests/fixtures/ai/cookware_modification_corpus.json").read_text("utf-8")
    )
    records.append(("modify_intent", {"text": cookware["text"]}, cookware["intent"]))
    safe_cookware_values = {
        "instruction": "空气炸锅180°C加热鸡肉10分钟，用食品温度计确认鸡肉中心温度达到74°C后盛出",
        "duration_seconds": 600,
        "doneness": "用食品温度计确认鸡肉中心温度达到74°C",
    }
    from gramtree.ai.explanations import facts
    from gramtree.recipes.service import _operations

    for modification_snapshot in modification_snapshots:
        step = next(s for s in modification_snapshot.steps if s.id == "cook")
        operations = [
            {
                "id": step.id,
                "before": getattr(step, change["field"]),
                "scope": [f"steps:{step.id}:{change['field']}"],
                "intent": "换空气炸锅",
                "reason": cookware["reason"],
                "risk": cookware["risk"],
                "confidence": 0.8,
                **change,
            }
            for change in cookware["changes"]
        ]
        records.append(
            (
                "modify",
                {
                    "text": cookware["text"],
                    "snapshot": modification_snapshot.model_dump(mode="json"),
                    "intent": cookware["intent"],
                },
                {"operations": operations},
            )
        )
        corrected = [
            {**operation, "after": safe_cookware_values.get(operation["field"], operation["after"])}
            for operation in operations
        ]
        records.append(
            (
                "change_explanation",
                {"operations": facts(corrected)},
                {
                    "change_note": "改用空气炸锅，调整温度、时长、容器和中心温度判断。",
                    "tags": ["换厨具"],
                },
            )
        )
        manual = modification_snapshot.model_copy(deep=True)
        manual.steps[0].instruction = "鸡腿肉切成大小一致的两厘米丁"
        # Editing the existing form serializes an unset difficulty as empty text.
        manual.difficulty = ""
        for baseline in [saved_modification_snapshot, editor_modification_snapshot]:
            records.append(
                (
                    "change_explanation",
                    {"operations": facts(_operations(baseline, manual))},
                    {"change_note": "写清鸡肉切丁大小。", "tags": ["步骤更清楚"]},
                )
            )
    method = json.loads(
        (ROOT / "server/tests/fixtures/ai/method_modification_corpus.json").read_text("utf-8")
    )
    method_text = "合成测试：做一道先腌肉再炒的宫保鸡丁"
    method_raw = GeneratedDraft.model_validate(corpus["valid"])
    method_raw.recipe.snapshot.steps[0].id = "marinate"
    method_raw.recipe.snapshot.steps[0].action = "腌"
    method_raw.recipe.snapshot.steps[0].instruction = "鸡腿肉切丁后腌3分钟"
    method_raw.recipe.snapshot.steps[1].depends_on = ["marinate"]
    records.extend(
        [
            ("intent", {"text": method_text}, corpus["intent"]),
            ("embedding", {"text": "宫保鸡丁 鸡腿肉 盐 腌 炒"}, corpus["embedding"]),
            ("embedding", {"text": "宫保鸡丁 鸡腿肉 盐 炒 装盘"}, corpus["embedding"]),
            (
                "generate",
                {
                    "text": method_text,
                    "intent": {**corpus["intent"], "servings": 2},
                    "profile": None,
                    "family": None,
                    "cookware_profile": None,
                },
                method_raw.model_dump(mode="json"),
            ),
        ]
    )
    _mark_sources(method_raw)
    for ingredient in method_raw.recipe.snapshot.ingredients:
        ingredient.base_quantity = ingredient.quantity
        ingredient.base_unit = "g"
        ingredient.scaling_mode = "proportional"
        ingredient.ingredient_id = None
    method_saved = normalize_sources(method_raw.recipe.snapshot)
    method_editor = method_saved.model_copy(deep=True)
    method_editor.difficulty = ""
    scenarios = [
        (method["time"], modification_snapshots),
        (method["difficulty"], [method_raw.recipe.snapshot, method_saved, method_editor]),
    ]
    for scenario, scenario_snapshots in scenarios:
        records.append(("modify_intent", {"text": scenario["text"]}, scenario["intent"]))
        for scenario_snapshot in scenario_snapshots:
            steps = {s.id: s.model_dump(mode="json") for s in scenario_snapshot.steps}
            operations = []
            for change in scenario["changes"]:
                kind = change["type"]
                if kind == "remove_step":
                    before = steps[change["id"]]
                elif kind == "add_step":
                    before = None
                elif kind == "reorder_steps":
                    before = [s.id for s in scenario_snapshot.steps]
                elif kind == "change_recipe_info":
                    before = getattr(scenario_snapshot, change["field"])
                else:
                    before = steps[change["id"]][change["field"]]
                operations.append(
                    {
                        "before": before,
                        "scope": [f"{change['id'] or 'recipe'}:{change['field']}"],
                        "intent": "调整时间" if scenario is method["time"] else "简化做法",
                        "reason": method["reason"],
                        "risk": method["risk"],
                        "confidence": 0.85,
                        **change,
                    }
                )
            records.append(
                (
                    "modify",
                    {
                        "text": scenario["text"],
                        "snapshot": scenario_snapshot.model_dump(mode="json"),
                        "intent": scenario["intent"],
                    },
                    {"operations": operations},
                )
            )
    args.out.mkdir(parents=True, exist_ok=True)
    for capability, payload, output in records:
        canonical = json.dumps(
            {"capability": capability, "prompt_version": "one-line-v1", "input": payload},
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        key = hashlib.sha256(canonical.encode()).hexdigest()
        (args.out / f"{key}.json").write_text(
            json.dumps({"output": output, "usage": corpus["usage"]}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
    print(f"Materialized {len(records)} synthetic replay records in {args.out}")


if __name__ == "__main__":
    main()
