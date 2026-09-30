// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_basis.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SourceBasisCWProxy {
  SourceBasis citation(String? citation);

  SourceBasis reasonCode(String reasonCode);

  SourceBasis text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SourceBasis(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SourceBasis(...).copyWith(id: 12, name: "My name")
  /// ````
  SourceBasis call({String? citation, String reasonCode, String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSourceBasis.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSourceBasis.copyWith.fieldName(...)`
class _$SourceBasisCWProxyImpl implements _$SourceBasisCWProxy {
  const _$SourceBasisCWProxyImpl(this._value);

  final SourceBasis _value;

  @override
  SourceBasis citation(String? citation) => this(citation: citation);

  @override
  SourceBasis reasonCode(String reasonCode) => this(reasonCode: reasonCode);

  @override
  SourceBasis text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SourceBasis(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SourceBasis(...).copyWith(id: 12, name: "My name")
  /// ````
  SourceBasis call({
    Object? citation = const $CopyWithPlaceholder(),
    Object? reasonCode = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return SourceBasis(
      citation: citation == const $CopyWithPlaceholder()
          ? _value.citation
          // ignore: cast_nullable_to_non_nullable
          : citation as String?,
      reasonCode: reasonCode == const $CopyWithPlaceholder()
          ? _value.reasonCode
          // ignore: cast_nullable_to_non_nullable
          : reasonCode as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $SourceBasisCopyWith on SourceBasis {
  /// Returns a callable class that can be used as follows: `instanceOfSourceBasis.copyWith(...)` or like so:`instanceOfSourceBasis.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SourceBasisCWProxy get copyWith => _$SourceBasisCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceBasis _$SourceBasisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SourceBasis', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason_code', 'text']);
      final val = SourceBasis(
        citation: $checkedConvert('citation', (v) => v as String?),
        reasonCode: $checkedConvert('reason_code', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'reasonCode': 'reason_code'});

Map<String, dynamic> _$SourceBasisToJson(SourceBasis instance) =>
    <String, dynamic>{
      'citation': ?instance.citation,
      'reason_code': instance.reasonCode,
      'text': instance.text,
    };
