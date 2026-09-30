// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flavor_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FlavorAttributeCWProxy {
  FlavorAttribute estimate(bool estimate);

  FlavorAttribute source_(String source_);

  FlavorAttribute status(AttributeStatus status);

  FlavorAttribute value(FlavorProfile value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FlavorAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FlavorAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  FlavorAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    FlavorProfile value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFlavorAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFlavorAttribute.copyWith.fieldName(...)`
class _$FlavorAttributeCWProxyImpl implements _$FlavorAttributeCWProxy {
  const _$FlavorAttributeCWProxyImpl(this._value);

  final FlavorAttribute _value;

  @override
  FlavorAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  FlavorAttribute source_(String source_) => this(source_: source_);

  @override
  FlavorAttribute status(AttributeStatus status) => this(status: status);

  @override
  FlavorAttribute value(FlavorProfile value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FlavorAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FlavorAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  FlavorAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return FlavorAttribute(
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
          : value as FlavorProfile,
    );
  }
}

extension $FlavorAttributeCopyWith on FlavorAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfFlavorAttribute.copyWith(...)` or like so:`instanceOfFlavorAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FlavorAttributeCWProxy get copyWith => _$FlavorAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlavorAttribute _$FlavorAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FlavorAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = FlavorAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert(
          'value',
          (v) => FlavorProfile.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$FlavorAttributeToJson(FlavorAttribute instance) =>
    <String, dynamic>{
      'estimate': instance.estimate,
      'source': instance.source_,
      'status': _$AttributeStatusEnumMap[instance.status]!,
      'value': instance.value.toJson(),
    };

const _$AttributeStatusEnumMap = {
  AttributeStatus.aiDraft: 'ai_draft',
  AttributeStatus.verified: 'verified',
};
