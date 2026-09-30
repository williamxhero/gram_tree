// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sourced_value.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SourcedValueCWProxy {
  SourcedValue basis(SourceBasis basis);

  SourcedValue originalValue(String? originalValue);

  SourcedValue sourceType(SourcedValueSourceTypeEnum sourceType);

  SourcedValue value(String value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SourcedValue(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SourcedValue(...).copyWith(id: 12, name: "My name")
  /// ````
  SourcedValue call({
    SourceBasis basis,
    String? originalValue,
    SourcedValueSourceTypeEnum sourceType,
    String value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSourcedValue.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSourcedValue.copyWith.fieldName(...)`
class _$SourcedValueCWProxyImpl implements _$SourcedValueCWProxy {
  const _$SourcedValueCWProxyImpl(this._value);

  final SourcedValue _value;

  @override
  SourcedValue basis(SourceBasis basis) => this(basis: basis);

  @override
  SourcedValue originalValue(String? originalValue) =>
      this(originalValue: originalValue);

  @override
  SourcedValue sourceType(SourcedValueSourceTypeEnum sourceType) =>
      this(sourceType: sourceType);

  @override
  SourcedValue value(String value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SourcedValue(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SourcedValue(...).copyWith(id: 12, name: "My name")
  /// ````
  SourcedValue call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? originalValue = const $CopyWithPlaceholder(),
    Object? sourceType = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return SourcedValue(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as SourceBasis,
      originalValue: originalValue == const $CopyWithPlaceholder()
          ? _value.originalValue
          // ignore: cast_nullable_to_non_nullable
          : originalValue as String?,
      sourceType: sourceType == const $CopyWithPlaceholder()
          ? _value.sourceType
          // ignore: cast_nullable_to_non_nullable
          : sourceType as SourcedValueSourceTypeEnum,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $SourcedValueCopyWith on SourcedValue {
  /// Returns a callable class that can be used as follows: `instanceOfSourcedValue.copyWith(...)` or like so:`instanceOfSourcedValue.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SourcedValueCWProxy get copyWith => _$SourcedValueCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourcedValue _$SourcedValueFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SourcedValue',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['basis', 'source_type', 'value']);
        final val = SourcedValue(
          basis: $checkedConvert(
            'basis',
            (v) => SourceBasis.fromJson(v as Map<String, dynamic>),
          ),
          originalValue: $checkedConvert('original_value', (v) => v as String?),
          sourceType: $checkedConvert(
            'source_type',
            (v) => $enumDecode(_$SourcedValueSourceTypeEnumEnumMap, v),
          ),
          value: $checkedConvert('value', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'originalValue': 'original_value',
        'sourceType': 'source_type',
      },
    );

Map<String, dynamic> _$SourcedValueToJson(SourcedValue instance) =>
    <String, dynamic>{
      'basis': instance.basis.toJson(),
      'original_value': ?instance.originalValue,
      'source_type': _$SourcedValueSourceTypeEnumEnumMap[instance.sourceType]!,
      'value': instance.value,
    };

const _$SourcedValueSourceTypeEnumEnumMap = {
  SourcedValueSourceTypeEnum.authorFilled: 'author_filled',
  SourcedValueSourceTypeEnum.tasteAdjusted: 'taste_adjusted',
  SourcedValueSourceTypeEnum.scenarioAdjusted: 'scenario_adjusted',
  SourcedValueSourceTypeEnum.aiEstimated: 'ai_estimated',
  SourcedValueSourceTypeEnum.verified: 'verified',
};
