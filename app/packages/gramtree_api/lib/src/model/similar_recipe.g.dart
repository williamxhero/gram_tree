// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_recipe.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SimilarRecipeCWProxy {
  SimilarRecipe aiAssisted(bool aiAssisted);

  SimilarRecipe basis(String basis);

  SimilarRecipe dishName(String dishName);

  SimilarRecipe recipeId(String recipeId);

  SimilarRecipe servings(int servings);

  SimilarRecipe versionId(String versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SimilarRecipe(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SimilarRecipe(...).copyWith(id: 12, name: "My name")
  /// ````
  SimilarRecipe call({
    bool aiAssisted,
    String basis,
    String dishName,
    String recipeId,
    int servings,
    String versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSimilarRecipe.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSimilarRecipe.copyWith.fieldName(...)`
class _$SimilarRecipeCWProxyImpl implements _$SimilarRecipeCWProxy {
  const _$SimilarRecipeCWProxyImpl(this._value);

  final SimilarRecipe _value;

  @override
  SimilarRecipe aiAssisted(bool aiAssisted) => this(aiAssisted: aiAssisted);

  @override
  SimilarRecipe basis(String basis) => this(basis: basis);

  @override
  SimilarRecipe dishName(String dishName) => this(dishName: dishName);

  @override
  SimilarRecipe recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  SimilarRecipe servings(int servings) => this(servings: servings);

  @override
  SimilarRecipe versionId(String versionId) => this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SimilarRecipe(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SimilarRecipe(...).copyWith(id: 12, name: "My name")
  /// ````
  SimilarRecipe call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? dishName = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? servings = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return SimilarRecipe(
      aiAssisted: aiAssisted == const $CopyWithPlaceholder()
          ? _value.aiAssisted
          // ignore: cast_nullable_to_non_nullable
          : aiAssisted as bool,
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      dishName: dishName == const $CopyWithPlaceholder()
          ? _value.dishName
          // ignore: cast_nullable_to_non_nullable
          : dishName as String,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      servings: servings == const $CopyWithPlaceholder()
          ? _value.servings
          // ignore: cast_nullable_to_non_nullable
          : servings as int,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
    );
  }
}

extension $SimilarRecipeCopyWith on SimilarRecipe {
  /// Returns a callable class that can be used as follows: `instanceOfSimilarRecipe.copyWith(...)` or like so:`instanceOfSimilarRecipe.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SimilarRecipeCWProxy get copyWith => _$SimilarRecipeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimilarRecipe _$SimilarRecipeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SimilarRecipe',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ai_assisted',
            'basis',
            'dish_name',
            'recipe_id',
            'servings',
            'version_id',
          ],
        );
        final val = SimilarRecipe(
          aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool),
          basis: $checkedConvert('basis', (v) => v as String),
          dishName: $checkedConvert('dish_name', (v) => v as String),
          recipeId: $checkedConvert('recipe_id', (v) => v as String),
          servings: $checkedConvert('servings', (v) => (v as num).toInt()),
          versionId: $checkedConvert('version_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'aiAssisted': 'ai_assisted',
        'dishName': 'dish_name',
        'recipeId': 'recipe_id',
        'versionId': 'version_id',
      },
    );

Map<String, dynamic> _$SimilarRecipeToJson(SimilarRecipe instance) =>
    <String, dynamic>{
      'ai_assisted': instance.aiAssisted,
      'basis': instance.basis,
      'dish_name': instance.dishName,
      'recipe_id': instance.recipeId,
      'servings': instance.servings,
      'version_id': instance.versionId,
    };
