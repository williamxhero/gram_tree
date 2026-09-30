// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TextAttributeCWProxy {
  TextAttribute estimate(bool estimate);

  TextAttribute source_(String source_);

  TextAttribute status(AttributeStatus status);

  TextAttribute value(String value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TextAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TextAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  TextAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    String value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTextAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTextAttribute.copyWith.fieldName(...)`
class _$TextAttributeCWProxyImpl implements _$TextAttributeCWProxy {
  const _$TextAttributeCWProxyImpl(this._value);

  final TextAttribute _value;

  @override
  TextAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  TextAttribute source_(String source_) => this(source_: source_);

  @override
  TextAttribute status(AttributeStatus status) => this(status: status);

  @override
  TextAttribute value(String value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TextAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TextAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  TextAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return TextAttribute(
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
          : value as String,
    );
  }
}

extension $TextAttributeCopyWith on TextAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfTextAttribute.copyWith(...)` or like so:`instanceOfTextAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TextAttributeCWProxy get copyWith => _$TextAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAttribute _$TextAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TextAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = TextAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$TextAttributeToJson(TextAttribute instance) =>
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
