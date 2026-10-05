/// The offline serving-conversion kernel used by recipe details.
///
/// Keep this contract in lockstep with
/// `server/gramtree/recipes/serving_conversion.py` and the JSON fixture in
/// `assets/serving_conversion_cases.json`. It intentionally has no HTTP or
/// persistence dependency.
library;

import 'decimal_rounding.dart';

class ServingConversionError implements Exception {
  ServingConversionError(this.code, this.message, [this.detail]);

  final String code;
  final String message;
  final String? detail;

  @override
  String toString() => detail == null ? message : '$message ($detail)';
}

class ServingIngredientInput {
  const ServingIngredientInput({
    required this.id,
    required this.displayName,
    required this.quantity,
    required this.unit,
    this.scalingMode = 'proportional',
  });

  factory ServingIngredientInput.fromJson(Map<String, dynamic> json) =>
      ServingIngredientInput(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        scalingMode: json['scaling_mode'] as String? ?? 'proportional',
      );

  final String id;
  final String displayName;
  final double quantity;
  final String unit;
  final String scalingMode;
}

class ServingStepInput {
  const ServingStepInput({
    required this.id,
    required this.instruction,
    this.ingredientIds = const [],
    this.durationSeconds = 0,
    this.temperatureCelsius,
    this.heat,
    this.unattended = false,
    this.dependsOn = const [],
  });

  factory ServingStepInput.fromJson(Map<String, dynamic> json) =>
      ServingStepInput(
        id: json['id'] as String,
        instruction: json['instruction'] as String,
        ingredientIds: [
          for (final id in (json['ingredient_ids'] as List? ?? const []))
            id as String,
        ],
        durationSeconds: (json['duration_seconds'] as num? ?? 0).toInt(),
        temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
        heat: json['heat'] as String?,
        unattended: json['unattended'] == true,
        dependsOn: [
          for (final id in (json['depends_on'] as List? ?? const []))
            id as String,
        ],
      );

  final String id;
  final String instruction;
  final List<String> ingredientIds;
  final int durationSeconds;
  final double? temperatureCelsius;
  final String? heat;
  final bool unattended;
  final List<String> dependsOn;
}

class ConvertedServingIngredient {
  const ConvertedServingIngredient({
    required this.id,
    required this.displayName,
    required this.originalQuantity,
    required this.displayQuantity,
    required this.unit,
    required this.rule,
    required this.deviationRatio,
    required this.deviationWarning,
  });

  final String id;
  final String displayName;
  final double originalQuantity;
  final double displayQuantity;
  final String unit;
  final String rule;
  final double? deviationRatio;
  final bool deviationWarning;

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'original_quantity': originalQuantity,
    'display_quantity': displayQuantity,
    'unit': unit,
    'rule': rule,
    'deviation_ratio': deviationRatio,
    'deviation_warning': deviationWarning,
  };
}

class ConvertedServingStep {
  const ConvertedServingStep({
    required this.id,
    required this.instruction,
    required this.durationSeconds,
    required this.temperatureCelsius,
    required this.heat,
    required this.batchWarning,
    required this.batchWarningText,
  });

  final String id;
  final String instruction;
  final int durationSeconds;
  final double? temperatureCelsius;
  final String? heat;
  final bool batchWarning;
  final String? batchWarningText;

  Map<String, dynamic> toJson() => {
    'id': id,
    'instruction': instruction,
    'duration_seconds': durationSeconds,
    'temperature_celsius': temperatureCelsius,
    'heat': heat,
    'batch_warning': batchWarning,
    'batch_warning_text': batchWarningText,
  };
}

class ServingConversionWarning {
  const ServingConversionWarning({
    required this.code,
    required this.ingredientId,
    required this.message,
  });

  final String code;
  final String? ingredientId;
  final String message;

  Map<String, dynamic> toJson() => {
    'code': code,
    'ingredient_id': ingredientId,
    'message': message,
  };
}

class ServingConversionResult {
  const ServingConversionResult({
    required this.originalServings,
    required this.targetServings,
    required this.minServings,
    required this.maxServings,
    required this.ingredients,
    required this.steps,
    required this.warnings,
    required this.totalTimeSeconds,
    required this.activeTimeSeconds,
  });

  final int originalServings;
  final int targetServings;
  final int minServings;
  final int maxServings;
  final List<ConvertedServingIngredient> ingredients;
  final List<ConvertedServingStep> steps;
  final List<ServingConversionWarning> warnings;
  final int totalTimeSeconds;
  final int activeTimeSeconds;

  Map<String, dynamic> toJson() => {
    'original_servings': originalServings,
    'target_servings': targetServings,
    'min_servings': minServings,
    'max_servings': maxServings,
    'ingredients': [for (final item in ingredients) item.toJson()],
    'steps': [for (final item in steps) item.toJson()],
    'warnings': [for (final item in warnings) item.toJson()],
    'total_time_seconds': totalTimeSeconds,
    'active_time_seconds': activeTimeSeconds,
  };
}

const _batchWarning = '注意分批下锅，时间以成熟判断为准。';

/// Map a standard ingredient's library `scaling` attribute to a conversion
/// rule, mirroring `_SCALING_MODE_BY_ATTRIBUTE` on the server. Returns `null`
/// when the library has no usable default.
String? scalingRuleForLibraryAttribute(String? value) => switch (value) {
  '线性' => 'proportional',
  '固定' => 'unchanged',
  '阶梯' => 'round',
  _ => null,
};

ServingConversionResult convertServings({
  required int originalServings,
  required int targetServings,
  required List<ServingIngredientInput> ingredients,
  required List<ServingStepInput> steps,
  int minServings = 1,
  int maxServings = 20,
  double roundDeviationThreshold = 0.20,
  double batchMultiplier = 2.0,
  int? totalTimeSeconds,
  int? activeTimeSeconds,
}) {
  if (originalServings < 1) {
    throw ServingConversionError('invalid_servings', '原菜谱份数必须至少为 1');
  }
  if (minServings < 1 || maxServings < minServings) {
    throw ServingConversionError('invalid_servings_config', '份数范围配置有误');
  }
  // Always allow the original recipe to open and reset, even when its author
  // recorded a serving count outside the configured adjustment range.
  minServings = originalServings < minServings ? originalServings : minServings;
  maxServings = originalServings > maxServings ? originalServings : maxServings;
  if (targetServings < minServings || targetServings > maxServings) {
    throw ServingConversionError(
      'invalid_servings',
      '份数必须在 $minServings 到 $maxServings 之间',
      'target_servings=$targetServings 超出允许范围 $minServings..$maxServings',
    );
  }
  if (roundDeviationThreshold < 0 || batchMultiplier < 1) {
    throw ServingConversionError('invalid_servings_config', '换算阈值配置有误');
  }

  final convertedIngredients = <ConvertedServingIngredient>[];
  final warnings = <ServingConversionWarning>[];
  for (final item in ingredients) {
    // Match the server's 28-digit Decimal ratio and product context before
    // applying ROUND_HALF_UP for display.
    final ratio = DecimalValue.fromNum(targetServings)
        .dividedBy(DecimalValue.fromNum(originalServings));
    final theoreticalDecimal = DecimalValue.fromNum(item.quantity)
        .multipliedBy(ratio);
    final theoretical = theoreticalDecimal.toDouble();
    var display = theoretical;
    double? deviationRatio;
    var deviationWarning = false;
    switch (item.scalingMode) {
      case 'unchanged':
        display = item.quantity;
      case 'round':
        // An identity ratio keeps the author's count (e.g. 0.5 个). Otherwise
        // zero stays an intentional absence, and a positive amount keeps at
        // least one item; the deviation warning below explains the adjustment.
        if (targetServings == originalServings) {
          display = item.quantity;
        } else {
          display = theoreticalDecimal.quantizedHalfUp(0).toDouble();
          if (!theoreticalDecimal.isZero && display < 1) display = 1;
        }
        if (theoretical != 0) {
          deviationRatio = (display - theoretical).abs() / theoretical.abs();
          deviationWarning = deviationRatio > roundDeviationThreshold;
          if (deviationWarning) {
            warnings.add(
              ServingConversionWarning(
                code: 'round_deviation',
                ingredientId: item.id,
                message: '${item.displayName}取整后与按比例结果相差较大，请按口味微调其他用量。',
              ),
            );
          }
        }
      case 'proportional':
        break;
      default:
        throw ServingConversionError(
          'invalid_scaling_mode',
          '菜谱包含无法识别的缩放方式',
          'ingredients[${item.id}].scaling_mode=${item.scalingMode}',
        );
    }
    convertedIngredients.add(
      ConvertedServingIngredient(
        id: item.id,
        displayName: item.displayName,
        originalQuantity: item.quantity,
        // An identity conversion and an unchanged rule must not invent a
        // precision loss that makes the page claim the system changed it.
        // A proportional amount is rounded once from the exact ratio, as the
        // server quantizes its Decimal product; rounding the 12-digit
        // theoretical value first turns 0.0049999999999999994 into 0.01.
        displayQuantity:
            item.scalingMode == 'unchanged' ||
                targetServings == originalServings
            ? display
            : item.scalingMode == 'proportional'
            ? theoreticalDecimal.quantizedHalfUp(2).toDouble()
            : _roundTwoDecimals(display),
        unit: item.unit,
        rule: item.scalingMode,
        deviationRatio: deviationRatio,
        deviationWarning: deviationWarning,
      ),
    );
  }

  final largeBatch = targetServings >= originalServings * batchMultiplier;
  final convertedSteps = [
    for (final step in steps)
      ConvertedServingStep(
        id: step.id,
        instruction: step.instruction,
        durationSeconds: step.durationSeconds,
        temperatureCelsius: step.temperatureCelsius,
        heat: step.heat,
        batchWarning: largeBatch && step.ingredientIds.isNotEmpty,
        batchWarningText: largeBatch && step.ingredientIds.isNotEmpty
            ? _batchWarning
            : null,
      ),
  ];
  // Step durations and heat never scale with servings, so the re-estimated
  // times follow the recipe's derived definition: total is the longest
  // depends_on chain (independent steps may overlap) and active is the sum of
  // steps that need attention. Active time can exceed elapsed total time when
  // independent attention-required steps overlap (the shared
  // half_servings_rounding fixture: total 600, active 720). Callers pass the
  // saved derived values so an author's explicit override still wins.
  final total = totalTimeSeconds ?? _criticalPathSeconds(steps);
  final active =
      activeTimeSeconds ??
      steps
          .where((step) => !step.unattended)
          .fold<int>(0, (sum, step) => sum + step.durationSeconds);
  return ServingConversionResult(
    originalServings: originalServings,
    targetServings: targetServings,
    minServings: minServings,
    maxServings: maxServings,
    ingredients: convertedIngredients,
    steps: convertedSteps,
    warnings: warnings,
    totalTimeSeconds: total,
    activeTimeSeconds: active,
  );
}

double _roundTwoDecimals(double value) => roundHalfUp(value, fractionDigits: 2);

/// Longest chain of step durations through `dependsOn`; unknown IDs are
/// ignored and saved snapshots are validated to be acyclic.
int _criticalPathSeconds(List<ServingStepInput> steps) {
  final byId = {for (final step in steps) step.id: step};
  final finish = <String, int>{};
  int finishAt(ServingStepInput step) {
    final known = finish[step.id];
    if (known != null) return known;
    var start = 0;
    for (final id in step.dependsOn) {
      final dependency = byId[id];
      if (dependency == null) continue;
      final value = finishAt(dependency);
      if (value > start) start = value;
    }
    return finish[step.id] = start + step.durationSeconds;
  }

  return steps.fold<int>(0, (maximum, step) {
    final value = finishAt(step);
    return value > maximum ? value : maximum;
  });
}
