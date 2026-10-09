// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_input_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeasureInputOutCWProxy {
  MeasureInputOut baseQuantity(num? baseQuantity);

  MeasureInputOut baseUnit(MeasureInputOutBaseUnitEnum baseUnit);

  MeasureInputOut basis(String basis);

  MeasureInputOut measureInputToken(String? measureInputToken);

  MeasureInputOut original(String original);

  MeasureInputOut quantitySource(ValueSource? quantitySource);

  MeasureInputOut status(MeasureInputOutStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureInputOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureInputOut(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureInputOut call({
    num? baseQuantity,
    MeasureInputOutBaseUnitEnum baseUnit,
    String basis,
    String? measureInputToken,
    String original,
    ValueSource? quantitySource,
    MeasureInputOutStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMeasureInputOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMeasureInputOut.copyWith.fieldName(...)`
class _$MeasureInputOutCWProxyImpl implements _$MeasureInputOutCWProxy {
  const _$MeasureInputOutCWProxyImpl(this._value);

  final MeasureInputOut _value;

  @override
  MeasureInputOut baseQuantity(num? baseQuantity) =>
      this(baseQuantity: baseQuantity);

  @override
  MeasureInputOut baseUnit(MeasureInputOutBaseUnitEnum baseUnit) =>
      this(baseUnit: baseUnit);

  @override
  MeasureInputOut basis(String basis) => this(basis: basis);

  @override
  MeasureInputOut measureInputToken(String? measureInputToken) =>
      this(measureInputToken: measureInputToken);

  @override
  MeasureInputOut original(String original) => this(original: original);

  @override
  MeasureInputOut quantitySource(ValueSource? quantitySource) =>
      this(quantitySource: quantitySource);

  @override
  MeasureInputOut status(MeasureInputOutStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureInputOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureInputOut(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureInputOut call({
    Object? baseQuantity = const $CopyWithPlaceholder(),
    Object? baseUnit = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? measureInputToken = const $CopyWithPlaceholder(),
    Object? original = const $CopyWithPlaceholder(),
    Object? quantitySource = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return MeasureInputOut(
      baseQuantity: baseQuantity == const $CopyWithPlaceholder()
          ? _value.baseQuantity
          // ignore: cast_nullable_to_non_nullable
          : baseQuantity as num?,
      baseUnit: baseUnit == const $CopyWithPlaceholder()
          ? _value.baseUnit
          // ignore: cast_nullable_to_non_nullable
          : baseUnit as MeasureInputOutBaseUnitEnum,
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      measureInputToken: measureInputToken == const $CopyWithPlaceholder()
          ? _value.measureInputToken
          // ignore: cast_nullable_to_non_nullable
          : measureInputToken as String?,
      original: original == const $CopyWithPlaceholder()
          ? _value.original
          // ignore: cast_nullable_to_non_nullable
          : original as String,
      quantitySource: quantitySource == const $CopyWithPlaceholder()
          ? _value.quantitySource
          // ignore: cast_nullable_to_non_nullable
          : quantitySource as ValueSource?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as MeasureInputOutStatusEnum,
    );
  }
}

extension $MeasureInputOutCopyWith on MeasureInputOut {
  /// Returns a callable class that can be used as follows: `instanceOfMeasureInputOut.copyWith(...)` or like so:`instanceOfMeasureInputOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeasureInputOutCWProxy get copyWith => _$MeasureInputOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeasureInputOut _$MeasureInputOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MeasureInputOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['base_unit', 'basis', 'original', 'status'],
        );
        final val = MeasureInputOut(
          baseQuantity: $checkedConvert('base_quantity', (v) => v as num?),
          baseUnit: $checkedConvert(
            'base_unit',
            (v) => $enumDecode(_$MeasureInputOutBaseUnitEnumEnumMap, v),
          ),
          basis: $checkedConvert('basis', (v) => v as String),
          measureInputToken: $checkedConvert(
            'measure_input_token',
            (v) => v as String?,
          ),
          original: $checkedConvert('original', (v) => v as String),
          quantitySource: $checkedConvert(
            'quantity_source',
            (v) => v == null
                ? null
                : ValueSource.fromJson(v as Map<String, dynamic>),
          ),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$MeasureInputOutStatusEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'baseQuantity': 'base_quantity',
        'baseUnit': 'base_unit',
        'measureInputToken': 'measure_input_token',
        'quantitySource': 'quantity_source',
      },
    );

Map<String, dynamic> _$MeasureInputOutToJson(MeasureInputOut instance) =>
    <String, dynamic>{
      'base_quantity': ?instance.baseQuantity,
      'base_unit': _$MeasureInputOutBaseUnitEnumEnumMap[instance.baseUnit]!,
      'basis': instance.basis,
      'measure_input_token': ?instance.measureInputToken,
      'original': instance.original,
      'quantity_source': ?instance.quantitySource?.toJson(),
      'status': _$MeasureInputOutStatusEnumEnumMap[instance.status]!,
    };

const _$MeasureInputOutBaseUnitEnumEnumMap = {
  MeasureInputOutBaseUnitEnum.g: 'g',
  MeasureInputOutBaseUnitEnum.ml: 'ml',
};

const _$MeasureInputOutStatusEnumEnumMap = {
  MeasureInputOutStatusEnum.ready: 'ready',
  MeasureInputOutStatusEnum.noDensity: 'no_density',
  MeasureInputOutStatusEnum.estimateConfirmationRequired:
      'estimate_confirmation_required',
};
