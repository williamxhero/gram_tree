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

/// Recomputes from the author snapshot, never repeatedly scales a rounded result.
/// Server-only substitutions and equipment steps remain the last accepted values.
RecipePersonalizedOut recompilePersonalizedServings({
  required RecipeSnapshot original,
  required RecipePersonalizedOut cached,
  required int targetServings,
  required int minServings,
  required int maxServings,
}) {
  final flavors = cached.effectiveFlavors.map(
    (key, value) => MapEntry(key, value.toDouble()),
  );
  PersonalizationResult compile(int servings) => personalizeIngredients(
    ingredients: original.ingredients ?? const [],
    originalServings: original.servings,
    targetServings: servings,
    flavors: flavors,
    minServings: minServings,
    maxServings: maxServings,
    adjustmentLimit: cached.adjustmentLimit.toDouble(),
  );
  final before = compile(cached.inputs.targetServings ?? original.servings);
  final next = compile(targetServings);
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
    var quantity = next.quantities[item.id]!;
    if (item.rule == 'substitution' && before.quantities[item.id]! != 0) {
      quantity = DecimalValue.fromNum(quantity)
          .multipliedBy(DecimalValue.fromNum(item.displayQuantity))
          .dividedBy(DecimalValue.fromNum(before.quantities[item.id]!))
          .quantizedHalfUp(2)
          .toDouble();
    }
    final current = accepted[item.id]!;
    final base = current.baseQuantity == null || current.quantity == 0
        ? null
        : DecimalValue.fromNum(current.baseQuantity!)
              .multipliedBy(DecimalValue.fromNum(quantity))
              .dividedBy(DecimalValue.fromNum(current.quantity))
              .quantizedHalfUp(2)
              .toDouble();
    execution.add(current.copyWith(quantity: quantity, baseQuantity: base));
    ingredients.add(
      item.copyWith(
        displayQuantity: quantity,
        changed:
            quantity != source.quantity ||
            current.displayName != source.displayName,
        rule: item.rule == 'substitution'
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
    fallback: '离线已重算份数和口味；替换与厨具步骤沿用最近结果，安全检查需联网更新。',
  );
}
