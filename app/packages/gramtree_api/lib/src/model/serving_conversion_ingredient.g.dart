// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serving_conversion_ingredient.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServingConversionIngredientCWProxy {
  ServingConversionIngredient deviationRatio(num? deviationRatio);

  ServingConversionIngredient deviationWarning(bool? deviationWarning);

  ServingConversionIngredient displayName(String displayName);

  ServingConversionIngredient displayQuantity(num displayQuantity);

  ServingConversionIngredient id(String id);

  ServingConversionIngredient originalQuantity(num originalQuantity);

  ServingConversionIngredient rule(ServingConversionIngredientRuleEnum rule);

  ServingConversionIngredient unit(String unit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversionIngredient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversionIngredient(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversionIngredient call({
    num? deviationRatio,
    bool? deviationWarning,
    String displayName,
    num displayQuantity,
    String id,
    num originalQuantity,
    ServingConversionIngredientRuleEnum rule,
    String unit,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfServingConversionIngredient.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfServingConversionIngredient.copyWith.fieldName(...)`
class _$ServingConversionIngredientCWProxyImpl
    implements _$ServingConversionIngredientCWProxy {
  const _$ServingConversionIngredientCWProxyImpl(this._value);

  final ServingConversionIngredient _value;

  @override
  ServingConversionIngredient deviationRatio(num? deviationRatio) =>
      this(deviationRatio: deviationRatio);

  @override
  ServingConversionIngredient deviationWarning(bool? deviationWarning) =>
      this(deviationWarning: deviationWarning);

  @override
  ServingConversionIngredient displayName(String displayName) =>
      this(displayName: displayName);

  @override
  ServingConversionIngredient displayQuantity(num displayQuantity) =>
      this(displayQuantity: displayQuantity);

  @override
  ServingConversionIngredient id(String id) => this(id: id);

  @override
  ServingConversionIngredient originalQuantity(num originalQuantity) =>
      this(originalQuantity: originalQuantity);

  @override
  ServingConversionIngredient rule(ServingConversionIngredientRuleEnum rule) =>
      this(rule: rule);

  @override
  ServingConversionIngredient unit(String unit) => this(unit: unit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversionIngredient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversionIngredient(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversionIngredient call({
    Object? deviationRatio = const $CopyWithPlaceholder(),
    Object? deviationWarning = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? displayQuantity = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? originalQuantity = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
  }) {
    return ServingConversionIngredient(
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
          : rule as ServingConversionIngredientRuleEnum,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String,
    );
  }
}

extension $ServingConversionIngredientCopyWith on ServingConversionIngredient {
  /// Returns a callable class that can be used as follows: `instanceOfServingConversionIngredient.copyWith(...)` or like so:`instanceOfServingConversionIngredient.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServingConversionIngredientCWProxy get copyWith =>
      _$ServingConversionIngredientCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServingConversionIngredient _$ServingConversionIngredientFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ServingConversionIngredient',
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
    final val = ServingConversionIngredient(
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
        (v) => $enumDecode(_$ServingConversionIngredientRuleEnumEnumMap, v),
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

Map<String, dynamic> _$ServingConversionIngredientToJson(
  ServingConversionIngredient instance,
) => <String, dynamic>{
  'deviation_ratio': ?instance.deviationRatio,
  'deviation_warning': ?instance.deviationWarning,
  'display_name': instance.displayName,
  'display_quantity': instance.displayQuantity,
  'id': instance.id,
  'original_quantity': instance.originalQuantity,
  'rule': _$ServingConversionIngredientRuleEnumEnumMap[instance.rule]!,
  'unit': instance.unit,
};

const _$ServingConversionIngredientRuleEnumEnumMap = {
  ServingConversionIngredientRuleEnum.proportional: 'proportional',
  ServingConversionIngredientRuleEnum.unchanged: 'unchanged',
  ServingConversionIngredientRuleEnum.round: 'round',
};
