// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient_replacement.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeIngredientReplacementCWProxy {
  RecipeIngredientReplacement displayName(String displayName);

  RecipeIngredientReplacement ingredientId(String ingredientId);

  RecipeIngredientReplacement note(String note);

  RecipeIngredientReplacement ratio(num? ratio);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientReplacement(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientReplacement(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientReplacement call({
    String displayName,
    String ingredientId,
    String note,
    num? ratio,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeIngredientReplacement.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeIngredientReplacement.copyWith.fieldName(...)`
class _$RecipeIngredientReplacementCWProxyImpl
    implements _$RecipeIngredientReplacementCWProxy {
  const _$RecipeIngredientReplacementCWProxyImpl(this._value);

  final RecipeIngredientReplacement _value;

  @override
  RecipeIngredientReplacement displayName(String displayName) =>
      this(displayName: displayName);

  @override
  RecipeIngredientReplacement ingredientId(String ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  RecipeIngredientReplacement note(String note) => this(note: note);

  @override
  RecipeIngredientReplacement ratio(num? ratio) => this(ratio: ratio);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientReplacement(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientReplacement(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientReplacement call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? ratio = const $CopyWithPlaceholder(),
  }) {
    return RecipeIngredientReplacement(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      ratio: ratio == const $CopyWithPlaceholder()
          ? _value.ratio
          // ignore: cast_nullable_to_non_nullable
          : ratio as num?,
    );
  }
}

extension $RecipeIngredientReplacementCopyWith on RecipeIngredientReplacement {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeIngredientReplacement.copyWith(...)` or like so:`instanceOfRecipeIngredientReplacement.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeIngredientReplacementCWProxy get copyWith =>
      _$RecipeIngredientReplacementCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredientReplacement _$RecipeIngredientReplacementFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeIngredientReplacement',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['display_name', 'ingredient_id', 'note'],
    );
    final val = RecipeIngredientReplacement(
      displayName: $checkedConvert('display_name', (v) => v as String),
      ingredientId: $checkedConvert('ingredient_id', (v) => v as String),
      note: $checkedConvert('note', (v) => v as String),
      ratio: $checkedConvert('ratio', (v) => v as num? ?? 1),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'ingredientId': 'ingredient_id',
  },
);

Map<String, dynamic> _$RecipeIngredientReplacementToJson(
  RecipeIngredientReplacement instance,
) => <String, dynamic>{
  'display_name': instance.displayName,
  'ingredient_id': instance.ingredientId,
  'note': instance.note,
  'ratio': ?instance.ratio,
};
