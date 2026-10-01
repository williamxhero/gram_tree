// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_display_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeasureDisplayRequestCWProxy {
  MeasureDisplayRequest baseQuantity(num baseQuantity);

  MeasureDisplayRequest baseUnit(MeasureDisplayRequestBaseUnitEnum baseUnit);

  MeasureDisplayRequest density(num? density);

  MeasureDisplayRequest measureId(String? measureId);

  MeasureDisplayRequest mode(MeasureDisplayRequestModeEnum mode);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureDisplayRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureDisplayRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureDisplayRequest call({
    num baseQuantity,
    MeasureDisplayRequestBaseUnitEnum baseUnit,
    num? density,
    String? measureId,
    MeasureDisplayRequestModeEnum mode,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMeasureDisplayRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMeasureDisplayRequest.copyWith.fieldName(...)`
class _$MeasureDisplayRequestCWProxyImpl
    implements _$MeasureDisplayRequestCWProxy {
  const _$MeasureDisplayRequestCWProxyImpl(this._value);

  final MeasureDisplayRequest _value;

  @override
  MeasureDisplayRequest baseQuantity(num baseQuantity) =>
      this(baseQuantity: baseQuantity);

  @override
  MeasureDisplayRequest baseUnit(MeasureDisplayRequestBaseUnitEnum baseUnit) =>
      this(baseUnit: baseUnit);

  @override
  MeasureDisplayRequest density(num? density) => this(density: density);

  @override
  MeasureDisplayRequest measureId(String? measureId) =>
      this(measureId: measureId);

  @override
  MeasureDisplayRequest mode(MeasureDisplayRequestModeEnum mode) =>
      this(mode: mode);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureDisplayRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureDisplayRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureDisplayRequest call({
    Object? baseQuantity = const $CopyWithPlaceholder(),
    Object? baseUnit = const $CopyWithPlaceholder(),
    Object? density = const $CopyWithPlaceholder(),
    Object? measureId = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
  }) {
    return MeasureDisplayRequest(
      baseQuantity: baseQuantity == const $CopyWithPlaceholder()
          ? _value.baseQuantity
          // ignore: cast_nullable_to_non_nullable
          : baseQuantity as num,
      baseUnit: baseUnit == const $CopyWithPlaceholder()
          ? _value.baseUnit
          // ignore: cast_nullable_to_non_nullable
          : baseUnit as MeasureDisplayRequestBaseUnitEnum,
      density: density == const $CopyWithPlaceholder()
          ? _value.density
          // ignore: cast_nullable_to_non_nullable
          : density as num?,
      measureId: measureId == const $CopyWithPlaceholder()
          ? _value.measureId
          // ignore: cast_nullable_to_non_nullable
          : measureId as String?,
      mode: mode == const $CopyWithPlaceholder()
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as MeasureDisplayRequestModeEnum,
    );
  }
}

extension $MeasureDisplayRequestCopyWith on MeasureDisplayRequest {
  /// Returns a callable class that can be used as follows: `instanceOfMeasureDisplayRequest.copyWith(...)` or like so:`instanceOfMeasureDisplayRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeasureDisplayRequestCWProxy get copyWith =>
      _$MeasureDisplayRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeasureDisplayRequest _$MeasureDisplayRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MeasureDisplayRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['base_quantity', 'base_unit', 'mode'],
    );
    final val = MeasureDisplayRequest(
      baseQuantity: $checkedConvert('base_quantity', (v) => v as num),
      baseUnit: $checkedConvert(
        'base_unit',
        (v) => $enumDecode(_$MeasureDisplayRequestBaseUnitEnumEnumMap, v),
      ),
      density: $checkedConvert('density', (v) => v as num?),
      measureId: $checkedConvert('measure_id', (v) => v as String?),
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$MeasureDisplayRequestModeEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseQuantity': 'base_quantity',
    'baseUnit': 'base_unit',
    'measureId': 'measure_id',
  },
);

Map<String, dynamic> _$MeasureDisplayRequestToJson(
  MeasureDisplayRequest instance,
) => <String, dynamic>{
  'base_quantity': instance.baseQuantity,
  'base_unit': _$MeasureDisplayRequestBaseUnitEnumEnumMap[instance.baseUnit]!,
  'density': ?instance.density,
  'measure_id': ?instance.measureId,
  'mode': _$MeasureDisplayRequestModeEnumEnumMap[instance.mode]!,
};

const _$MeasureDisplayRequestBaseUnitEnumEnumMap = {
  MeasureDisplayRequestBaseUnitEnum.g: 'g',
  MeasureDisplayRequestBaseUnitEnum.ml: 'ml',
};

const _$MeasureDisplayRequestModeEnumEnumMap = {
  MeasureDisplayRequestModeEnum.base_: 'base',
  MeasureDisplayRequestModeEnum.standard: 'standard',
  MeasureDisplayRequestModeEnum.home: 'home',
};
