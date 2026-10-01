import 'dart:math' as math;

import 'package:gramtree_api/gramtree_api.dart';

/// Offline mold conversion kernel. It mirrors
/// `server/gramtree/recipes/mold_conversion.py` and never mutates a snapshot.
class MoldConversionError implements Exception {
  MoldConversionError(this.code, this.message, [this.detail]);

  final String code;
  final String message;
  final String? detail;

  @override
  String toString() => detail == null ? message : '$message ($detail)';
}

class MoldIngredientInput {
  const MoldIngredientInput({
    required this.id,
    required this.displayName,
    required this.quantity,
    required this.unit,
    this.scalingMode = 'proportional',
  });

  final String id;
  final String displayName;
  final double quantity;
  final String unit;
  final String scalingMode;
}

class MoldStepInput {
  const MoldStepInput({
    required this.id,
    required this.instruction,
    this.durationSeconds = 0,
    this.temperatureCelsius,
    this.heat,
  });

  final String id;
  final String instruction;
  final int durationSeconds;
  final double? temperatureCelsius;
  final String? heat;
}

class ConvertedMoldIngredient {
  const ConvertedMoldIngredient({
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
}

class ConvertedMoldStep {
  const ConvertedMoldStep({
    required this.id,
    required this.instruction,
    required this.durationSeconds,
    required this.temperatureCelsius,
    required this.heat,
    required this.timeAdvisory,
    required this.donenessWarning,
    required this.donenessWarningText,
  });

  final String id;
  final String instruction;
  final int durationSeconds;
  final double? temperatureCelsius;
  final String? heat;
  final String? timeAdvisory;
  final bool donenessWarning;
  final String? donenessWarningText;
}

class MoldConversionWarning {
  const MoldConversionWarning({
    required this.code,
    required this.ingredientId,
    required this.message,
  });

  final String code;
  final String? ingredientId;
  final String message;
}

class MoldConversionResult {
  const MoldConversionResult({
    required this.originalMold,
    required this.targetMold,
    required this.areaRatio,
    required this.ingredients,
    required this.steps,
    required this.warnings,
  });

  final MoldSpec originalMold;
  final MoldSpec targetMold;
  final double areaRatio;
  final List<ConvertedMoldIngredient> ingredients;
  final List<ConvertedMoldStep> steps;
  final List<MoldConversionWarning> warnings;
}

MoldConversionResult convertMold({
  required MoldSpec originalMold,
  required MoldSpec targetMold,
  required List<MoldIngredientInput> ingredients,
  required List<MoldStepInput> steps,
  double roundDeviationThreshold = 0.20,
}) {
  final sourceArea = _area(originalMold);
  final targetArea = _area(targetMold);
  final ratio = targetArea / sourceArea;
  final converted = <ConvertedMoldIngredient>[];
  final warnings = <MoldConversionWarning>[];
  for (final item in ingredients) {
    final theoretical = item.quantity * ratio;
    var display = theoretical;
    var rule = item.scalingMode;
    double? deviationRatio;
    var deviationWarning = false;
    switch (item.scalingMode) {
      case 'proportional':
        rule = 'mold_ratio';
      case 'unchanged':
        display = item.quantity;
      case 'round':
        display = theoretical.roundToDouble().clamp(1, double.infinity);
        rule = 'round';
        if (theoretical != 0) {
          deviationRatio = (display - theoretical).abs() / theoretical.abs();
          deviationWarning = deviationRatio > roundDeviationThreshold;
          if (deviationWarning) {
            warnings.add(
              MoldConversionWarning(
                code: 'round_deviation',
                ingredientId: item.id,
                message: '${item.displayName}取整后与模具比例结果相差较大，请按实际情况微调其他用量。',
              ),
            );
          }
        }
      default:
        throw MoldConversionError(
          'invalid_scaling_mode',
          '菜谱包含无法识别的缩放方式',
          'ingredients[${item.id}].scaling_mode=${item.scalingMode}',
        );
    }
    converted.add(
      ConvertedMoldIngredient(
        id: item.id,
        displayName: item.displayName,
        originalQuantity: item.quantity,
        displayQuantity: _roundTwoDecimals(display),
        unit: item.unit,
        rule: rule,
        deviationRatio: deviationRatio,
        deviationWarning: deviationWarning,
      ),
    );
  }
  final convertedSteps = [
    for (final step in steps)
      ConvertedMoldStep(
        id: step.id,
        instruction: step.instruction,
        durationSeconds: step.durationSeconds,
        temperatureCelsius: step.temperatureCelsius,
        heat: step.heat,
        timeAdvisory: step.durationSeconds > 0
            ? '时间不按模具比例放大，建议从原时间开始检查，以成熟判断为准。'
            : null,
        donenessWarning: step.durationSeconds > 0,
        donenessWarningText: step.durationSeconds > 0
            ? '请以成熟判断为准，不要只看计时。'
            : null,
      ),
  ];
  if (convertedSteps.any((step) => step.durationSeconds > 0)) {
    warnings.add(
      const MoldConversionWarning(
        code: 'doneness_check',
        ingredientId: null,
        message: '烘烤时间不按模具比例放大，请以成熟判断为准。',
      ),
    );
  }
  return MoldConversionResult(
    originalMold: originalMold,
    targetMold: targetMold,
    areaRatio: _roundTwoDecimals(ratio),
    ingredients: converted,
    steps: convertedSteps,
    warnings: warnings,
  );
}

double _area(MoldSpec mold) {
  final factor = _unitFactor(mold.unit?.value ?? 'cm');
  switch (mold.shape) {
    case MoldSpecShapeEnum.round:
      final diameter = _positive(mold.diameter, 'diameter') * factor;
      final radius = diameter / 2;
      return math.pi * radius * radius;
    case MoldSpecShapeEnum.square:
      final side = _positive(mold.side ?? mold.width, 'side') * factor;
      if (mold.length != null &&
          mold.length != mold.side &&
          mold.length != mold.width) {
        throw MoldConversionError('invalid_mold', '方模的边长必须相等');
      }
      return side * side;
    case MoldSpecShapeEnum.rectangular:
    case MoldSpecShapeEnum.custom:
      return _positive(mold.width, 'width') *
          _positive(mold.length, 'length') *
          factor *
          factor;
  }
}

double _unitFactor(String unit) => switch (unit) {
  'cm' => 1,
  'in' || 'inch' => 2.54,
  _ => throw MoldConversionError('invalid_mold', '模具尺寸单位只支持厘米或英寸'),
};

double _positive(num? value, String field) {
  if (value == null || value <= 0) {
    throw MoldConversionError('invalid_mold', '模具尺寸必须是正数', '$field=$value');
  }
  return value.toDouble();
}

double _roundTwoDecimals(double value) => (value * 100).round() / 100;
