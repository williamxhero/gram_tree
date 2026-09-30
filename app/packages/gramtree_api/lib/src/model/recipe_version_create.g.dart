// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_version_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeVersionCreateCWProxy {
  RecipeVersionCreate aiAssisted(bool? aiAssisted);

  RecipeVersionCreate baseVersionId(String? baseVersionId);

  RecipeVersionCreate changeNote(String? changeNote);

  RecipeVersionCreate snapshot(RecipeSnapshot snapshot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionCreate call({
    bool? aiAssisted,
    String? baseVersionId,
    String? changeNote,
    RecipeSnapshot snapshot,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeVersionCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeVersionCreate.copyWith.fieldName(...)`
class _$RecipeVersionCreateCWProxyImpl implements _$RecipeVersionCreateCWProxy {
  const _$RecipeVersionCreateCWProxyImpl(this._value);

  final RecipeVersionCreate _value;

  @override
  RecipeVersionCreate aiAssisted(bool? aiAssisted) =>
      this(aiAssisted: aiAssisted);

  @override
  RecipeVersionCreate baseVersionId(String? baseVersionId) =>
      this(baseVersionId: baseVersionId);

  @override
  RecipeVersionCreate changeNote(String? changeNote) =>
      this(changeNote: changeNote);

  @override
  RecipeVersionCreate snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionCreate call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? baseVersionId = const $CopyWithPlaceholder(),
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
  }) {
    return RecipeVersionCreate(
      aiAssisted: aiAssisted == const $CopyWithPlaceholder()
          ? _value.aiAssisted
          // ignore: cast_nullable_to_non_nullable
          : aiAssisted as bool?,
      baseVersionId: baseVersionId == const $CopyWithPlaceholder()
          ? _value.baseVersionId
          // ignore: cast_nullable_to_non_nullable
          : baseVersionId as String?,
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
    );
  }
}

extension $RecipeVersionCreateCopyWith on RecipeVersionCreate {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeVersionCreate.copyWith(...)` or like so:`instanceOfRecipeVersionCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeVersionCreateCWProxy get copyWith =>
      _$RecipeVersionCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeVersionCreate _$RecipeVersionCreateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeVersionCreate',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['snapshot']);
    final val = RecipeVersionCreate(
      aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool? ?? false),
      baseVersionId: $checkedConvert('base_version_id', (v) => v as String?),
      changeNote: $checkedConvert('change_note', (v) => v as String? ?? ''),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'aiAssisted': 'ai_assisted',
    'baseVersionId': 'base_version_id',
    'changeNote': 'change_note',
  },
);

Map<String, dynamic> _$RecipeVersionCreateToJson(
  RecipeVersionCreate instance,
) => <String, dynamic>{
  'ai_assisted': ?instance.aiAssisted,
  'base_version_id': ?instance.baseVersionId,
  'change_note': ?instance.changeNote,
  'snapshot': instance.snapshot.toJson(),
};
