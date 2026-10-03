import 'package:gramtree_api/gramtree_api.dart';

import '../l10n/app_localizations.dart';

enum MeasureDisplayMode { base, standard, home }

class DisplayMeasureInput {
  const DisplayMeasureInput({
    required this.baseQuantity,
    required this.baseUnit,
    required this.density,
    required this.mode,
    this.measure,
  });

  final double baseQuantity;
  final String baseUnit;
  final double? density;
  final MeasureDisplayMode mode;
  final PersonalMeasureOut? measure;
}

class DisplayedAmount {
  const DisplayedAmount({
    required this.text,
    required this.displayQuantity,
    required this.displayUnit,
    required this.grams,
    required this.rule,
    this.baseQuantity,
    this.baseUnit,
  });

  final String text;
  final double displayQuantity;
  final String displayUnit;
  final double? grams;
  final String rule;
  final double? baseQuantity;
  final String? baseUnit;

  Map<String, dynamic> toJson() => {
    'text': text,
    'display_quantity': displayQuantity,
    'display_unit': displayUnit,
    'grams': grams,
    'rule': rule,
  };
}

const _fractions = <double>[0.25, 1 / 3, 0.5, 2 / 3, 0.75, 1];

({double value, String text}) _roundedFraction(double value) {
  if (value <= 0) return (value: 0, text: '0');
  var whole = value.floor();
  final remainder = value - whole;
  if (remainder < 0.125) return (value: whole.toDouble(), text: '$whole');
  final fraction = _fractions.reduce(
    (a, b) => (a - remainder).abs() <= (b - remainder).abs() ? a : b,
  );
  var rounded = whole + fraction;
  if (rounded == whole + 1) {
    whole++;
    rounded = whole.toDouble();
  }
  if (rounded == rounded.roundToDouble()) {
    return (value: rounded, text: rounded.toInt().toString());
  }
  final text = (fraction - 0.25).abs() < 0.01
      ? '1/4'
      : (fraction - 1 / 3).abs() < 0.01
      ? '1/3'
      : (fraction - 0.5).abs() < 0.01
      ? '1/2'
      : (fraction - 2 / 3).abs() < 0.01
      ? '2/3'
      : '3/4';
  return (value: rounded, text: whole == 0 ? text : '$whole $text');
}

double? _grams(double quantity, String unit, double? density) {
  if (unit == 'g') return quantity;
  if (unit == 'ml' && density != null) return quantity * density;
  return null;
}

String _quantityText(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');

DisplayedAmount _base(DisplayMeasureInput input, {String? rule}) {
  final unit = input.baseUnit == 'g' ? 'g' : 'ml';
  final unitText = unit == 'g' ? '克' : '毫升';
  final grams = _grams(input.baseQuantity, unit, input.density);
  return DisplayedAmount(
    text: '${_quantityText(input.baseQuantity)} $unitText',
    displayQuantity: input.baseQuantity,
    displayUnit: unit,
    grams: unit == 'ml' && input.density == null ? null : grams,
    rule: rule ?? 'base',
    baseQuantity: input.baseQuantity,
    baseUnit: input.baseUnit,
  );
}

DisplayedAmount _standard(DisplayMeasureInput input) {
  double? millilitres = input.baseUnit == 'ml'
      ? input.baseQuantity
      : input.density == null
      ? null
      : input.baseQuantity / input.density!;
  if (millilitres == null) return _base(input, rule: 'no_density');

  const candidates = [(15.0, '汤匙'), (5.0, '茶匙')];
  final candidate = candidates.reduce((a, b) {
    final ar = _roundedFraction(millilitres / a.$1).value;
    final br = _roundedFraction(millilitres / b.$1).value;
    final ae = (ar * a.$1 - millilitres).abs();
    final be = (br * b.$1 - millilitres).abs();
    return ae <= be ? a : b;
  });
  final fraction = _roundedFraction(millilitres / candidate.$1);
  final grams = _grams(input.baseQuantity, input.baseUnit, input.density);
  final gramsText = grams == null ? '' : '（${_quantityText(grams)} 克）';
  return DisplayedAmount(
    text: '${fraction.text} ${candidate.$2}$gramsText',
    displayQuantity: fraction.value,
    displayUnit: candidate.$2,
    grams: grams,
    rule: 'standard_measure',
    baseQuantity: input.baseQuantity,
    baseUnit: input.baseUnit,
  );
}

String localizedDisplayedAmount(
  DisplayedAmount amount,
  AppLocalizations l10n,
) {
  final unit = switch (amount.displayUnit) {
    'g' => l10n.recipeMeasureGram,
    'ml' => l10n.recipeMeasureMillilitre,
    '汤匙' => l10n.recipeMeasureTablespoon,
    '茶匙' => l10n.recipeMeasureTeaspoon,
    _ => amount.displayUnit,
  };
  if (amount.rule == 'base' || amount.rule == 'no_density') {
    return '${_quantityText(amount.displayQuantity)} $unit';
  }
  final fraction = _roundedFraction(amount.displayQuantity).text;
  final parenthetical = amount.grams != null
      ? '（${_quantityText(amount.grams!)} ${l10n.recipeMeasureGram}）'
      : amount.baseUnit == 'ml' && amount.baseQuantity != null
      ? '（${_quantityText(amount.baseQuantity!)} ${l10n.recipeMeasureMillilitre}）'
      : '';
  final prefix = amount.rule == 'personal_measure'
      ? '${l10n.recipeMeasureApproximate} '
      : '';
  return '$prefix$fraction $unit$parenthetical';
}

DisplayedAmount displayAmount(DisplayMeasureInput input) {
  if (input.baseQuantity < 0 || !{'g', 'ml'}.contains(input.baseUnit)) {
    throw ArgumentError('基础量必须是非负克或毫升');
  }
  if (input.density != null && input.density! <= 0) {
    throw ArgumentError('密度必须为正数');
  }
  switch (input.mode) {
    case MeasureDisplayMode.base:
      return _base(input);
    case MeasureDisplayMode.standard:
      return _standard(input);
    case MeasureDisplayMode.home:
      final measure = input.measure;
      if (measure == null || measure.capacityMl <= 0) {
        throw ArgumentError('自家量具模式必须提供量具');
      }
      final millilitres = input.baseUnit == 'ml'
          ? input.baseQuantity
          : input.density == null
          ? null
          : input.baseQuantity / input.density!;
      if (millilitres == null) return _base(input, rule: 'no_density');
      final fraction = _roundedFraction(
        millilitres / measure.capacityMl.toDouble(),
      );
      final grams = _grams(input.baseQuantity, input.baseUnit, input.density);
      final parenthetical = grams == null
          ? '（${_quantityText(input.baseQuantity)} 毫升）'
          : '（${_quantityText(grams)} 克）';
      return DisplayedAmount(
        text: '约 ${fraction.text} ${measure.name}$parenthetical',
        displayQuantity: fraction.value,
        displayUnit: measure.name,
        grams: grams,
        rule: 'personal_measure',
        baseQuantity: input.baseQuantity,
        baseUnit: input.baseUnit,
      );
  }
}
