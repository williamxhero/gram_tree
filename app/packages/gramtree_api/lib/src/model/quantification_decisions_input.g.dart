// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantification_decisions_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuantificationDecisionsInputCWProxy {
  QuantificationDecisionsInput acceptAll(bool? acceptAll);

  QuantificationDecisionsInput decisions(
    List<QuantificationDecision>? decisions,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationDecisionsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationDecisionsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationDecisionsInput call({
    bool? acceptAll,
    List<QuantificationDecision>? decisions,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuantificationDecisionsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuantificationDecisionsInput.copyWith.fieldName(...)`
class _$QuantificationDecisionsInputCWProxyImpl
    implements _$QuantificationDecisionsInputCWProxy {
  const _$QuantificationDecisionsInputCWProxyImpl(this._value);

  final QuantificationDecisionsInput _value;

  @override
  QuantificationDecisionsInput acceptAll(bool? acceptAll) =>
      this(acceptAll: acceptAll);

  @override
  QuantificationDecisionsInput decisions(
    List<QuantificationDecision>? decisions,
  ) => this(decisions: decisions);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationDecisionsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationDecisionsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationDecisionsInput call({
    Object? acceptAll = const $CopyWithPlaceholder(),
    Object? decisions = const $CopyWithPlaceholder(),
  }) {
    return QuantificationDecisionsInput(
      acceptAll: acceptAll == const $CopyWithPlaceholder()
          ? _value.acceptAll
          // ignore: cast_nullable_to_non_nullable
          : acceptAll as bool?,
      decisions: decisions == const $CopyWithPlaceholder()
          ? _value.decisions
          // ignore: cast_nullable_to_non_nullable
          : decisions as List<QuantificationDecision>?,
    );
  }
}

extension $QuantificationDecisionsInputCopyWith
    on QuantificationDecisionsInput {
  /// Returns a callable class that can be used as follows: `instanceOfQuantificationDecisionsInput.copyWith(...)` or like so:`instanceOfQuantificationDecisionsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuantificationDecisionsInputCWProxy get copyWith =>
      _$QuantificationDecisionsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuantificationDecisionsInput _$QuantificationDecisionsInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QuantificationDecisionsInput', json, ($checkedConvert) {
  final val = QuantificationDecisionsInput(
    acceptAll: $checkedConvert('accept_all', (v) => v as bool? ?? false),
    decisions: $checkedConvert(
      'decisions',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => QuantificationDecision.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'acceptAll': 'accept_all'});

Map<String, dynamic> _$QuantificationDecisionsInputToJson(
  QuantificationDecisionsInput instance,
) => <String, dynamic>{
  'accept_all': ?instance.acceptAll,
  'decisions': ?instance.decisions?.map((e) => e.toJson()).toList(),
};
