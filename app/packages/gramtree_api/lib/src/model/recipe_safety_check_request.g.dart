// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_safety_check_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeSafetyCheckRequestCWProxy {
  RecipeSafetyCheckRequest changeNote(String? changeNote);

  RecipeSafetyCheckRequest description(String? description);

  RecipeSafetyCheckRequest dishAliases(List<String>? dishAliases);

  RecipeSafetyCheckRequest dishName(String? dishName);

  RecipeSafetyCheckRequest snapshot(RecipeSnapshot snapshot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyCheckRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyCheckRequest call({
    String? changeNote,
    String? description,
    List<String>? dishAliases,
    String? dishName,
    RecipeSnapshot snapshot,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeSafetyCheckRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeSafetyCheckRequest.copyWith.fieldName(...)`
class _$RecipeSafetyCheckRequestCWProxyImpl
    implements _$RecipeSafetyCheckRequestCWProxy {
  const _$RecipeSafetyCheckRequestCWProxyImpl(this._value);

  final RecipeSafetyCheckRequest _value;

  @override
  RecipeSafetyCheckRequest changeNote(String? changeNote) =>
      this(changeNote: changeNote);

  @override
  RecipeSafetyCheckRequest description(String? description) =>
      this(description: description);

  @override
  RecipeSafetyCheckRequest dishAliases(List<String>? dishAliases) =>
      this(dishAliases: dishAliases);

  @override
  RecipeSafetyCheckRequest dishName(String? dishName) =>
      this(dishName: dishName);

  @override
  RecipeSafetyCheckRequest snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyCheckRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyCheckRequest call({
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? dishAliases = const $CopyWithPlaceholder(),
    Object? dishName = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
  }) {
    return RecipeSafetyCheckRequest(
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      dishAliases: dishAliases == const $CopyWithPlaceholder()
          ? _value.dishAliases
          // ignore: cast_nullable_to_non_nullable
          : dishAliases as List<String>?,
      dishName: dishName == const $CopyWithPlaceholder()
          ? _value.dishName
          // ignore: cast_nullable_to_non_nullable
          : dishName as String?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
    );
  }
}

extension $RecipeSafetyCheckRequestCopyWith on RecipeSafetyCheckRequest {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeSafetyCheckRequest.copyWith(...)` or like so:`instanceOfRecipeSafetyCheckRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeSafetyCheckRequestCWProxy get copyWith =>
      _$RecipeSafetyCheckRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSafetyCheckRequest _$RecipeSafetyCheckRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeSafetyCheckRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['snapshot']);
    final val = RecipeSafetyCheckRequest(
      changeNote: $checkedConvert('change_note', (v) => v as String? ?? ''),
      description: $checkedConvert('description', (v) => v as String?),
      dishAliases: $checkedConvert(
        'dish_aliases',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      dishName: $checkedConvert('dish_name', (v) => v as String? ?? ''),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'changeNote': 'change_note',
    'dishAliases': 'dish_aliases',
    'dishName': 'dish_name',
  },
);

Map<String, dynamic> _$RecipeSafetyCheckRequestToJson(
  RecipeSafetyCheckRequest instance,
) => <String, dynamic>{
  'change_note': ?instance.changeNote,
  'description': ?instance.description,
  'dish_aliases': ?instance.dishAliases,
  'dish_name': ?instance.dishName,
  'snapshot': instance.snapshot.toJson(),
};
