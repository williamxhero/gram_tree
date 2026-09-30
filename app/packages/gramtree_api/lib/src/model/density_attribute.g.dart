// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'density_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DensityAttributeCWProxy {
  DensityAttribute estimate(bool estimate);

  DensityAttribute source_(String source_);

  DensityAttribute status(AttributeStatus status);

  DensityAttribute value(num value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DensityAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DensityAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  DensityAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    num value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDensityAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDensityAttribute.copyWith.fieldName(...)`
class _$DensityAttributeCWProxyImpl implements _$DensityAttributeCWProxy {
  const _$DensityAttributeCWProxyImpl(this._value);

  final DensityAttribute _value;

  @override
  DensityAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  DensityAttribute source_(String source_) => this(source_: source_);

  @override
  DensityAttribute status(AttributeStatus status) => this(status: status);

  @override
  DensityAttribute value(num value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DensityAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DensityAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  DensityAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return DensityAttribute(
      estimate: estimate == const $CopyWithPlaceholder()
          ? _value.estimate
          // ignore: cast_nullable_to_non_nullable
          : estimate as bool,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AttributeStatus,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num,
    );
  }
}

extension $DensityAttributeCopyWith on DensityAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfDensityAttribute.copyWith(...)` or like so:`instanceOfDensityAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DensityAttributeCWProxy get copyWith => _$DensityAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DensityAttribute _$DensityAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DensityAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = DensityAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as num),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$DensityAttributeToJson(DensityAttribute instance) =>
    <String, dynamic>{
      'estimate': instance.estimate,
      'source': instance.source_,
      'status': _$AttributeStatusEnumMap[instance.status]!,
      'value': instance.value,
    };

const _$AttributeStatusEnumMap = {
  AttributeStatus.aiDraft: 'ai_draft',
  AttributeStatus.verified: 'verified',
};
