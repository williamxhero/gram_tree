// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_mold_conversion_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeMoldConversionOutCWProxy {
  RecipeMoldConversionOut conversion(MoldConversion conversion);

  RecipeMoldConversionOut recipeId(String recipeId);

  RecipeMoldConversionOut versionId(String versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeMoldConversionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeMoldConversionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeMoldConversionOut call({
    MoldConversion conversion,
    String recipeId,
    String versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeMoldConversionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeMoldConversionOut.copyWith.fieldName(...)`
class _$RecipeMoldConversionOutCWProxyImpl
    implements _$RecipeMoldConversionOutCWProxy {
  const _$RecipeMoldConversionOutCWProxyImpl(this._value);

  final RecipeMoldConversionOut _value;

  @override
  RecipeMoldConversionOut conversion(MoldConversion conversion) =>
      this(conversion: conversion);

  @override
  RecipeMoldConversionOut recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  RecipeMoldConversionOut versionId(String versionId) =>
      this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeMoldConversionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeMoldConversionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeMoldConversionOut call({
    Object? conversion = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return RecipeMoldConversionOut(
      conversion: conversion == const $CopyWithPlaceholder()
          ? _value.conversion
          // ignore: cast_nullable_to_non_nullable
          : conversion as MoldConversion,
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

extension $RecipeMoldConversionOutCopyWith on RecipeMoldConversionOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeMoldConversionOut.copyWith(...)` or like so:`instanceOfRecipeMoldConversionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeMoldConversionOutCWProxy get copyWith =>
      _$RecipeMoldConversionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeMoldConversionOut _$RecipeMoldConversionOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeMoldConversionOut', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['conversion', 'recipe_id', 'version_id'],
  );
  final val = RecipeMoldConversionOut(
    conversion: $checkedConvert(
      'conversion',
      (v) => MoldConversion.fromJson(v as Map<String, dynamic>),
    ),
    recipeId: $checkedConvert('recipe_id', (v) => v as String),
    versionId: $checkedConvert('version_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'recipeId': 'recipe_id', 'versionId': 'version_id'});

Map<String, dynamic> _$RecipeMoldConversionOutToJson(
  RecipeMoldConversionOut instance,
) => <String, dynamic>{
  'conversion': instance.conversion.toJson(),
  'recipe_id': instance.recipeId,
  'version_id': instance.versionId,
};
