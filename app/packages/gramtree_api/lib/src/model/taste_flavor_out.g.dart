// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_flavor_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteFlavorOutCWProxy {
  TasteFlavorOut coefficient(num coefficient);

  TasteFlavorOut confidence(TasteFlavorOutConfidenceEnum confidence);

  TasteFlavorOut confidenceText(String confidenceText);

  TasteFlavorOut label(String label);

  TasteFlavorOut level(int level);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteFlavorOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteFlavorOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteFlavorOut call({
    num coefficient,
    TasteFlavorOutConfidenceEnum confidence,
    String confidenceText,
    String label,
    int level,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteFlavorOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteFlavorOut.copyWith.fieldName(...)`
class _$TasteFlavorOutCWProxyImpl implements _$TasteFlavorOutCWProxy {
  const _$TasteFlavorOutCWProxyImpl(this._value);

  final TasteFlavorOut _value;

  @override
  TasteFlavorOut coefficient(num coefficient) => this(coefficient: coefficient);

  @override
  TasteFlavorOut confidence(TasteFlavorOutConfidenceEnum confidence) =>
      this(confidence: confidence);

  @override
  TasteFlavorOut confidenceText(String confidenceText) =>
      this(confidenceText: confidenceText);

  @override
  TasteFlavorOut label(String label) => this(label: label);

  @override
  TasteFlavorOut level(int level) => this(level: level);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteFlavorOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteFlavorOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteFlavorOut call({
    Object? coefficient = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? confidenceText = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? level = const $CopyWithPlaceholder(),
  }) {
    return TasteFlavorOut(
      coefficient: coefficient == const $CopyWithPlaceholder()
          ? _value.coefficient
          // ignore: cast_nullable_to_non_nullable
          : coefficient as num,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as TasteFlavorOutConfidenceEnum,
      confidenceText: confidenceText == const $CopyWithPlaceholder()
          ? _value.confidenceText
          // ignore: cast_nullable_to_non_nullable
          : confidenceText as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      level: level == const $CopyWithPlaceholder()
          ? _value.level
          // ignore: cast_nullable_to_non_nullable
          : level as int,
    );
  }
}

extension $TasteFlavorOutCopyWith on TasteFlavorOut {
  /// Returns a callable class that can be used as follows: `instanceOfTasteFlavorOut.copyWith(...)` or like so:`instanceOfTasteFlavorOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteFlavorOutCWProxy get copyWith => _$TasteFlavorOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteFlavorOut _$TasteFlavorOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TasteFlavorOut', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'coefficient',
          'confidence',
          'confidence_text',
          'label',
          'level',
        ],
      );
      final val = TasteFlavorOut(
        coefficient: $checkedConvert('coefficient', (v) => v as num),
        confidence: $checkedConvert(
          'confidence',
          (v) => $enumDecode(_$TasteFlavorOutConfidenceEnumEnumMap, v),
        ),
        confidenceText: $checkedConvert('confidence_text', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        level: $checkedConvert('level', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'confidenceText': 'confidence_text'});

Map<String, dynamic> _$TasteFlavorOutToJson(TasteFlavorOut instance) =>
    <String, dynamic>{
      'coefficient': instance.coefficient,
      'confidence': _$TasteFlavorOutConfidenceEnumEnumMap[instance.confidence]!,
      'confidence_text': instance.confidenceText,
      'label': instance.label,
      'level': instance.level,
    };

const _$TasteFlavorOutConfidenceEnumEnumMap = {
  TasteFlavorOutConfidenceEnum.low: 'low',
  TasteFlavorOutConfidenceEnum.high: 'high',
};
