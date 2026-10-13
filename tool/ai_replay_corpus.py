"""Materialize the sanitized SPEC-003.1 corpus as semantic-key replay files.

Run from any directory: uv run --directory server python tool/ai_replay_corpus.py --out ...
Record mode can refresh the same files using ONLY these synthetic requests.
"""

import argparse
import hashlib
import json
from copy import deepcopy
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
TEXT = "想做一道小朋友能吃的、不辣的宫保鸡丁"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--import-substitution-library", action="store_true")
    args = parser.parse_args()
    corpus = json.loads((ROOT / "server/tests/fixtures/ai/recipe_corpus.json").read_text("utf-8"))
    records: list[tuple[str, dict[str, Any], Any]] = [("intent", {"text": TEXT}, corpus["intent"])]
    # A fresh account has no profile until the first profile-dependent request,
    # while a later journey may have materialized the default profile. Both are
    # the same synthetic user context and must resolve to the same draft.
    profiles = [
        None,
        {
            "flavors": {
                key: 1.0
                for key in (
                    "salty",
                    "sweet",
                    "sour",
                    "spicy",
                    "numbing",
                    "umami",
                    "oily",
                )
            },
            "preferences": [],
        },
    ]
    for profile in profiles:
        records.append(
            (
                "generate",
                {
                    "text": TEXT,
                    "intent": {**corpus["intent"], "servings": 2},
                    "profile": profile,
                    "family": None,
                    "cookware_profile": None,
                },
                corpus["valid"],
            )
        )
    records.extend(
        [
            (
                "normalize",
                {"names": ["鸡腿肉", "盐"], "candidates": []},
                corpus["normalization"],
            ),
            ("embedding", {"text": "宫保鸡丁"}, corpus["embedding"]),
            (
                "embedding",
                {"text": "宫保鸡丁 鸡腿肉 盐 鸡腿肉切丁 炒"},
                corpus["embedding"],
            ),
        ]
    )
    # The browser journey saves the synthetic draft after confirming 320 g.
    # Use the public snapshot contract's defaults, never a production recording.
    from sqlalchemy.orm import Session

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
    assistance = json.loads(
        (ROOT / "server/tests/fixtures/ai/comparison_assistance_corpus.json").read_text("utf-8")
    )
    records.append(("comparison", assistance["input"], assistance["outputs"]["high_a"]))
    for scenario in assistance["scenarios"].values():
        # A missing replay is intentional for the unavailable browser flow.
        if scenario["output"] is None:
            continue
        payload = deepcopy(assistance["input"])
        for version in payload["versions"].values():
            version["dish_name"] = scenario["dish_name"]
        records.append(("comparison", payload, assistance["outputs"][scenario["output"]]))
    from gramtree.ai.schemas import GeneratedDraft
    from gramtree.ai.service import _mark_sources
    from gramtree.recipes.service import _operations, _validate_snapshot

    def editor_snapshot(
        snapshot: RecipeSnapshot, library_session: Session | None = None
    ) -> RecipeSnapshot:
        # dart-dio omits null sources but sends functional=False. Derive the
        # saved provenance through the same validation as the public save path.
        incoming = snapshot.model_dump(mode="json", exclude_none=True)
        incoming["difficulty"] = ""
        if library_session is not None:
            return _validate_snapshot(library_session, RecipeSnapshot.model_validate(incoming))
        # Original synthetic ingredients have no library IDs, so no database is needed.
        with Session() as session:
            return _validate_snapshot(session, RecipeSnapshot.model_validate(incoming))

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
    editor_modification_snapshot = editor_snapshot(saved_modification_snapshot)
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
    from gramtree.ai.modification_schemas import (
        ModificationDecision,
        ModificationIntent,
        ModificationOperation,
    )
    from gramtree.ai.modifications import _apply, _substitution_facts, _taste_expected_quantities

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
        # Explanation keys use canonical selected values, not raw model values
        # (for example the snapshot validates temperature 180 as float 180.0).
        _, _, corrected = _apply(
            modification_snapshot,
            [ModificationOperation.model_validate(operation) for operation in operations],
            [
                ModificationDecision(
                    operation_id=operation["operation_id"],
                    decision="modify" if operation["field"] in safe_cookware_values else "accept",
                    **(
                        {"after": safe_cookware_values[operation["field"]]}
                        if operation["field"] in safe_cookware_values
                        else {}
                    ),
                )
                for operation in operations
            ],
        )
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
    method_editor = editor_snapshot(method_saved)
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
    consequential = json.loads(
        (ROOT / "server/tests/fixtures/ai/taste_substitution_modification_corpus.json").read_text(
            "utf-8"
        )
    )
    taste, substitution = consequential["taste"], consequential["substitution"]
    zero_flavor = dict.fromkeys(("salty", "sweet", "sour", "spicy", "umami", "numbing", "oily"), 0)

    def consequential_draft(scenario: dict) -> GeneratedDraft:
        raw = deepcopy(corpus["valid"])
        snapshot = raw["recipe"]["snapshot"]
        chicken = snapshot["ingredients"][0]
        chicken.update(flavor_contribution=zero_flavor.copy(), functional=False)
        snapshot["ingredients"] = [chicken]
        if scenario is taste:
            snapshot["ingredients"].extend(
                {
                    **deepcopy(item),
                    "flavor_contribution": {**zero_flavor, **item["flavor_contribution"]},
                    "functional": False,
                    "group": "调味",
                    "scaling_mode": "proportional",
                }
                for item in taste["ingredients"]
            )
            snapshot["steps"][1]["instruction"] = "中火炒鸡肉至中心温度达到74°C，加入调料收汁"
        else:
            snapshot["ingredients"].append(
                {
                    "id": "wine",
                    "display_name": "料酒",
                    "quantity": substitution["original_quantity"],
                    "unit": "ml",
                    "group": "调味",
                    "functional": False,
                    "flavor_contribution": {**zero_flavor, "umami": 2},
                    "preparation": "出锅前加入",
                    "replacement": {
                        "ingredient_id": substitution["white_wine_id"],
                        "display_name": substitution["white_wine_name"],
                        "ratio": substitution["ratio"],
                        "note": "本菜谱作者登记1:2换算，适用于出锅前去腥",
                    },
                }
            )
            snapshot["steps"][1]["instruction"] = "中火炒鸡肉至中心温度达到74°C，加入料酒翻炒收汁"
        snapshot["steps"][1]["ingredient_ids"] = [i["id"] for i in snapshot["ingredients"]]
        return GeneratedDraft.model_validate(raw)

    def consequential_operation(snapshot: RecipeSnapshot, change: dict, scenario: dict) -> dict:
        collection = "steps" if change["type"].startswith("change_step") else "ingredients"
        node = next(item for item in getattr(snapshot, collection) if item.id == change["id"])
        before = node.model_dump(mode="json")
        if change["type"] != "remove_ingredient":
            before = before[change["field"]]
        return {
            "before": before,
            "scope": [collection],
            "intent": "降低咸度" if scenario is taste else "缺料替代",
            "reason": scenario["reason"],
            "risk": scenario["risk"],
            "confidence": 0.85,
            "depends_on": [],
            **change,
        }

    # These cases contain real synthetic library IDs. Derive provenance and unit
    # conversions from the imported acceptance library rather than inventing them.
    # The caller must migrate and import fixtures before materializing this corpus.
    from gramtree.ai.schemas import RecipeIntent
    from gramtree.ai.service import _validate_draft
    from gramtree.db import make_engine
    from gramtree.ingredients import matching
    from gramtree.settings import Settings

    if args.import_substitution_library:
        from gramtree.cli import main as cli

        checked = {"source": "人工整理", "status": "verified"}
        # Imports are complete releases, not patches: retain the base acceptance IDs.
        library = json.loads((ROOT / "server/tests/data/ingredients/test.json").read_text("utf-8"))
        for key, name, flavor, allergens in (
            ("wine_id", "料酒", {**zero_flavor, "umami": 1}, []),
            ("white_wine_id", substitution["white_wine_name"], {**zero_flavor, "sour": 1}, []),
            (
                "peanut_id",
                substitution["peanut_name"],
                {**zero_flavor, "salty": 1, "oily": 2},
                ["花生"],
            ),
            ("unknown_id", "未完善资料调味汁", None, None),
        ):
            entry = {
                "id": substitution[key],
                "standard_name": name,
                "aliases": [],
                "pinyin": "ceshi",
                "pinyin_initials": "c",
                "category": "调料",
            }
            if flavor is not None:
                entry["attributes"] = {
                    "base_unit": {"value": "毫升", **checked},
                    "flavor": {"value": flavor, **checked},
                    "allergens": {"value": allergens, **checked},
                    "functional": {"value": False, **checked},
                }
            library.append(entry)
        with TemporaryDirectory(prefix="gramtree-substitution-") as temporary:
            directory = Path(temporary)
            (directory / "manifest.json").write_text(
                json.dumps({"version": "172.1.0", "changelog": "合成浏览器替代用例"}),
                encoding="utf-8",
            )
            (directory / "data.json").write_text(
                json.dumps(library, ensure_ascii=False), encoding="utf-8"
            )
            if cli(["ingredients", "import", str(directory)]) != 0:
                raise RuntimeError("Synthetic substitution library import failed")

    engine = make_engine(Settings().database_url)
    try:
        with Session(engine) as library_session:
            # The substitution scenario registers replacement ingredients that only
            # exist after the synthetic library import, and its snapshots cannot be
            # validated without them. Callers that skip the import (plain unit tests
            # of the replay tooling) therefore get the taste scenario only, instead
            # of a corpus that references ingredients their database does not have.
            scenarios = (taste, substitution) if args.import_substitution_library else (taste,)
            for scenario in scenarios:
                generated = consequential_draft(scenario)
                records.append(("intent", {"text": scenario["generation_text"]}, corpus["intent"]))
                for item, match in zip(
                    generated.recipe.snapshot.ingredients,
                    matching.normalize(
                        library_session,
                        [item.display_name for item in generated.recipe.snapshot.ingredients],
                    ),
                    strict=True,
                ):
                    item.ingredient_id = (
                        match.ingredient.id
                        if match.confidence in ("exact", "alias") and match.ingredient
                        else None
                    )
                _mark_sources(generated)
                _validate_draft(
                    library_session,
                    generated,
                    RecipeIntent.model_validate({**corpus["intent"], "servings": 2}),
                )
                for profile in profiles:
                    records.append(
                        (
                            "generate",
                            {
                                "text": scenario["generation_text"],
                                "intent": {**corpus["intent"], "servings": 2},
                                "profile": profile,
                                "family": None,
                                "cookware_profile": None,
                            },
                            generated.model_dump(mode="json"),
                        )
                    )
                first_save = normalize_sources(generated.recipe.snapshot)
                form_save = normalize_sources(editor_snapshot(first_save, library_session))
                for scenario_snapshot in (
                    generated.recipe.snapshot,
                    first_save,
                    form_save,
                    editor_snapshot(form_save, library_session),
                ):
                    if scenario is taste:
                        records.append(("modify_intent", {"text": taste["text"]}, taste["intent"]))
                        for percent, expected in taste["quantities"].items():
                            intent = deepcopy(taste["intent"])
                            intent["parameters"]["adjustment_percent"] = int(percent)
                            amounts = _taste_expected_quantities(
                                library_session,
                                scenario_snapshot,
                                ModificationIntent.model_validate(intent),
                            )
                            if amounts != expected:
                                raise ValueError("Synthetic taste calculation differs from corpus")
                            changes = [
                                {
                                    "operation_id": f"reduce-{item_id}",
                                    "type": "change_quantity",
                                    "id": item_id,
                                    "field": "quantity",
                                    "after": amount,
                                }
                                for item_id, amount in amounts.items()
                            ] + deepcopy(taste["side_effects"])
                            records.append(
                                (
                                    "modify",
                                    {
                                        "text": taste["text"],
                                        "snapshot": scenario_snapshot.model_dump(mode="json"),
                                        "intent": intent,
                                        "taste_quantities": amounts,
                                    },
                                    {
                                        "operations": [
                                            consequential_operation(
                                                scenario_snapshot, change, taste
                                            )
                                            for change in changes
                                        ]
                                    },
                                )
                            )
                    else:
                        substitution_facts = _substitution_facts(
                            library_session,
                            next(
                                item for item in scenario_snapshot.ingredients if item.id == "wine"
                            ),
                        )
                        for text, target, flavor in (
                            (substitution["text"], "white_wine", {**zero_flavor, "sour": 1}),
                            (
                                substitution["peanut_text"],
                                "peanut",
                                {**zero_flavor, "salty": 1, "oily": 2},
                            ),
                            (substitution["omit_text"], None, None),
                        ):
                            records.append(
                                ("modify_intent", {"text": text}, substitution["intent"])
                            )
                            if target is None:
                                step = next(s for s in scenario_snapshot.steps if s.id == "cook")
                                changes = [
                                    {
                                        "operation_id": "clean-wine-reference",
                                        "type": "change_step_ingredients",
                                        "id": "cook",
                                        "field": "ingredient_ids",
                                        "after": [i for i in step.ingredient_ids if i != "wine"],
                                    },
                                    {
                                        "operation_id": "omit-wine-instruction",
                                        "type": "change_step_field",
                                        "id": "cook",
                                        "field": "instruction",
                                        "after": "保持原火候翻炒收汁；省略料酒会减弱去腥和香气",
                                    },
                                    {
                                        "operation_id": "remove-wine",
                                        "type": "remove_ingredient",
                                        "id": "wine",
                                        "field": "ingredients",
                                        "after": None,
                                        "depends_on": [
                                            "clean-wine-reference",
                                            "omit-wine-instruction",
                                        ],
                                    },
                                ]
                                reasons = {
                                    **substitution,
                                    "reason": substitution["omit_reason"],
                                    "risk": substitution["omit_risk"],
                                }
                            else:
                                target_id = substitution[f"{target}_id"]
                                target_name = substitution[f"{target}_name"]
                                changes = [
                                    {
                                        "operation_id": operation_id,
                                        "type": kind,
                                        "id": "wine",
                                        "field": field,
                                        "after": after,
                                        "depends_on": []
                                        if operation_id == "replace-wine"
                                        else ["replace-wine"],
                                    }
                                    for operation_id, kind, field, after in (
                                        (
                                            "replace-wine",
                                            "replace_ingredient",
                                            "ingredient_id",
                                            target_id,
                                        ),
                                        (
                                            "name-wine",
                                            "change_display_name",
                                            "display_name",
                                            target_name,
                                        ),
                                        (
                                            "flavor-wine",
                                            "change_flavor_contribution",
                                            "flavor_contribution",
                                            flavor,
                                        ),
                                        (
                                            "relation-wine",
                                            "change_replacement",
                                            "replacement",
                                            {
                                                "ingredient_id": target_id,
                                                "display_name": target_name,
                                                "ratio": substitution["ratio"],
                                                "note": (
                                                    "由料酒10ml换算而来；"
                                                    "本次替代比1:2，去腥和风味不等效"
                                                ),
                                            },
                                        ),
                                        (
                                            "quantity-wine",
                                            "change_quantity",
                                            "quantity",
                                            substitution["replacement_quantity"],
                                        ),
                                    )
                                ]
                                changes.extend(
                                    {
                                        "operation_id": f"replace-wine-instruction-{step.id}",
                                        "type": "change_step_field",
                                        "id": step.id,
                                        "field": "instruction",
                                        "after": step.instruction.replace("料酒", target_name),
                                        "depends_on": ["replace-wine"],
                                    }
                                    for step in scenario_snapshot.steps
                                    if "wine" in step.ingredient_ids and "料酒" in step.instruction
                                )
                                reasons = substitution
                            records.append(
                                (
                                    "modify",
                                    {
                                        "text": text,
                                        "snapshot": scenario_snapshot.model_dump(mode="json"),
                                        "intent": substitution["intent"],
                                        "substitution_facts": substitution_facts,
                                    },
                                    {
                                        "operations": [
                                            consequential_operation(
                                                scenario_snapshot, change, reasons
                                            )
                                            for change in changes
                                        ]
                                    },
                                )
                            )
                search_text = " ".join(
                    [generated.recipe.dish_name]
                    + [i.display_name for i in generated.recipe.snapshot.ingredients]
                    + [s.action or s.instruction for s in generated.recipe.snapshot.steps]
                )
                records.append(("embedding", {"text": search_text}, corpus["embedding"]))
    finally:
        engine.dispose()
    # Modification requests omit context when all authorized values are None.
    # Saved-editor journeys have materialized the synthetic default profile;
    # register its minimized payload too, without changing any legacy key or
    # including sensitive data, owner IDs, or dependency receipts.
    for capability, payload, output in list(records):
        if capability not in ("modify_intent", "modify"):
            continue
        for profile in profiles:
            authorized_payload = {
                "profile": profile,
                "family": None,
                "cookware_profile": None,
            }
            model_context = {
                key: value for key, value in authorized_payload.items() if value is not None
            }
            if model_context:
                records.append((capability, {**payload, "context": model_context}, output))
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
