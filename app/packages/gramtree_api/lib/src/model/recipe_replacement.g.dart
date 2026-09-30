// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_replacement.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeReplacementCWProxy {
  RecipeReplacement displayName(String displayName);

  RecipeReplacement ingredientId(String? ingredientId);

  RecipeReplacement note(String? note);

  RecipeReplacement ratio(num? ratio);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReplacement(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReplacement(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReplacement call({
    String displayName,
    String? ingredientId,
    String? note,
    num? ratio,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeReplacement.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeReplacement.copyWith.fieldName(...)`
class _$RecipeReplacementCWProxyImpl implements _$RecipeReplacementCWProxy {
  const _$RecipeReplacementCWProxyImpl(this._value);

  final RecipeReplacement _value;

  @override
  RecipeReplacement displayName(String displayName) =>
      this(displayName: displayName);

  @override
  RecipeReplacement ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  RecipeReplacement note(String? note) => this(note: note);

  @override
  RecipeReplacement ratio(num? ratio) => this(ratio: ratio);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReplacement(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReplacement(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReplacement call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? ratio = const $CopyWithPlaceholder(),
  }) {
    return RecipeReplacement(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      ratio: ratio == const $CopyWithPlaceholder()
          ? _value.ratio
          // ignore: cast_nullable_to_non_nullable
          : ratio as num?,
    );
  }
}

extension $RecipeReplacementCopyWith on RecipeReplacement {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeReplacement.copyWith(...)` or like so:`instanceOfRecipeReplacement.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeReplacementCWProxy get copyWith =>
      _$RecipeReplacementCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeReplacement _$RecipeReplacementFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeReplacement',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['display_name']);
        final val = RecipeReplacement(
          displayName: $checkedConvert('display_name', (v) => v as String),
          ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
          note: $checkedConvert('note', (v) => v as String?),
          ratio: $checkedConvert('ratio', (v) => v as num? ?? 1),
        );
        return val;
      },
      fieldKeyMap: const {
        'displayName': 'display_name',
        'ingredientId': 'ingredient_id',
      },
    );

Map<String, dynamic> _$RecipeReplacementToJson(RecipeReplacement instance) =>
    <String, dynamic>{
      'display_name': instance.displayName,
      'ingredient_id': ?instance.ingredientId,
      'note': ?instance.note,
      'ratio': ?instance.ratio,
    };
