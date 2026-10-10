// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeCreateCWProxy {
  RecipeCreate aiAssisted(bool? aiAssisted);

  RecipeCreate changeNote(String? changeNote);

  RecipeCreate dish(DishInput? dish);

  RecipeCreate dishAliases(List<String>? dishAliases);

  RecipeCreate dishName(String? dishName);

  RecipeCreate explanationFingerprint(String? explanationFingerprint);

  RecipeCreate imageIds(List<String>? imageIds);

  RecipeCreate snapshot(RecipeSnapshot snapshot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeCreate call({
    bool? aiAssisted,
    String? changeNote,
    DishInput? dish,
    List<String>? dishAliases,
    String? dishName,
    String? explanationFingerprint,
    List<String>? imageIds,
    RecipeSnapshot snapshot,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeCreate.copyWith.fieldName(...)`
class _$RecipeCreateCWProxyImpl implements _$RecipeCreateCWProxy {
  const _$RecipeCreateCWProxyImpl(this._value);

  final RecipeCreate _value;

  @override
  RecipeCreate aiAssisted(bool? aiAssisted) => this(aiAssisted: aiAssisted);

  @override
  RecipeCreate changeNote(String? changeNote) => this(changeNote: changeNote);

  @override
  RecipeCreate dish(DishInput? dish) => this(dish: dish);

  @override
  RecipeCreate dishAliases(List<String>? dishAliases) =>
      this(dishAliases: dishAliases);

  @override
  RecipeCreate dishName(String? dishName) => this(dishName: dishName);

  @override
  RecipeCreate explanationFingerprint(String? explanationFingerprint) =>
      this(explanationFingerprint: explanationFingerprint);

  @override
  RecipeCreate imageIds(List<String>? imageIds) => this(imageIds: imageIds);

  @override
  RecipeCreate snapshot(RecipeSnapshot snapshot) => this(snapshot: snapshot);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeCreate call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? dish = const $CopyWithPlaceholder(),
    Object? dishAliases = const $CopyWithPlaceholder(),
    Object? dishName = const $CopyWithPlaceholder(),
    Object? explanationFingerprint = const $CopyWithPlaceholder(),
    Object? imageIds = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
  }) {
    return RecipeCreate(
      aiAssisted: aiAssisted == const $CopyWithPlaceholder()
          ? _value.aiAssisted
          // ignore: cast_nullable_to_non_nullable
          : aiAssisted as bool?,
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      dish: dish == const $CopyWithPlaceholder()
          ? _value.dish
          // ignore: cast_nullable_to_non_nullable
          : dish as DishInput?,
      dishAliases: dishAliases == const $CopyWithPlaceholder()
          ? _value.dishAliases
          // ignore: cast_nullable_to_non_nullable
          : dishAliases as List<String>?,
      dishName: dishName == const $CopyWithPlaceholder()
          ? _value.dishName
          // ignore: cast_nullable_to_non_nullable
          : dishName as String?,
      explanationFingerprint:
          explanationFingerprint == const $CopyWithPlaceholder()
          ? _value.explanationFingerprint
          // ignore: cast_nullable_to_non_nullable
          : explanationFingerprint as String?,
      imageIds: imageIds == const $CopyWithPlaceholder()
          ? _value.imageIds
          // ignore: cast_nullable_to_non_nullable
          : imageIds as List<String>?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
    );
  }
}

extension $RecipeCreateCopyWith on RecipeCreate {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeCreate.copyWith(...)` or like so:`instanceOfRecipeCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeCreateCWProxy get copyWith => _$RecipeCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeCreate _$RecipeCreateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeCreate',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['snapshot']);
    final val = RecipeCreate(
      aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool? ?? false),
      changeNote: $checkedConvert('change_note', (v) => v as String? ?? ''),
      dish: $checkedConvert(
        'dish',
        (v) => v == null ? null : DishInput.fromJson(v as Map<String, dynamic>),
      ),
      dishAliases: $checkedConvert(
        'dish_aliases',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      dishName: $checkedConvert('dish_name', (v) => v as String?),
      explanationFingerprint: $checkedConvert(
        'explanation_fingerprint',
        (v) => v as String?,
      ),
      imageIds: $checkedConvert(
        'image_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'aiAssisted': 'ai_assisted',
    'changeNote': 'change_note',
    'dishAliases': 'dish_aliases',
    'dishName': 'dish_name',
    'explanationFingerprint': 'explanation_fingerprint',
    'imageIds': 'image_ids',
  },
);

Map<String, dynamic> _$RecipeCreateToJson(RecipeCreate instance) =>
    <String, dynamic>{
      'ai_assisted': ?instance.aiAssisted,
      'change_note': ?instance.changeNote,
      'dish': ?instance.dish?.toJson(),
      'dish_aliases': ?instance.dishAliases,
      'dish_name': ?instance.dishName,
      'explanation_fingerprint': ?instance.explanationFingerprint,
      'image_ids': ?instance.imageIds,
      'snapshot': instance.snapshot.toJson(),
    };
