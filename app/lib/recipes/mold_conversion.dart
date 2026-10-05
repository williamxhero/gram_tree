import 'dart:math' as math;

import 'package:gramtree_api/gramtree_api.dart';

import 'decimal_rounding.dart';

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
    this.action,
    this.cookware,
  });

  final String id;
  final String instruction;
  final int durationSeconds;
  final double? temperatureCelsius;
  final String? heat;
  final String? action;
  final String? cookware;
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
    required this.scale,
    required this.ingredients,
    required this.steps,
    required this.warnings,
  });

  final MoldSpec originalMold;
  final MoldSpec targetMold;
  final double areaRatio;

  /// Unrounded bottom-area ratio, used to keep tiny proportional amounts
  /// visible instead of collapsing them to the rounded `0`.
  final double scale;
  final List<ConvertedMoldIngredient> ingredients;
  final List<ConvertedMoldStep> steps;
  final List<MoldConversionWarning> warnings;
}

bool _isBakingStep(MoldStepInput step) {
  final context = [
    step.action,
    step.instruction,
    step.cookware,
    step.heat,
  ].whereType<String>().join(' ').toLowerCase();
  return ['烤', '焙', '烘', '烤箱', 'oven', 'bake', 'roast'].any(context.contains);
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
  // Derive same-shape ratios from dimensions before dividing binary area
  // doubles; this keeps circular areas such as 4 cm -> 5 cm at 1.5625.
  final ratio = _areaRatio(
    originalMold,
    targetMold,
    sourceArea: sourceArea,
    targetArea: targetArea,
  );
  final isIdentity = targetArea == sourceArea;
  final converted = <ConvertedMoldIngredient>[];
  final warnings = <MoldConversionWarning>[];
  for (final item in ingredients) {
    // Multiply in decimal form like the server's Decimal(str(quantity)) * ratio,
    // so a binary product such as 1.15 * 1.5 cannot round to 1.72 here.
    final theoretical = scaleByDecimalRatio(item.quantity, ratio);
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
        // An equal-area mold keeps the author's count (e.g. 0.5 个). Otherwise
        // zero stays an intentional absence, and a positive amount keeps at
        // least one item; the deviation warning below explains the adjustment.
        display = isIdentity
            ? item.quantity
            : theoretical == 0
            ? 0
            : roundHalfUp(
                theoretical,
                fractionDigits: 0,
              ).clamp(1, double.infinity).toDouble();
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
        // Preserve identity and unchanged values at source precision. A
        // proportional amount is rounded once from the decimal product, as the
        // server quantizes it; a 12-digit intermediate could round
        // 0.00499999999999995 up to 0.005 and then to 0.01.
        displayQuantity: item.scalingMode == 'unchanged' || isIdentity
            ? display
            : item.scalingMode == 'proportional'
            ? scaleByDecimalRatio(item.quantity, ratio, fractionDigits: 2)
            : _roundTwoDecimals(display),
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
        timeAdvisory: step.durationSeconds > 0 && _isBakingStep(step)
            ? '时间不按模具比例放大，建议从原时间开始检查，以成熟判断为准。'
            : null,
        donenessWarning: step.durationSeconds > 0 && _isBakingStep(step),
        donenessWarningText: step.durationSeconds > 0 && _isBakingStep(step)
            ? '请以成熟判断为准，不要只看计时。'
            : null,
      ),
  ];
  if (convertedSteps.any((step) => step.donenessWarning)) {
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
    scale: ratio,
    ingredients: converted,
    steps: convertedSteps,
    warnings: warnings,
  );
}

// Keep intermediate geometry precise enough for small valid dimensions before
// returning to the double representation used by the public conversion result.
const _geometryScaleDigits = 30;

(double, double) _dimensions(MoldSpec mold) {
  final factor = _unitFactor(mold.unit?.value ?? 'cm');
  double inCentimetres(num? value, String field) => scaleByDecimalRatio(
    _positive(value, field),
    factor,
    fractionDigits: _geometryScaleDigits,
  );

  switch (mold.shape) {
    case MoldSpecShapeEnum.round:
      final diameter = inCentimetres(mold.diameter, 'diameter');
      return (diameter, diameter);
    case MoldSpecShapeEnum.square:
      if (mold.side != null && mold.width != null && mold.side != mold.width) {
        throw MoldConversionError('invalid_mold', '方模的 side 与 width 必须一致');
      }
      final side = mold.side ?? mold.width;
      final sideInCm = inCentimetres(side, 'side');
      if (mold.length != null &&
          mold.length != mold.side &&
          mold.length != mold.width) {
        throw MoldConversionError('invalid_mold', '方模的边长必须相等');
      }
      return (sideInCm, sideInCm);
    case MoldSpecShapeEnum.rectangular:
    case MoldSpecShapeEnum.custom:
      return (
        inCentimetres(mold.width, 'width'),
        inCentimetres(mold.length, 'length'),
      );
  }
}

double _areaRatio(
  MoldSpec original,
  MoldSpec target, {
  required double sourceArea,
  required double targetArea,
}) {
  final (originalWidth, originalLength) = _dimensions(original);
  final (targetWidth, targetLength) = _dimensions(target);
  if (original.shape == MoldSpecShapeEnum.round &&
      target.shape == MoldSpecShapeEnum.round) {
    final diameterRatio = divideByDecimalRatio(
      targetWidth,
      originalWidth,
      fractionDigits: _geometryScaleDigits,
    );
    return scaleByDecimalRatio(
      diameterRatio,
      diameterRatio,
      fractionDigits: _geometryScaleDigits,
    );
  }
  if (original.shape != MoldSpecShapeEnum.round &&
      target.shape != MoldSpecShapeEnum.round) {
    final widthRatio = divideByDecimalRatio(
      targetWidth,
      originalWidth,
      fractionDigits: _geometryScaleDigits,
    );
    final lengthRatio = divideByDecimalRatio(
      targetLength,
      originalLength,
      fractionDigits: _geometryScaleDigits,
    );
    return scaleByDecimalRatio(
      widthRatio,
      lengthRatio,
      fractionDigits: _geometryScaleDigits,
    );
  }
  return divideByDecimalRatio(
    targetArea,
    sourceArea,
    fractionDigits: _geometryScaleDigits,
  );
}

double _area(MoldSpec mold) {
  final (width, length) = _dimensions(mold);
  if (mold.shape == MoldSpecShapeEnum.round) {
    final radius = scaleByIntegerRatio(
      width,
      1,
      2,
      fractionDigits: _geometryScaleDigits,
    );
    return scaleByDecimalRatio(
      math.pi,
      scaleByDecimalRatio(radius, radius, fractionDigits: _geometryScaleDigits),
      fractionDigits: _geometryScaleDigits,
    );
  }
  return scaleByDecimalRatio(
    width,
    length,
    fractionDigits: _geometryScaleDigits,
  );
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

double _roundTwoDecimals(double value) => roundHalfUp(value, fractionDigits: 2);
