// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'count_units_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CountUnitsAttributeCWProxy {
  CountUnitsAttribute estimate(bool estimate);

  CountUnitsAttribute source_(String source_);

  CountUnitsAttribute status(AttributeStatus status);

  CountUnitsAttribute value(List<CountUnit> value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CountUnitsAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CountUnitsAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  CountUnitsAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    List<CountUnit> value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCountUnitsAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCountUnitsAttribute.copyWith.fieldName(...)`
class _$CountUnitsAttributeCWProxyImpl implements _$CountUnitsAttributeCWProxy {
  const _$CountUnitsAttributeCWProxyImpl(this._value);

  final CountUnitsAttribute _value;

  @override
  CountUnitsAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  CountUnitsAttribute source_(String source_) => this(source_: source_);

  @override
  CountUnitsAttribute status(AttributeStatus status) => this(status: status);

  @override
  CountUnitsAttribute value(List<CountUnit> value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CountUnitsAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CountUnitsAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  CountUnitsAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return CountUnitsAttribute(
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
          : value as List<CountUnit>,
    );
  }
}

extension $CountUnitsAttributeCopyWith on CountUnitsAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfCountUnitsAttribute.copyWith(...)` or like so:`instanceOfCountUnitsAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CountUnitsAttributeCWProxy get copyWith =>
      _$CountUnitsAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountUnitsAttribute _$CountUnitsAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CountUnitsAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = CountUnitsAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert(
          'value',
          (v) => (v as List<dynamic>)
              .map((e) => CountUnit.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$CountUnitsAttributeToJson(
  CountUnitsAttribute instance,
) => <String, dynamic>{
  'estimate': instance.estimate,
  'source': instance.source_,
  'status': _$AttributeStatusEnumMap[instance.status]!,
  'value': instance.value.map((e) => e.toJson()).toList(),
};

const _$AttributeStatusEnumMap = {
  AttributeStatus.aiDraft: 'ai_draft',
  AttributeStatus.verified: 'verified',
};
