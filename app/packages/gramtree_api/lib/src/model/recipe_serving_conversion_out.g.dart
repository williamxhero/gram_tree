// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_serving_conversion_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeServingConversionOutCWProxy {
  RecipeServingConversionOut conversion(ServingConversion conversion);

  RecipeServingConversionOut recipeId(String recipeId);

  RecipeServingConversionOut versionId(String versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeServingConversionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeServingConversionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeServingConversionOut call({
    ServingConversion conversion,
    String recipeId,
    String versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeServingConversionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeServingConversionOut.copyWith.fieldName(...)`
class _$RecipeServingConversionOutCWProxyImpl
    implements _$RecipeServingConversionOutCWProxy {
  const _$RecipeServingConversionOutCWProxyImpl(this._value);

  final RecipeServingConversionOut _value;

  @override
  RecipeServingConversionOut conversion(ServingConversion conversion) =>
      this(conversion: conversion);

  @override
  RecipeServingConversionOut recipeId(String recipeId) =>
      this(recipeId: recipeId);

  @override
  RecipeServingConversionOut versionId(String versionId) =>
      this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeServingConversionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeServingConversionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeServingConversionOut call({
    Object? conversion = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return RecipeServingConversionOut(
      conversion: conversion == const $CopyWithPlaceholder()
          ? _value.conversion
          // ignore: cast_nullable_to_non_nullable
          : conversion as ServingConversion,
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

extension $RecipeServingConversionOutCopyWith on RecipeServingConversionOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeServingConversionOut.copyWith(...)` or like so:`instanceOfRecipeServingConversionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeServingConversionOutCWProxy get copyWith =>
      _$RecipeServingConversionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeServingConversionOut _$RecipeServingConversionOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeServingConversionOut', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['conversion', 'recipe_id', 'version_id'],
  );
  final val = RecipeServingConversionOut(
    conversion: $checkedConvert(
      'conversion',
      (v) => ServingConversion.fromJson(v as Map<String, dynamic>),
    ),
    recipeId: $checkedConvert('recipe_id', (v) => v as String),
    versionId: $checkedConvert('version_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'recipeId': 'recipe_id', 'versionId': 'version_id'});

Map<String, dynamic> _$RecipeServingConversionOutToJson(
  RecipeServingConversionOut instance,
) => <String, dynamic>{
  'conversion': instance.conversion.toJson(),
  'recipe_id': instance.recipeId,
  'version_id': instance.versionId,
};
