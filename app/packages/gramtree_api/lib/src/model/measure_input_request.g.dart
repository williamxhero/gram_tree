// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_input_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeasureInputRequestCWProxy {
  MeasureInputRequest acceptEstimate(bool? acceptEstimate);

  MeasureInputRequest baseUnit(MeasureInputRequestBaseUnitEnum baseUnit);

  MeasureInputRequest ingredientId(String? ingredientId);

  MeasureInputRequest measureId(String measureId);

  MeasureInputRequest quantity(num quantity);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureInputRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureInputRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureInputRequest call({
    bool? acceptEstimate,
    MeasureInputRequestBaseUnitEnum baseUnit,
    String? ingredientId,
    String measureId,
    num quantity,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMeasureInputRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMeasureInputRequest.copyWith.fieldName(...)`
class _$MeasureInputRequestCWProxyImpl implements _$MeasureInputRequestCWProxy {
  const _$MeasureInputRequestCWProxyImpl(this._value);

  final MeasureInputRequest _value;

  @override
  MeasureInputRequest acceptEstimate(bool? acceptEstimate) =>
      this(acceptEstimate: acceptEstimate);

  @override
  MeasureInputRequest baseUnit(MeasureInputRequestBaseUnitEnum baseUnit) =>
      this(baseUnit: baseUnit);

  @override
  MeasureInputRequest ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  MeasureInputRequest measureId(String measureId) => this(measureId: measureId);

  @override
  MeasureInputRequest quantity(num quantity) => this(quantity: quantity);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureInputRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureInputRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureInputRequest call({
    Object? acceptEstimate = const $CopyWithPlaceholder(),
    Object? baseUnit = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? measureId = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
  }) {
    return MeasureInputRequest(
      acceptEstimate: acceptEstimate == const $CopyWithPlaceholder()
          ? _value.acceptEstimate
          // ignore: cast_nullable_to_non_nullable
          : acceptEstimate as bool?,
      baseUnit: baseUnit == const $CopyWithPlaceholder()
          ? _value.baseUnit
          // ignore: cast_nullable_to_non_nullable
          : baseUnit as MeasureInputRequestBaseUnitEnum,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
      measureId: measureId == const $CopyWithPlaceholder()
          ? _value.measureId
          // ignore: cast_nullable_to_non_nullable
          : measureId as String,
      quantity: quantity == const $CopyWithPlaceholder()
          ? _value.quantity
          // ignore: cast_nullable_to_non_nullable
          : quantity as num,
    );
  }
}

extension $MeasureInputRequestCopyWith on MeasureInputRequest {
  /// Returns a callable class that can be used as follows: `instanceOfMeasureInputRequest.copyWith(...)` or like so:`instanceOfMeasureInputRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeasureInputRequestCWProxy get copyWith =>
      _$MeasureInputRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeasureInputRequest _$MeasureInputRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MeasureInputRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['base_unit', 'measure_id', 'quantity'],
        );
        final val = MeasureInputRequest(
          acceptEstimate: $checkedConvert(
            'accept_estimate',
            (v) => v as bool? ?? false,
          ),
          baseUnit: $checkedConvert(
            'base_unit',
            (v) => $enumDecode(_$MeasureInputRequestBaseUnitEnumEnumMap, v),
          ),
          ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
          measureId: $checkedConvert('measure_id', (v) => v as String),
          quantity: $checkedConvert('quantity', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'acceptEstimate': 'accept_estimate',
        'baseUnit': 'base_unit',
        'ingredientId': 'ingredient_id',
        'measureId': 'measure_id',
      },
    );

Map<String, dynamic> _$MeasureInputRequestToJson(
  MeasureInputRequest instance,
) => <String, dynamic>{
  'accept_estimate': ?instance.acceptEstimate,
  'base_unit': _$MeasureInputRequestBaseUnitEnumEnumMap[instance.baseUnit]!,
  'ingredient_id': ?instance.ingredientId,
  'measure_id': instance.measureId,
  'quantity': instance.quantity,
};

const _$MeasureInputRequestBaseUnitEnumEnumMap = {
  MeasureInputRequestBaseUnitEnum.g: 'g',
  MeasureInputRequestBaseUnitEnum.ml: 'ml',
};
