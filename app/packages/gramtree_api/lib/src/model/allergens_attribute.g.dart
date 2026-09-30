// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergens_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AllergensAttributeCWProxy {
  AllergensAttribute estimate(bool estimate);

  AllergensAttribute source_(String source_);

  AllergensAttribute status(AttributeStatus status);

  AllergensAttribute value(List<String> value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergensAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergensAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergensAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    List<String> value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAllergensAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAllergensAttribute.copyWith.fieldName(...)`
class _$AllergensAttributeCWProxyImpl implements _$AllergensAttributeCWProxy {
  const _$AllergensAttributeCWProxyImpl(this._value);

  final AllergensAttribute _value;

  @override
  AllergensAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  AllergensAttribute source_(String source_) => this(source_: source_);

  @override
  AllergensAttribute status(AttributeStatus status) => this(status: status);

  @override
  AllergensAttribute value(List<String> value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergensAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergensAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergensAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return AllergensAttribute(
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
          : value as List<String>,
    );
  }
}

extension $AllergensAttributeCopyWith on AllergensAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfAllergensAttribute.copyWith(...)` or like so:`instanceOfAllergensAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AllergensAttributeCWProxy get copyWith =>
      _$AllergensAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergensAttribute _$AllergensAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AllergensAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = AllergensAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert(
          'value',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$AllergensAttributeToJson(AllergensAttribute instance) =>
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
