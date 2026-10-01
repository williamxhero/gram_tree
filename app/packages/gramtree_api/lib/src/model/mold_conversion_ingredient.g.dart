// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mold_conversion_ingredient.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MoldConversionIngredientCWProxy {
  MoldConversionIngredient deviationRatio(num? deviationRatio);

  MoldConversionIngredient deviationWarning(bool? deviationWarning);

  MoldConversionIngredient displayName(String displayName);

  MoldConversionIngredient displayQuantity(num displayQuantity);

  MoldConversionIngredient id(String id);

  MoldConversionIngredient originalQuantity(num originalQuantity);

  MoldConversionIngredient rule(MoldConversionIngredientRuleEnum rule);

  MoldConversionIngredient unit(String unit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversionIngredient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversionIngredient(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversionIngredient call({
    num? deviationRatio,
    bool? deviationWarning,
    String displayName,
    num displayQuantity,
    String id,
    num originalQuantity,
    MoldConversionIngredientRuleEnum rule,
    String unit,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMoldConversionIngredient.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMoldConversionIngredient.copyWith.fieldName(...)`
class _$MoldConversionIngredientCWProxyImpl
    implements _$MoldConversionIngredientCWProxy {
  const _$MoldConversionIngredientCWProxyImpl(this._value);

  final MoldConversionIngredient _value;

  @override
  MoldConversionIngredient deviationRatio(num? deviationRatio) =>
      this(deviationRatio: deviationRatio);

  @override
  MoldConversionIngredient deviationWarning(bool? deviationWarning) =>
      this(deviationWarning: deviationWarning);

  @override
  MoldConversionIngredient displayName(String displayName) =>
      this(displayName: displayName);

  @override
  MoldConversionIngredient displayQuantity(num displayQuantity) =>
      this(displayQuantity: displayQuantity);

  @override
  MoldConversionIngredient id(String id) => this(id: id);

  @override
  MoldConversionIngredient originalQuantity(num originalQuantity) =>
      this(originalQuantity: originalQuantity);

  @override
  MoldConversionIngredient rule(MoldConversionIngredientRuleEnum rule) =>
      this(rule: rule);

  @override
  MoldConversionIngredient unit(String unit) => this(unit: unit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversionIngredient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversionIngredient(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversionIngredient call({
    Object? deviationRatio = const $CopyWithPlaceholder(),
    Object? deviationWarning = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? displayQuantity = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? originalQuantity = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
  }) {
    return MoldConversionIngredient(
      deviationRatio: deviationRatio == const $CopyWithPlaceholder()
          ? _value.deviationRatio
          // ignore: cast_nullable_to_non_nullable
          : deviationRatio as num?,
      deviationWarning: deviationWarning == const $CopyWithPlaceholder()
          ? _value.deviationWarning
          // ignore: cast_nullable_to_non_nullable
          : deviationWarning as bool?,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      displayQuantity: displayQuantity == const $CopyWithPlaceholder()
          ? _value.displayQuantity
          // ignore: cast_nullable_to_non_nullable
          : displayQuantity as num,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      originalQuantity: originalQuantity == const $CopyWithPlaceholder()
          ? _value.originalQuantity
          // ignore: cast_nullable_to_non_nullable
          : originalQuantity as num,
      rule: rule == const $CopyWithPlaceholder()
          ? _value.rule
          // ignore: cast_nullable_to_non_nullable
          : rule as MoldConversionIngredientRuleEnum,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String,
    );
  }
}

extension $MoldConversionIngredientCopyWith on MoldConversionIngredient {
  /// Returns a callable class that can be used as follows: `instanceOfMoldConversionIngredient.copyWith(...)` or like so:`instanceOfMoldConversionIngredient.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MoldConversionIngredientCWProxy get copyWith =>
      _$MoldConversionIngredientCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoldConversionIngredient _$MoldConversionIngredientFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MoldConversionIngredient',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'display_name',
        'display_quantity',
        'id',
        'original_quantity',
        'rule',
        'unit',
      ],
    );
    final val = MoldConversionIngredient(
      deviationRatio: $checkedConvert('deviation_ratio', (v) => v as num?),
      deviationWarning: $checkedConvert(
        'deviation_warning',
        (v) => v as bool? ?? false,
      ),
      displayName: $checkedConvert('display_name', (v) => v as String),
      displayQuantity: $checkedConvert('display_quantity', (v) => v as num),
      id: $checkedConvert('id', (v) => v as String),
      originalQuantity: $checkedConvert('original_quantity', (v) => v as num),
      rule: $checkedConvert(
        'rule',
        (v) => $enumDecode(_$MoldConversionIngredientRuleEnumEnumMap, v),
      ),
      unit: $checkedConvert('unit', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'deviationRatio': 'deviation_ratio',
    'deviationWarning': 'deviation_warning',
    'displayName': 'display_name',
    'displayQuantity': 'display_quantity',
    'originalQuantity': 'original_quantity',
  },
);

Map<String, dynamic> _$MoldConversionIngredientToJson(
  MoldConversionIngredient instance,
) => <String, dynamic>{
  'deviation_ratio': ?instance.deviationRatio,
  'deviation_warning': ?instance.deviationWarning,
  'display_name': instance.displayName,
  'display_quantity': instance.displayQuantity,
  'id': instance.id,
  'original_quantity': instance.originalQuantity,
  'rule': _$MoldConversionIngredientRuleEnumEnumMap[instance.rule]!,
  'unit': instance.unit,
};

const _$MoldConversionIngredientRuleEnumEnumMap = {
  MoldConversionIngredientRuleEnum.moldRatio: 'mold_ratio',
  MoldConversionIngredientRuleEnum.unchanged: 'unchanged',
  MoldConversionIngredientRuleEnum.round: 'round',
};
