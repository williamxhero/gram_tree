// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bool_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BoolAttributeCWProxy {
  BoolAttribute estimate(bool estimate);

  BoolAttribute source_(String source_);

  BoolAttribute status(AttributeStatus status);

  BoolAttribute value(bool value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BoolAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BoolAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  BoolAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    bool value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBoolAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBoolAttribute.copyWith.fieldName(...)`
class _$BoolAttributeCWProxyImpl implements _$BoolAttributeCWProxy {
  const _$BoolAttributeCWProxyImpl(this._value);

  final BoolAttribute _value;

  @override
  BoolAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  BoolAttribute source_(String source_) => this(source_: source_);

  @override
  BoolAttribute status(AttributeStatus status) => this(status: status);

  @override
  BoolAttribute value(bool value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BoolAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BoolAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  BoolAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return BoolAttribute(
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
          : value as bool,
    );
  }
}

extension $BoolAttributeCopyWith on BoolAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfBoolAttribute.copyWith(...)` or like so:`instanceOfBoolAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BoolAttributeCWProxy get copyWith => _$BoolAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoolAttribute _$BoolAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BoolAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = BoolAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$BoolAttributeToJson(BoolAttribute instance) =>
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
