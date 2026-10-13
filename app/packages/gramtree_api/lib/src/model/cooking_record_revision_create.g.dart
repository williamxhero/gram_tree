// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_record_revision_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingRecordRevisionCreateCWProxy {
  CookingRecordRevisionCreate field(CookingRecordRevisionCreateFieldEnum field);

  CookingRecordRevisionCreate note(String? note);

  CookingRecordRevisionCreate revisionId(String revisionId);

  CookingRecordRevisionCreate value(Object value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordRevisionCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordRevisionCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordRevisionCreate call({
    CookingRecordRevisionCreateFieldEnum field,
    String? note,
    String revisionId,
    Object value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingRecordRevisionCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingRecordRevisionCreate.copyWith.fieldName(...)`
class _$CookingRecordRevisionCreateCWProxyImpl
    implements _$CookingRecordRevisionCreateCWProxy {
  const _$CookingRecordRevisionCreateCWProxyImpl(this._value);

  final CookingRecordRevisionCreate _value;

  @override
  CookingRecordRevisionCreate field(
    CookingRecordRevisionCreateFieldEnum field,
  ) => this(field: field);

  @override
  CookingRecordRevisionCreate note(String? note) => this(note: note);

  @override
  CookingRecordRevisionCreate revisionId(String revisionId) =>
      this(revisionId: revisionId);

  @override
  CookingRecordRevisionCreate value(Object value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordRevisionCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordRevisionCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordRevisionCreate call({
    Object? field = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? revisionId = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return CookingRecordRevisionCreate(
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as CookingRecordRevisionCreateFieldEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
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

extension $CookingRecordRevisionCreateCopyWith on CookingRecordRevisionCreate {
  /// Returns a callable class that can be used as follows: `instanceOfCookingRecordRevisionCreate.copyWith(...)` or like so:`instanceOfCookingRecordRevisionCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingRecordRevisionCreateCWProxy get copyWith =>
      _$CookingRecordRevisionCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingRecordRevisionCreate _$CookingRecordRevisionCreateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CookingRecordRevisionCreate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['field', 'revision_id', 'value']);
  final val = CookingRecordRevisionCreate(
    field: $checkedConvert(
      'field',
      (v) => $enumDecode(_$CookingRecordRevisionCreateFieldEnumEnumMap, v),
    ),
    note: $checkedConvert('note', (v) => v as String? ?? ''),
    revisionId: $checkedConvert('revision_id', (v) => v as String),
    value: $checkedConvert('value', (v) => v as Object),
  );
  return val;
}, fieldKeyMap: const {'revisionId': 'revision_id'});

Map<String, dynamic> _$CookingRecordRevisionCreateToJson(
  CookingRecordRevisionCreate instance,
) => <String, dynamic>{
  'field': _$CookingRecordRevisionCreateFieldEnumEnumMap[instance.field]!,
  'note': ?instance.note,
  'revision_id': instance.revisionId,
  'value': instance.value,
};

const _$CookingRecordRevisionCreateFieldEnumEnumMap = {
  CookingRecordRevisionCreateFieldEnum.rating: 'rating',
  CookingRecordRevisionCreateFieldEnum.feedback: 'feedback',
  CookingRecordRevisionCreateFieldEnum.tags: 'tags',
};
