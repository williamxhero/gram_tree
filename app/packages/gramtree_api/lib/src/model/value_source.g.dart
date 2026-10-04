// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'value_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ValueSourceCWProxy {
  ValueSource basis(String? basis);

  ValueSource confidence(num? confidence);

  ValueSource original(String? original);

  ValueSource source_(ValueSourceSource_Enum source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ValueSource(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ValueSource(...).copyWith(id: 12, name: "My name")
  /// ````
  ValueSource call({
    String? basis,
    num? confidence,
    String? original,
    ValueSourceSource_Enum source_,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfValueSource.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfValueSource.copyWith.fieldName(...)`
class _$ValueSourceCWProxyImpl implements _$ValueSourceCWProxy {
  const _$ValueSourceCWProxyImpl(this._value);

  final ValueSource _value;

  @override
  ValueSource basis(String? basis) => this(basis: basis);

  @override
  ValueSource confidence(num? confidence) => this(confidence: confidence);

  @override
  ValueSource original(String? original) => this(original: original);

  @override
  ValueSource source_(ValueSourceSource_Enum source_) => this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ValueSource(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ValueSource(...).copyWith(id: 12, name: "My name")
  /// ````
  ValueSource call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? original = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return ValueSource(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String?,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as num?,
      original: original == const $CopyWithPlaceholder()
          ? _value.original
          // ignore: cast_nullable_to_non_nullable
          : original as String?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as ValueSourceSource_Enum,
    );
  }
}

extension $ValueSourceCopyWith on ValueSource {
  /// Returns a callable class that can be used as follows: `instanceOfValueSource.copyWith(...)` or like so:`instanceOfValueSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ValueSourceCWProxy get copyWith => _$ValueSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValueSource _$ValueSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ValueSource', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['source']);
      final val = ValueSource(
        basis: $checkedConvert('basis', (v) => v as String?),
        confidence: $checkedConvert('confidence', (v) => v as num?),
        original: $checkedConvert('original', (v) => v as String?),
        source_: $checkedConvert(
          'source',
          (v) => $enumDecode(_$ValueSourceSource_EnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$ValueSourceToJson(ValueSource instance) =>
    <String, dynamic>{
      'basis': ?instance.basis,
      'confidence': ?instance.confidence,
      'original': ?instance.original,
      'source': _$ValueSourceSource_EnumEnumMap[instance.source_]!,
    };

const _$ValueSourceSource_EnumEnumMap = {
  ValueSourceSource_Enum.authorFilled: 'author_filled',
  ValueSourceSource_Enum.scenarioAdjusted: 'scenario_adjusted',
  ValueSourceSource_Enum.aiEstimated: 'ai_estimated',
  ValueSourceSource_Enum.verified: 'verified',
};
