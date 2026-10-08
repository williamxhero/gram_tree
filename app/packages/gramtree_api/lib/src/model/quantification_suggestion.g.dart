// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantification_suggestion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuantificationSuggestionCWProxy {
  QuantificationSuggestion adjustment(String? adjustment);

  QuantificationSuggestion baseline(String? baseline);

  QuantificationSuggestion basis(String basis);

  QuantificationSuggestion confidence(
    QuantificationSuggestionConfidenceEnum confidence,
  );

  QuantificationSuggestion problemId(String problemId);

  QuantificationSuggestion unit(String? unit);

  QuantificationSuggestion value(String value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationSuggestion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationSuggestion(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationSuggestion call({
    String? adjustment,
    String? baseline,
    String basis,
    QuantificationSuggestionConfidenceEnum confidence,
    String problemId,
    String? unit,
    String value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuantificationSuggestion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuantificationSuggestion.copyWith.fieldName(...)`
class _$QuantificationSuggestionCWProxyImpl
    implements _$QuantificationSuggestionCWProxy {
  const _$QuantificationSuggestionCWProxyImpl(this._value);

  final QuantificationSuggestion _value;

  @override
  QuantificationSuggestion adjustment(String? adjustment) =>
      this(adjustment: adjustment);

  @override
  QuantificationSuggestion baseline(String? baseline) =>
      this(baseline: baseline);

  @override
  QuantificationSuggestion basis(String basis) => this(basis: basis);

  @override
  QuantificationSuggestion confidence(
    QuantificationSuggestionConfidenceEnum confidence,
  ) => this(confidence: confidence);

  @override
  QuantificationSuggestion problemId(String problemId) =>
      this(problemId: problemId);

  @override
  QuantificationSuggestion unit(String? unit) => this(unit: unit);

  @override
  QuantificationSuggestion value(String value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationSuggestion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationSuggestion(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationSuggestion call({
    Object? adjustment = const $CopyWithPlaceholder(),
    Object? baseline = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? problemId = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return QuantificationSuggestion(
      adjustment: adjustment == const $CopyWithPlaceholder()
          ? _value.adjustment
          // ignore: cast_nullable_to_non_nullable
          : adjustment as String?,
      baseline: baseline == const $CopyWithPlaceholder()
          ? _value.baseline
          // ignore: cast_nullable_to_non_nullable
          : baseline as String?,
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as QuantificationSuggestionConfidenceEnum,
      problemId: problemId == const $CopyWithPlaceholder()
          ? _value.problemId
          // ignore: cast_nullable_to_non_nullable
          : problemId as String,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String?,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $QuantificationSuggestionCopyWith on QuantificationSuggestion {
  /// Returns a callable class that can be used as follows: `instanceOfQuantificationSuggestion.copyWith(...)` or like so:`instanceOfQuantificationSuggestion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuantificationSuggestionCWProxy get copyWith =>
      _$QuantificationSuggestionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuantificationSuggestion _$QuantificationSuggestionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QuantificationSuggestion', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['basis', 'confidence', 'problem_id', 'value'],
  );
  final val = QuantificationSuggestion(
    adjustment: $checkedConvert('adjustment', (v) => v as String?),
    baseline: $checkedConvert('baseline', (v) => v as String?),
    basis: $checkedConvert('basis', (v) => v as String),
    confidence: $checkedConvert(
      'confidence',
      (v) => $enumDecode(_$QuantificationSuggestionConfidenceEnumEnumMap, v),
    ),
    problemId: $checkedConvert('problem_id', (v) => v as String),
    unit: $checkedConvert('unit', (v) => v as String?),
    value: $checkedConvert('value', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'problemId': 'problem_id'});

Map<String, dynamic> _$QuantificationSuggestionToJson(
  QuantificationSuggestion instance,
) => <String, dynamic>{
  'adjustment': ?instance.adjustment,
  'baseline': ?instance.baseline,
  'basis': instance.basis,
  'confidence':
      _$QuantificationSuggestionConfidenceEnumEnumMap[instance.confidence]!,
  'problem_id': instance.problemId,
  'unit': ?instance.unit,
  'value': instance.value,
};

const _$QuantificationSuggestionConfidenceEnumEnumMap = {
  QuantificationSuggestionConfidenceEnum.high: 'high',
  QuantificationSuggestionConfidenceEnum.medium: 'medium',
  QuantificationSuggestionConfidenceEnum.low: 'low',
};
