// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_replacement_allergens.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeReplacementAllergensCWProxy {
  RecipeReplacementAllergens allergens(List<String>? allergens);

  RecipeReplacementAllergens displayName(String displayName);

  RecipeReplacementAllergens incomplete(bool? incomplete);

  RecipeReplacementAllergens ingredientId(String ingredientId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReplacementAllergens(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReplacementAllergens(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReplacementAllergens call({
    List<String>? allergens,
    String displayName,
    bool? incomplete,
    String ingredientId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeReplacementAllergens.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeReplacementAllergens.copyWith.fieldName(...)`
class _$RecipeReplacementAllergensCWProxyImpl
    implements _$RecipeReplacementAllergensCWProxy {
  const _$RecipeReplacementAllergensCWProxyImpl(this._value);

  final RecipeReplacementAllergens _value;

  @override
  RecipeReplacementAllergens allergens(List<String>? allergens) =>
      this(allergens: allergens);

  @override
  RecipeReplacementAllergens displayName(String displayName) =>
      this(displayName: displayName);

  @override
  RecipeReplacementAllergens incomplete(bool? incomplete) =>
      this(incomplete: incomplete);

  @override
  RecipeReplacementAllergens ingredientId(String ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReplacementAllergens(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReplacementAllergens(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReplacementAllergens call({
    Object? allergens = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? incomplete = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
  }) {
    return RecipeReplacementAllergens(
      allergens: allergens == const $CopyWithPlaceholder()
          ? _value.allergens
          // ignore: cast_nullable_to_non_nullable
          : allergens as List<String>?,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      incomplete: incomplete == const $CopyWithPlaceholder()
          ? _value.incomplete
          // ignore: cast_nullable_to_non_nullable
          : incomplete as bool?,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String,
    );
  }
}

extension $RecipeReplacementAllergensCopyWith on RecipeReplacementAllergens {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeReplacementAllergens.copyWith(...)` or like so:`instanceOfRecipeReplacementAllergens.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeReplacementAllergensCWProxy get copyWith =>
      _$RecipeReplacementAllergensCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeReplacementAllergens _$RecipeReplacementAllergensFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeReplacementAllergens',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['display_name', 'ingredient_id']);
    final val = RecipeReplacementAllergens(
      allergens: $checkedConvert(
        'allergens',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      displayName: $checkedConvert('display_name', (v) => v as String),
      incomplete: $checkedConvert('incomplete', (v) => v as bool? ?? false),
      ingredientId: $checkedConvert('ingredient_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'ingredientId': 'ingredient_id',
  },
);

Map<String, dynamic> _$RecipeReplacementAllergensToJson(
  RecipeReplacementAllergens instance,
) => <String, dynamic>{
  'allergens': ?instance.allergens,
  'display_name': instance.displayName,
  'incomplete': ?instance.incomplete,
  'ingredient_id': instance.ingredientId,
};
