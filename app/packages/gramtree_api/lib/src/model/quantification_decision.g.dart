// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantification_decision.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuantificationDecisionCWProxy {
  QuantificationDecision decision(QuantificationDecisionDecisionEnum decision);

  QuantificationDecision problemId(String problemId);

  QuantificationDecision unit(String? unit);

  QuantificationDecision value(String? value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationDecision(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationDecision(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationDecision call({
    QuantificationDecisionDecisionEnum decision,
    String problemId,
    String? unit,
    String? value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuantificationDecision.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuantificationDecision.copyWith.fieldName(...)`
class _$QuantificationDecisionCWProxyImpl
    implements _$QuantificationDecisionCWProxy {
  const _$QuantificationDecisionCWProxyImpl(this._value);

  final QuantificationDecision _value;

  @override
  QuantificationDecision decision(
    QuantificationDecisionDecisionEnum decision,
  ) => this(decision: decision);

  @override
  QuantificationDecision problemId(String problemId) =>
      this(problemId: problemId);

  @override
  QuantificationDecision unit(String? unit) => this(unit: unit);

  @override
  QuantificationDecision value(String? value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationDecision(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationDecision(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationDecision call({
    Object? decision = const $CopyWithPlaceholder(),
    Object? problemId = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return QuantificationDecision(
      decision: decision == const $CopyWithPlaceholder()
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as QuantificationDecisionDecisionEnum,
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
          : value as String?,
    );
  }
}

extension $QuantificationDecisionCopyWith on QuantificationDecision {
  /// Returns a callable class that can be used as follows: `instanceOfQuantificationDecision.copyWith(...)` or like so:`instanceOfQuantificationDecision.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuantificationDecisionCWProxy get copyWith =>
      _$QuantificationDecisionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuantificationDecision _$QuantificationDecisionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QuantificationDecision', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['decision', 'problem_id']);
  final val = QuantificationDecision(
    decision: $checkedConvert(
      'decision',
      (v) => $enumDecode(_$QuantificationDecisionDecisionEnumEnumMap, v),
    ),
    problemId: $checkedConvert('problem_id', (v) => v as String),
    unit: $checkedConvert('unit', (v) => v as String?),
    value: $checkedConvert('value', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'problemId': 'problem_id'});

Map<String, dynamic> _$QuantificationDecisionToJson(
  QuantificationDecision instance,
) => <String, dynamic>{
  'decision': _$QuantificationDecisionDecisionEnumEnumMap[instance.decision]!,
  'problem_id': instance.problemId,
  'unit': ?instance.unit,
  'value': ?instance.value,
};

const _$QuantificationDecisionDecisionEnumEnumMap = {
  QuantificationDecisionDecisionEnum.accept: 'accept',
  QuantificationDecisionDecisionEnum.modify: 'modify',
  QuantificationDecisionDecisionEnum.ignore: 'ignore',
};
