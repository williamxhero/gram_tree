// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_decisions_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationDecisionsInputCWProxy {
  ModificationDecisionsInput decisions(List<ModificationDecision>? decisions);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationDecisionsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationDecisionsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationDecisionsInput call({List<ModificationDecision>? decisions});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationDecisionsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationDecisionsInput.copyWith.fieldName(...)`
class _$ModificationDecisionsInputCWProxyImpl
    implements _$ModificationDecisionsInputCWProxy {
  const _$ModificationDecisionsInputCWProxyImpl(this._value);

  final ModificationDecisionsInput _value;

  @override
  ModificationDecisionsInput decisions(List<ModificationDecision>? decisions) =>
      this(decisions: decisions);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationDecisionsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationDecisionsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationDecisionsInput call({
    Object? decisions = const $CopyWithPlaceholder(),
  }) {
    return ModificationDecisionsInput(
      decisions: decisions == const $CopyWithPlaceholder()
          ? _value.decisions
          // ignore: cast_nullable_to_non_nullable
          : decisions as List<ModificationDecision>?,
    );
  }
}

extension $ModificationDecisionsInputCopyWith on ModificationDecisionsInput {
  /// Returns a callable class that can be used as follows: `instanceOfModificationDecisionsInput.copyWith(...)` or like so:`instanceOfModificationDecisionsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationDecisionsInputCWProxy get copyWith =>
      _$ModificationDecisionsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationDecisionsInput _$ModificationDecisionsInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ModificationDecisionsInput', json, ($checkedConvert) {
  final val = ModificationDecisionsInput(
    decisions: $checkedConvert(
      'decisions',
      (v) => (v as List<dynamic>?)
          ?.map((e) => ModificationDecision.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ModificationDecisionsInputToJson(
  ModificationDecisionsInput instance,
) => <String, dynamic>{
  'decisions': ?instance.decisions?.map((e) => e.toJson()).toList(),
};
