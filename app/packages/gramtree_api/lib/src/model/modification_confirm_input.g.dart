// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_confirm_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationConfirmInputCWProxy {
  ModificationConfirmInput changeNote(String? changeNote);

  ModificationConfirmInput revision(int revision);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationConfirmInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationConfirmInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationConfirmInput call({String? changeNote, int revision});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationConfirmInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationConfirmInput.copyWith.fieldName(...)`
class _$ModificationConfirmInputCWProxyImpl
    implements _$ModificationConfirmInputCWProxy {
  const _$ModificationConfirmInputCWProxyImpl(this._value);

  final ModificationConfirmInput _value;

  @override
  ModificationConfirmInput changeNote(String? changeNote) =>
      this(changeNote: changeNote);

  @override
  ModificationConfirmInput revision(int revision) => this(revision: revision);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationConfirmInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationConfirmInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationConfirmInput call({
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? revision = const $CopyWithPlaceholder(),
  }) {
    return ModificationConfirmInput(
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      revision: revision == const $CopyWithPlaceholder()
          ? _value.revision
          // ignore: cast_nullable_to_non_nullable
          : revision as int,
    );
  }
}

extension $ModificationConfirmInputCopyWith on ModificationConfirmInput {
  /// Returns a callable class that can be used as follows: `instanceOfModificationConfirmInput.copyWith(...)` or like so:`instanceOfModificationConfirmInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationConfirmInputCWProxy get copyWith =>
      _$ModificationConfirmInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationConfirmInput _$ModificationConfirmInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ModificationConfirmInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['revision']);
  final val = ModificationConfirmInput(
    changeNote: $checkedConvert('change_note', (v) => v as String? ?? ''),
    revision: $checkedConvert('revision', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'changeNote': 'change_note'});

Map<String, dynamic> _$ModificationConfirmInputToJson(
  ModificationConfirmInput instance,
) => <String, dynamic>{
  'change_note': ?instance.changeNote,
  'revision': instance.revision,
};
