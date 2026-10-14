// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_version_save_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecordVersionSaveInputCWProxy {
  RecordVersionSaveInput changeNote(String? changeNote);

  RecordVersionSaveInput requestId(String requestId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecordVersionSaveInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecordVersionSaveInput(...).copyWith(id: 12, name: "My name")
  /// ````
  RecordVersionSaveInput call({String? changeNote, String requestId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecordVersionSaveInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecordVersionSaveInput.copyWith.fieldName(...)`
class _$RecordVersionSaveInputCWProxyImpl
    implements _$RecordVersionSaveInputCWProxy {
  const _$RecordVersionSaveInputCWProxyImpl(this._value);

  final RecordVersionSaveInput _value;

  @override
  RecordVersionSaveInput changeNote(String? changeNote) =>
      this(changeNote: changeNote);

  @override
  RecordVersionSaveInput requestId(String requestId) =>
      this(requestId: requestId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecordVersionSaveInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecordVersionSaveInput(...).copyWith(id: 12, name: "My name")
  /// ````
  RecordVersionSaveInput call({
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
  }) {
    return RecordVersionSaveInput(
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
    );
  }
}

extension $RecordVersionSaveInputCopyWith on RecordVersionSaveInput {
  /// Returns a callable class that can be used as follows: `instanceOfRecordVersionSaveInput.copyWith(...)` or like so:`instanceOfRecordVersionSaveInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecordVersionSaveInputCWProxy get copyWith =>
      _$RecordVersionSaveInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordVersionSaveInput _$RecordVersionSaveInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecordVersionSaveInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['request_id']);
  final val = RecordVersionSaveInput(
    changeNote: $checkedConvert('change_note', (v) => v as String? ?? '临场调整'),
    requestId: $checkedConvert('request_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'changeNote': 'change_note', 'requestId': 'request_id'});

Map<String, dynamic> _$RecordVersionSaveInputToJson(
  RecordVersionSaveInput instance,
) => <String, dynamic>{
  'change_note': ?instance.changeNote,
  'request_id': instance.requestId,
};
