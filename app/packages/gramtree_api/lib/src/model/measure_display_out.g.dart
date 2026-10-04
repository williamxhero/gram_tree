// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_display_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeasureDisplayOutCWProxy {
  MeasureDisplayOut displayQuantity(num displayQuantity);

  MeasureDisplayOut displayUnit(String displayUnit);

  MeasureDisplayOut grams(num? grams);

  MeasureDisplayOut rule(MeasureDisplayOutRuleEnum rule);

  MeasureDisplayOut source_(SourcedValue source_);

  MeasureDisplayOut text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureDisplayOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureDisplayOut(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureDisplayOut call({
    num displayQuantity,
    String displayUnit,
    num? grams,
    MeasureDisplayOutRuleEnum rule,
    SourcedValue source_,
    String text,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMeasureDisplayOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMeasureDisplayOut.copyWith.fieldName(...)`
class _$MeasureDisplayOutCWProxyImpl implements _$MeasureDisplayOutCWProxy {
  const _$MeasureDisplayOutCWProxyImpl(this._value);

  final MeasureDisplayOut _value;

  @override
  MeasureDisplayOut displayQuantity(num displayQuantity) =>
      this(displayQuantity: displayQuantity);

  @override
  MeasureDisplayOut displayUnit(String displayUnit) =>
      this(displayUnit: displayUnit);

  @override
  MeasureDisplayOut grams(num? grams) => this(grams: grams);

  @override
  MeasureDisplayOut rule(MeasureDisplayOutRuleEnum rule) => this(rule: rule);

  @override
  MeasureDisplayOut source_(SourcedValue source_) => this(source_: source_);

  @override
  MeasureDisplayOut text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureDisplayOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureDisplayOut(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureDisplayOut call({
    Object? displayQuantity = const $CopyWithPlaceholder(),
    Object? displayUnit = const $CopyWithPlaceholder(),
    Object? grams = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return MeasureDisplayOut(
      displayQuantity: displayQuantity == const $CopyWithPlaceholder()
          ? _value.displayQuantity
          // ignore: cast_nullable_to_non_nullable
          : displayQuantity as num,
      displayUnit: displayUnit == const $CopyWithPlaceholder()
          ? _value.displayUnit
          // ignore: cast_nullable_to_non_nullable
          : displayUnit as String,
      grams: grams == const $CopyWithPlaceholder()
          ? _value.grams
          // ignore: cast_nullable_to_non_nullable
          : grams as num?,
      rule: rule == const $CopyWithPlaceholder()
          ? _value.rule
          // ignore: cast_nullable_to_non_nullable
          : rule as MeasureDisplayOutRuleEnum,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as SourcedValue,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $MeasureDisplayOutCopyWith on MeasureDisplayOut {
  /// Returns a callable class that can be used as follows: `instanceOfMeasureDisplayOut.copyWith(...)` or like so:`instanceOfMeasureDisplayOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeasureDisplayOutCWProxy get copyWith =>
      _$MeasureDisplayOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeasureDisplayOut _$MeasureDisplayOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MeasureDisplayOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'display_quantity',
            'display_unit',
            'rule',
            'source',
            'text',
          ],
        );
        final val = MeasureDisplayOut(
          displayQuantity: $checkedConvert('display_quantity', (v) => v as num),
          displayUnit: $checkedConvert('display_unit', (v) => v as String),
          grams: $checkedConvert('grams', (v) => v as num?),
          rule: $checkedConvert(
            'rule',
            (v) => $enumDecode(_$MeasureDisplayOutRuleEnumEnumMap, v),
          ),
          source_: $checkedConvert(
            'source',
            (v) => SourcedValue.fromJson(v as Map<String, dynamic>),
          ),
          text: $checkedConvert('text', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'displayQuantity': 'display_quantity',
        'displayUnit': 'display_unit',
        'source_': 'source',
      },
    );

Map<String, dynamic> _$MeasureDisplayOutToJson(MeasureDisplayOut instance) =>
    <String, dynamic>{
      'display_quantity': instance.displayQuantity,
      'display_unit': instance.displayUnit,
      'grams': ?instance.grams,
      'rule': _$MeasureDisplayOutRuleEnumEnumMap[instance.rule]!,
      'source': instance.source_.toJson(),
      'text': instance.text,
    };

const _$MeasureDisplayOutRuleEnumEnumMap = {
  MeasureDisplayOutRuleEnum.base_: 'base',
  MeasureDisplayOutRuleEnum.standardMeasure: 'standard_measure',
  MeasureDisplayOutRuleEnum.personalMeasure: 'personal_measure',
  MeasureDisplayOutRuleEnum.noDensity: 'no_density',
};
