// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StorageAttributeCWProxy {
  StorageAttribute estimate(bool estimate);

  StorageAttribute source_(String source_);

  StorageAttribute status(AttributeStatus status);

  StorageAttribute value(List<StorageAdvice> value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StorageAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StorageAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  StorageAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    List<StorageAdvice> value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStorageAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStorageAttribute.copyWith.fieldName(...)`
class _$StorageAttributeCWProxyImpl implements _$StorageAttributeCWProxy {
  const _$StorageAttributeCWProxyImpl(this._value);

  final StorageAttribute _value;

  @override
  StorageAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  StorageAttribute source_(String source_) => this(source_: source_);

  @override
  StorageAttribute status(AttributeStatus status) => this(status: status);

  @override
  StorageAttribute value(List<StorageAdvice> value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StorageAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StorageAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  StorageAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return StorageAttribute(
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
          : value as List<StorageAdvice>,
    );
  }
}

extension $StorageAttributeCopyWith on StorageAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfStorageAttribute.copyWith(...)` or like so:`instanceOfStorageAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StorageAttributeCWProxy get copyWith => _$StorageAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageAttribute _$StorageAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StorageAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = StorageAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert(
          'value',
          (v) => (v as List<dynamic>)
              .map((e) => StorageAdvice.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$StorageAttributeToJson(StorageAttribute instance) =>
    <String, dynamic>{
      'estimate': instance.estimate,
      'source': instance.source_,
      'status': _$AttributeStatusEnumMap[instance.status]!,
      'value': instance.value.map((e) => e.toJson()).toList(),
    };

const _$AttributeStatusEnumMap = {
  AttributeStatus.aiDraft: 'ai_draft',
  AttributeStatus.verified: 'verified',
};
