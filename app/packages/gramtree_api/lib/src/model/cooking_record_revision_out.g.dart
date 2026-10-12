// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_record_revision_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingRecordRevisionOutCWProxy {
  CookingRecordRevisionOut createdAt(String createdAt);

  CookingRecordRevisionOut field(String field);

  CookingRecordRevisionOut note(String note);

  CookingRecordRevisionOut revision(int revision);

  CookingRecordRevisionOut revisionId(String revisionId);

  CookingRecordRevisionOut value(Object value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordRevisionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordRevisionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordRevisionOut call({
    String createdAt,
    String field,
    String note,
    int revision,
    String revisionId,
    Object value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingRecordRevisionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingRecordRevisionOut.copyWith.fieldName(...)`
class _$CookingRecordRevisionOutCWProxyImpl
    implements _$CookingRecordRevisionOutCWProxy {
  const _$CookingRecordRevisionOutCWProxyImpl(this._value);

  final CookingRecordRevisionOut _value;

  @override
  CookingRecordRevisionOut createdAt(String createdAt) =>
      this(createdAt: createdAt);

  @override
  CookingRecordRevisionOut field(String field) => this(field: field);

  @override
  CookingRecordRevisionOut note(String note) => this(note: note);

  @override
  CookingRecordRevisionOut revision(int revision) => this(revision: revision);

  @override
  CookingRecordRevisionOut revisionId(String revisionId) =>
      this(revisionId: revisionId);

  @override
  CookingRecordRevisionOut value(Object value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordRevisionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordRevisionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordRevisionOut call({
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? revision = const $CopyWithPlaceholder(),
    Object? revisionId = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return CookingRecordRevisionOut(
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      revision: revision == const $CopyWithPlaceholder()
          ? _value.revision
          // ignore: cast_nullable_to_non_nullable
          : revision as int,
      revisionId: revisionId == const $CopyWithPlaceholder()
          ? _value.revisionId
          // ignore: cast_nullable_to_non_nullable
          : revisionId as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as Object,
    );
  }
}

extension $CookingRecordRevisionOutCopyWith on CookingRecordRevisionOut {
  /// Returns a callable class that can be used as follows: `instanceOfCookingRecordRevisionOut.copyWith(...)` or like so:`instanceOfCookingRecordRevisionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingRecordRevisionOutCWProxy get copyWith =>
      _$CookingRecordRevisionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingRecordRevisionOut _$CookingRecordRevisionOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CookingRecordRevisionOut', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'created_at',
      'field',
      'note',
      'revision',
      'revision_id',
      'value',
    ],
  );
  final val = CookingRecordRevisionOut(
    createdAt: $checkedConvert('created_at', (v) => v as String),
    field: $checkedConvert('field', (v) => v as String),
    note: $checkedConvert('note', (v) => v as String),
    revision: $checkedConvert('revision', (v) => (v as num).toInt()),
    revisionId: $checkedConvert('revision_id', (v) => v as String),
    value: $checkedConvert('value', (v) => v as Object),
  );
  return val;
}, fieldKeyMap: const {'createdAt': 'created_at', 'revisionId': 'revision_id'});

Map<String, dynamic> _$CookingRecordRevisionOutToJson(
  CookingRecordRevisionOut instance,
) => <String, dynamic>{
  'created_at': instance.createdAt,
  'field': instance.field,
  'note': instance.note,
  'revision': instance.revision,
  'revision_id': instance.revisionId,
  'value': instance.value,
};
