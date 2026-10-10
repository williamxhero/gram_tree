// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_decision_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationDecisionOutCWProxy {
  ModificationDecisionOut after(Object? after);

  ModificationDecisionOut blockedBy(List<String>? blockedBy);

  ModificationDecisionOut decision(
    ModificationDecisionOutDecisionEnum decision,
  );

  ModificationDecisionOut operationId(String operationId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationDecisionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationDecisionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationDecisionOut call({
    Object? after,
    List<String>? blockedBy,
    ModificationDecisionOutDecisionEnum decision,
    String operationId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationDecisionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationDecisionOut.copyWith.fieldName(...)`
class _$ModificationDecisionOutCWProxyImpl
    implements _$ModificationDecisionOutCWProxy {
  const _$ModificationDecisionOutCWProxyImpl(this._value);

  final ModificationDecisionOut _value;

  @override
  ModificationDecisionOut after(Object? after) => this(after: after);

  @override
  ModificationDecisionOut blockedBy(List<String>? blockedBy) =>
      this(blockedBy: blockedBy);

  @override
  ModificationDecisionOut decision(
    ModificationDecisionOutDecisionEnum decision,
  ) => this(decision: decision);

  @override
  ModificationDecisionOut operationId(String operationId) =>
      this(operationId: operationId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationDecisionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationDecisionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationDecisionOut call({
    Object? after = const $CopyWithPlaceholder(),
    Object? blockedBy = const $CopyWithPlaceholder(),
    Object? decision = const $CopyWithPlaceholder(),
    Object? operationId = const $CopyWithPlaceholder(),
  }) {
    return ModificationDecisionOut(
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as Object?,
      blockedBy: blockedBy == const $CopyWithPlaceholder()
          ? _value.blockedBy
          // ignore: cast_nullable_to_non_nullable
          : blockedBy as List<String>?,
      decision: decision == const $CopyWithPlaceholder()
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as ModificationDecisionOutDecisionEnum,
      operationId: operationId == const $CopyWithPlaceholder()
          ? _value.operationId
          // ignore: cast_nullable_to_non_nullable
          : operationId as String,
    );
  }
}

extension $ModificationDecisionOutCopyWith on ModificationDecisionOut {
  /// Returns a callable class that can be used as follows: `instanceOfModificationDecisionOut.copyWith(...)` or like so:`instanceOfModificationDecisionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationDecisionOutCWProxy get copyWith =>
      _$ModificationDecisionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationDecisionOut _$ModificationDecisionOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ModificationDecisionOut',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['decision', 'operation_id']);
    final val = ModificationDecisionOut(
      after: $checkedConvert('after', (v) => v),
      blockedBy: $checkedConvert(
        'blocked_by',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      decision: $checkedConvert(
        'decision',
        (v) => $enumDecode(_$ModificationDecisionOutDecisionEnumEnumMap, v),
      ),
      operationId: $checkedConvert('operation_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'blockedBy': 'blocked_by', 'operationId': 'operation_id'},
);

Map<String, dynamic> _$ModificationDecisionOutToJson(
  ModificationDecisionOut instance,
) => <String, dynamic>{
  'after': ?instance.after,
  'blocked_by': ?instance.blockedBy,
  'decision': _$ModificationDecisionOutDecisionEnumEnumMap[instance.decision]!,
  'operation_id': instance.operationId,
};

const _$ModificationDecisionOutDecisionEnumEnumMap = {
  ModificationDecisionOutDecisionEnum.pending: 'pending',
  ModificationDecisionOutDecisionEnum.accept: 'accept',
  ModificationDecisionOutDecisionEnum.reject: 'reject',
  ModificationDecisionOutDecisionEnum.modify: 'modify',
};
