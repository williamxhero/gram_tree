import 'package:gramtree_api/gramtree_api.dart';

import 'serving_conversion.dart';
import 'decimal_rounding.dart';

const personalizationFlavorAxes = [
  'salty',
  'sweet',
  'sour',
  'spicy',
  'numbing',
  'umami',
  'oily',
];

class PersonalizationResult {
  const PersonalizationResult({required this.quantities, required this.rules});
  final Map<String, double> quantities;
  final Map<String, String> rules;
}

/// Applies the same serving-first, flavor-second rules as the server kernel.
PersonalizationResult personalizeIngredients({
  required List<RecipeIngredient> ingredients,
  required int originalServings,
  required int targetServings,
  required Map<String, double> flavors,
  int minServings = 1,
  int maxServings = 20,
  double adjustmentLimit = .30,
}) {
  final converted = convertServings(
    originalServings: originalServings,
    targetServings: targetServings,
    minServings: minServings,
    maxServings: maxServings,
    ingredients: [
      for (final item in ingredients)
        ServingIngredientInput(
          id: item.id,
          displayName: item.displayName,
          quantity: item.quantity.toDouble(),
          unit: item.unit,
          scalingMode: item.scalingMode?.value ?? 'proportional',
        ),
    ],
    steps: const [],
  );
  final convertedById = {
    for (final item in converted.ingredients) item.id: item,
  };
  final quantities = <String, double>{};
  final rules = <String, String>{};
  for (final item in ingredients) {
    final serving = convertedById[item.id]!;
    final contribution = item.flavorContribution;
    final values = <(int?, String)>[
      (contribution?.salty, 'salty'),
      (contribution?.sweet, 'sweet'),
      (contribution?.sour, 'sour'),
      (contribution?.spicy, 'spicy'),
      (contribution?.numbing, 'numbing'),
      (contribution?.umami, 'umami'),
      (contribution?.oily, 'oily'),
    ].where((entry) => entry.$1 != null && entry.$1 != 0).toList();
    var quantity = serving.displayQuantity;
    var rule = serving.rule;
    if (item.functional == true) {
      rule = 'functional_protected';
    } else if (item.group != '主料' && values.isNotEmpty) {
      final factor =
          values
              .map(
                (entry) => 1 + entry.$1! / 3 * ((flavors[entry.$2] ?? 1) - 1),
              )
              .reduce((a, b) => a + b) /
          values.length;
      final bounded = factor.clamp(1 - adjustmentLimit, 1 + adjustmentLimit);
      quantity = DecimalValue.fromNum(quantity)
          .multipliedBy(DecimalValue.fromNum(bounded))
          .quantizedHalfUp(2)
          .toDouble();
      rule = 'taste_filter';
    }
    quantities[item.id] = quantity;
    rules[item.id] = rule;
  }
  return PersonalizationResult(quantities: quantities, rules: rules);
}

/// Builds a display-only projection when the recipe and taste profile are cached.
/// Safety remains blocked until the server can validate the result.
RecipePersonalizedOut offlinePersonalization({
  required RecipeDetail detail,
  required TasteProfileOut profile,
  required int targetServings,
  required int minServings,
  required int maxServings,
  required bool originalView,
  double adjustmentLimit = .30,
}) {
  final source = detail.version.snapshot;
  final sourceIngredients = source.ingredients ?? const <RecipeIngredient>[];
  final conversion = convertServings(
    originalServings: source.servings,
    targetServings: targetServings,
    minServings: minServings,
    maxServings: maxServings,
    ingredients: [
      for (final item in sourceIngredients)
        ServingIngredientInput(
          id: item.id,
          displayName: item.displayName,
          quantity: item.quantity.toDouble(),
          unit: item.unit,
          scalingMode: item.scalingMode?.value ?? 'proportional',
        ),
    ],
    steps: const [],
  );
  final servingById = {for (final item in conversion.ingredients) item.id: item};
  final flavors = {
    for (final entry in profile.flavors.entries)
      entry.key: entry.value.coefficient.toDouble(),
  };
  final result = originalView
      ? PersonalizationResult(
          quantities: {
            for (final item in conversion.ingredients)
              item.id: item.displayQuantity,
          },
          rules: {
            for (final item in conversion.ingredients) item.id: item.rule,
          },
        )
      : personalizeIngredients(
          ingredients: sourceIngredients,
          originalServings: source.servings,
          targetServings: targetServings,
          flavors: flavors,
          minServings: minServings,
          maxServings: maxServings,
          adjustmentLimit: adjustmentLimit,
        );
  final now = DateTime.now().toUtc().toIso8601String();
  final execution = <RecipeIngredient>[];
  final display = <PersonalizedIngredientOut>[];
  for (final item in sourceIngredients) {
    final serving = servingById[item.id]!;
    final quantity = result.quantities[item.id]!;
    var base = item.baseQuantity == null || item.quantity == 0
        ? null
        : DecimalValue.fromNum(item.baseQuantity!)
              .multipliedBy(DecimalValue.fromNum(serving.displayQuantity))
              .dividedBy(DecimalValue.fromNum(item.quantity))
              .toDouble();
    if (base != null &&
        quantity != serving.displayQuantity &&
        serving.displayQuantity != 0) {
      base = DecimalValue.fromNum(base)
          .multipliedBy(DecimalValue.fromNum(quantity))
          .dividedBy(DecimalValue.fromNum(serving.displayQuantity))
          .quantizedHalfUp(2)
          .toDouble();
    }
    execution.add(item.copyWith(quantity: quantity, baseQuantity: base));
    final rule = result.rules[item.id] ?? serving.rule;
    final changed = quantity != item.quantity || serving.rule != 'unchanged';
    final reason = switch (rule) {
      'taste_filter' => '按味型贡献和口味档案换算',
      'functional_protected' => '功能性用料保护',
      'servings' => '份数换算',
      'rounding' => '份数换算与取整',
      _ => '作者填写',
    };
    display.add(
      PersonalizedIngredientOut(
        changed: changed,
        displayName: item.displayName,
        displayQuantity: quantity,
        displayUnit: item.unit,
        factor: item.quantity == 0 ? 1 : quantity / item.quantity,
        id: item.id,
        originalName: item.displayName,
        originalQuantity: item.quantity,
        originalUnit: item.unit,
        reason: reason,
        rule: rule,
      ),
    );
  }
  final blockedSafety = RecipePersonalSafety(
    incomplete: true,
    status: RecipePersonalSafetyStatusEnum.available,
    unknownIngredients: [for (final item in sourceIngredients) item.displayName],
  );
  return RecipePersonalizedOut(
    adjustmentLimit: adjustmentLimit,
    authorizationVersion: 0,
    blocked: true,
    cacheKey: 'offline:${detail.version.id}:$targetServings:${profile.version}:$originalView',
    effectiveFlavors: flavors,
    fallback: '离线仅计算份数、味型和功能性用料；安全检查未完成，联网前不能开始做菜。',
    foodSafety: RecipeSafetyResult(
      allergensIncomplete: true,
      canSave: false,
      checkedAt: now,
      rulesVersion: 'offline-unchecked',
      stale: true,
    ),
    ingredients: display,
    inputs: PersonalizationRequest(
      targetServings: targetServings,
      versionId: detail.version.id,
    ),
    notices: const ['过敏与食品安全尚未检查'],
    profileVersion: profile.version,
    recipeId: detail.id,
    safety: blockedSafety,
    snapshot: source.copyWith(
      ingredients: execution,
      servings: targetServings,
    ),
    snapshotUnchanged: true,
    steps: [
      for (final item in source.steps ?? const <RecipeStep>[])
        PersonalizedStepOut(
          id: item.id,
          instruction: item.instruction,
          originalInstruction: item.instruction,
          source_: PersonalizedStepOutSource_Enum.recipe,
        ),
    ],
    versionId: detail.version.id,
    view: originalView
        ? RecipePersonalizedOutViewEnum.original
        : RecipePersonalizedOutViewEnum.personalized,
  );
}

/// Confirmation is scoped to one attempt, never restored from private storage.
RecipePersonalizedOut requirePersonalizationConfirmation(
  RecipePersonalizedOut result,
) => result.copyWith(
  inputs: result.inputs.copyWith(confirmAllergyRisk: false),
  blocked:
      result.blocked ||
      (result.safety.alerts ?? const []).any(
        (alert) => alert.kind == RecipePersonalSafetyAlertKindEnum.allergy,
      ),
);

/// Recomputes from the author snapshot, never repeatedly scales a rounded result.
/// Server-only substitutions and equipment steps remain the last accepted values.
RecipePersonalizedOut recompilePersonalizedServings({
  required RecipeSnapshot original,
  required RecipePersonalizedOut cached,
  required int targetServings,
  required int minServings,
  required int maxServings,
}) {
  final originalView = cached.view == RecipePersonalizedOutViewEnum.original;
  final servingOnly = convertServings(
    originalServings: original.servings,
    targetServings: targetServings,
    minServings: minServings,
    maxServings: maxServings,
    ingredients: [
      for (final item in original.ingredients ?? <RecipeIngredient>[])
        ServingIngredientInput(
          id: item.id,
          displayName: item.displayName,
          quantity: item.quantity.toDouble(),
          unit: item.unit,
          scalingMode: item.scalingMode?.value ?? 'proportional',
        ),
    ],
    steps: const [],
  );
  final servingQuantities = {
    for (final item in servingOnly.ingredients) item.id: item.displayQuantity,
  };
  final next = originalView
      ? PersonalizationResult(
          quantities: {
            for (final item in servingOnly.ingredients)
              item.id: item.displayQuantity,
          },
          rules: {
            for (final item in servingOnly.ingredients) item.id: item.rule,
          },
        )
      : personalizeIngredients(
          ingredients: original.ingredients ?? const [],
          originalServings: original.servings,
          targetServings: targetServings,
          flavors: cached.effectiveFlavors.map(
            (key, value) => MapEntry(key, value.toDouble()),
          ),
          minServings: minServings,
          maxServings: maxServings,
          adjustmentLimit: cached.adjustmentLimit.toDouble(),
        );
  final sources = {
    for (final item in original.ingredients ?? <RecipeIngredient>[])
      item.id: item,
  };
  final accepted = {
    for (final item in cached.snapshot.ingredients ?? <RecipeIngredient>[])
      item.id: item,
  };
  final ingredients = <PersonalizedIngredientOut>[];
  final execution = <RecipeIngredient>[];
  for (final item in cached.ingredients) {
    final source = sources[item.id]!;
    final current = accepted[item.id]!;
    final servingQuantity = servingQuantities[item.id]!;
    var quantity = next.quantities[item.id]!;
    var base = source.baseQuantity?.toDouble();
    if (base != null && source.quantity != 0) {
      base = DecimalValue.fromNum(base)
          .multipliedBy(DecimalValue.fromNum(servingQuantity))
          .dividedBy(DecimalValue.fromNum(source.quantity))
          .toDouble();
      if (quantity != servingQuantity && servingQuantity != 0) {
        base = DecimalValue.fromNum(base)
            .multipliedBy(DecimalValue.fromNum(quantity))
            .dividedBy(DecimalValue.fromNum(servingQuantity))
            .quantizedHalfUp(2)
            .toDouble();
      }
    }
    const adaptedRules = {'substitution', 'ai_substitution', 'child_portion'};
    if (!originalView && adaptedRules.contains(item.rule)) {
      final factors = item.adaptationFactors;
      if (factors == null || factors.isEmpty) {
        throw const FormatException('替换比例缺失，需要联网更新后才能换算份数。');
      }
      final substituted =
          current.displayName != source.displayName ||
          current.ingredientId != source.ingredientId;
      for (var index = 0; index < factors.length; index++) {
        final factor = factors[index];
        quantity = DecimalValue.fromNum(quantity)
            .multipliedBy(DecimalValue.fromNum(factor))
            .quantizedHalfUp(2)
            .toDouble();
        if (substituted && index == 0) {
          // A substitute cannot inherit the author's density conversion.
          base = current.unit == 'g' || current.unit == 'ml' ? quantity : null;
        } else if (base != null) {
          base = DecimalValue.fromNum(base)
              .multipliedBy(DecimalValue.fromNum(factor))
              .quantizedHalfUp(2)
              .toDouble();
        }
      }
    }
    execution.add(current.copyWith(quantity: quantity, baseQuantity: base));
    ingredients.add(
      item.copyWith(
        displayQuantity: quantity,
        changed:
            quantity != source.quantity ||
            current.displayName != source.displayName,
        rule: !originalView && adaptedRules.contains(item.rule)
            ? item.rule
            : (next.rules[item.id] ?? item.rule),
        reason: '份数换算；${item.reason}',
      ),
    );
  }
  return cached.copyWith(
    snapshot: cached.snapshot.copyWith(
      ingredients: execution,
      servings: targetServings,
    ),
    ingredients: ingredients,
    inputs: cached.inputs.copyWith(
      targetServings: targetServings,
      targetMold: null,
      confirmAllergyRisk: false,
    ),
    cacheKey: '${cached.cacheKey}:local-servings:$targetServings',
    blocked:
        cached.blocked ||
        (cached.safety.alerts ?? const []).any(
          (alert) => alert.kind == RecipePersonalSafetyAlertKindEnum.allergy,
        ),
    fallback: cached.foodSafety.rulesVersion == 'offline-unchecked'
        ? '离线仅计算份数、味型和功能性用料；安全检查未完成，联网前不能开始做菜。'
        : '离线已重算份数和口味；替换与厨具步骤沿用最近结果，安全检查需联网更新。',
  );
}
