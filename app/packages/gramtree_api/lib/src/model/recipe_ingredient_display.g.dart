// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient_display.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeIngredientDisplayCWProxy {
  RecipeIngredientDisplay ingredients(
    List<RecipeDisplayedIngredient> ingredients,
  );

  RecipeIngredientDisplay measureId(String? measureId);

  RecipeIngredientDisplay mode(RecipeIngredientDisplayModeEnum mode);

  RecipeIngredientDisplay recipeId(String recipeId);

  RecipeIngredientDisplay versionId(String versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientDisplay(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientDisplay(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientDisplay call({
    List<RecipeDisplayedIngredient> ingredients,
    String? measureId,
    RecipeIngredientDisplayModeEnum mode,
    String recipeId,
    String versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeIngredientDisplay.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeIngredientDisplay.copyWith.fieldName(...)`
class _$RecipeIngredientDisplayCWProxyImpl
    implements _$RecipeIngredientDisplayCWProxy {
  const _$RecipeIngredientDisplayCWProxyImpl(this._value);

  final RecipeIngredientDisplay _value;

  @override
  RecipeIngredientDisplay ingredients(
    List<RecipeDisplayedIngredient> ingredients,
  ) => this(ingredients: ingredients);

  @override
  RecipeIngredientDisplay measureId(String? measureId) =>
      this(measureId: measureId);

  @override
  RecipeIngredientDisplay mode(RecipeIngredientDisplayModeEnum mode) =>
      this(mode: mode);

  @override
  RecipeIngredientDisplay recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  RecipeIngredientDisplay versionId(String versionId) =>
      this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientDisplay(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientDisplay(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientDisplay call({
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? measureId = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return RecipeIngredientDisplay(
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<RecipeDisplayedIngredient>,
      measureId: measureId == const $CopyWithPlaceholder()
          ? _value.measureId
          // ignore: cast_nullable_to_non_nullable
          : measureId as String?,
      mode: mode == const $CopyWithPlaceholder()
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as RecipeIngredientDisplayModeEnum,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
    );
  }
}

extension $RecipeIngredientDisplayCopyWith on RecipeIngredientDisplay {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeIngredientDisplay.copyWith(...)` or like so:`instanceOfRecipeIngredientDisplay.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeIngredientDisplayCWProxy get copyWith =>
      _$RecipeIngredientDisplayCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredientDisplay _$RecipeIngredientDisplayFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeIngredientDisplay',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['ingredients', 'mode', 'recipe_id', 'version_id'],
    );
    final val = RecipeIngredientDisplay(
      ingredients: $checkedConvert(
        'ingredients',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  RecipeDisplayedIngredient.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      measureId: $checkedConvert('measure_id', (v) => v as String?),
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$RecipeIngredientDisplayModeEnumEnumMap, v),
      ),
      recipeId: $checkedConvert('recipe_id', (v) => v as String),
      versionId: $checkedConvert('version_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'measureId': 'measure_id',
    'recipeId': 'recipe_id',
    'versionId': 'version_id',
  },
);

Map<String, dynamic> _$RecipeIngredientDisplayToJson(
  RecipeIngredientDisplay instance,
) => <String, dynamic>{
  'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
  'measure_id': ?instance.measureId,
  'mode': _$RecipeIngredientDisplayModeEnumEnumMap[instance.mode]!,
  'recipe_id': instance.recipeId,
  'version_id': instance.versionId,
};

const _$RecipeIngredientDisplayModeEnumEnumMap = {
  RecipeIngredientDisplayModeEnum.base_: 'base',
  RecipeIngredientDisplayModeEnum.standard: 'standard',
  RecipeIngredientDisplayModeEnum.home: 'home',
};
