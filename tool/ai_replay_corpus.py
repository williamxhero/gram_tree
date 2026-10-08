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
    from gramtree.recipes.provenance import normalize_sources
    from gramtree.recipes.reproducibility import check
    from gramtree.recipes.schemas import RecipeSnapshot

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
    # Generation previews retain model provenance; the unchanged first save
    # also normalizes missing author sources. Record both exact owned inputs.
    modification_snapshots = [draft.recipe.snapshot, normalize_sources(draft.recipe.snapshot)]
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
