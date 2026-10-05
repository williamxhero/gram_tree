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
    required this.decimalScale,
    required this.ingredients,
    required this.steps,
    required this.warnings,
  });

  final MoldSpec originalMold;
  final MoldSpec targetMold;
  final double areaRatio;

  /// Binary view for layout and inexpensive comparisons.
  final double scale;

  /// Context-rounded Decimal ratio used for exact boundary display calculations.
  final DecimalValue decimalScale;

  double scaleQuantity(double quantity, {int fractionDigits = 20}) =>
      DecimalValue.fromNum(quantity)
          .multipliedBy(decimalScale)
          .quantizedHalfUp(fractionDigits)
          .toDouble();

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
  // Match the server's Decimal area division at its 28-digit context precision.
  final ratio = targetArea.dividedBy(sourceArea);
  final ratioDouble = ratio.toDouble();
  final isIdentity = ratio.isOne;
  final converted = <ConvertedMoldIngredient>[];
  final warnings = <MoldConversionWarning>[];
  for (final item in ingredients) {
    // Preserve the context-rounded Decimal product until after count and
    // display quantization, including positive products smaller than 1e-12.
    final theoreticalDecimal = DecimalValue.fromNum(item.quantity)
        .multipliedBy(ratio);
    final theoretical = theoreticalDecimal.toDouble();
    var display = theoretical;
    var rule = item.scalingMode;
    DecimalValue? displayDecimal;
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
        displayDecimal = isIdentity
            ? DecimalValue.fromNum(item.quantity)
            : theoreticalDecimal.isZero
            ? DecimalValue.fromNum(0)
            : theoreticalDecimal.quantizedHalfUp(0);
        if (!theoreticalDecimal.isZero &&
            !isIdentity &&
            displayDecimal.compareTo(DecimalValue.fromNum(1)) < 0) {
          displayDecimal = DecimalValue.fromNum(1);
        }
        display = displayDecimal.toDouble();
        rule = 'round';
        if (!theoreticalDecimal.isZero) {
          final deviation = displayDecimal.relativeDifference(
            theoreticalDecimal,
          );
          deviationRatio = deviation.toDouble();
          deviationWarning =
              deviation.compareTo(
                DecimalValue.fromNum(roundDeviationThreshold),
              ) >
              0;
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
            ? theoreticalDecimal.quantizedHalfUp(2).toDouble()
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
    areaRatio: ratio.quantizedHalfUp(2).toDouble(),
    scale: ratioDouble,
    decimalScale: ratio,
    ingredients: converted,
    steps: convertedSteps,
    warnings: warnings,
  );
}

(DecimalValue, DecimalValue) _dimensions(MoldSpec mold) {
  final factor = DecimalValue.fromNum(_unitFactor(mold.unit?.value ?? 'cm'));
  DecimalValue inCentimetres(num? value, String field) =>
      DecimalValue.fromNum(_positive(value, field)).multipliedBy(factor);

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

DecimalValue _area(MoldSpec mold) {
  final (width, length) = _dimensions(mold);
  if (mold.shape == MoldSpecShapeEnum.round) {
    final radius = width.dividedBy(DecimalValue.fromNum(2));
    // Same operation order and 28-significant-digit context as Python:
    // Decimal(str(pi)) * radius * radius.
    return DecimalValue.fromNum(math.pi)
        .multipliedBy(radius)
        .multipliedBy(radius);
  }
  return width.multipliedBy(length);
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
