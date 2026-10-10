// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_decision.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationDecisionCWProxy {
  ModificationDecision after(Object? after);

  ModificationDecision decision(ModificationDecisionDecisionEnum decision);

  ModificationDecision operationId(String operationId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationDecision(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationDecision(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationDecision call({
    Object? after,
    ModificationDecisionDecisionEnum decision,
    String operationId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationDecision.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationDecision.copyWith.fieldName(...)`
class _$ModificationDecisionCWProxyImpl
    implements _$ModificationDecisionCWProxy {
  const _$ModificationDecisionCWProxyImpl(this._value);

  final ModificationDecision _value;

  @override
  ModificationDecision after(Object? after) => this(after: after);

  @override
  ModificationDecision decision(ModificationDecisionDecisionEnum decision) =>
      this(decision: decision);

  @override
  ModificationDecision operationId(String operationId) =>
      this(operationId: operationId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationDecision(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationDecision(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationDecision call({
    Object? after = const $CopyWithPlaceholder(),
    Object? decision = const $CopyWithPlaceholder(),
    Object? operationId = const $CopyWithPlaceholder(),
  }) {
    return ModificationDecision(
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as Object?,
      decision: decision == const $CopyWithPlaceholder()
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as ModificationDecisionDecisionEnum,
      operationId: operationId == const $CopyWithPlaceholder()
          ? _value.operationId
          // ignore: cast_nullable_to_non_nullable
          : operationId as String,
    );
  }
}

extension $ModificationDecisionCopyWith on ModificationDecision {
  /// Returns a callable class that can be used as follows: `instanceOfModificationDecision.copyWith(...)` or like so:`instanceOfModificationDecision.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationDecisionCWProxy get copyWith =>
      _$ModificationDecisionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationDecision _$ModificationDecisionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ModificationDecision', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['decision', 'operation_id']);
  final val = ModificationDecision(
    after: $checkedConvert('after', (v) => v),
    decision: $checkedConvert(
      'decision',
      (v) => $enumDecode(_$ModificationDecisionDecisionEnumEnumMap, v),
    ),
    operationId: $checkedConvert('operation_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'operationId': 'operation_id'});

Map<String, dynamic> _$ModificationDecisionToJson(
  ModificationDecision instance,
) => <String, dynamic>{
  'after': ?instance.after,
  'decision': _$ModificationDecisionDecisionEnumEnumMap[instance.decision]!,
  'operation_id': instance.operationId,
};

const _$ModificationDecisionDecisionEnumEnumMap = {
  ModificationDecisionDecisionEnum.accept: 'accept',
  ModificationDecisionDecisionEnum.reject: 'reject',
  ModificationDecisionDecisionEnum.modify: 'modify',
};
