// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_share_target.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeShareTargetCWProxy {
  RecipeShareTarget appPath(String appPath);

  RecipeShareTarget recipeId(String recipeId);

  RecipeShareTarget shareId(String shareId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeShareTarget(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeShareTarget(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeShareTarget call({String appPath, String recipeId, String shareId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeShareTarget.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeShareTarget.copyWith.fieldName(...)`
class _$RecipeShareTargetCWProxyImpl implements _$RecipeShareTargetCWProxy {
  const _$RecipeShareTargetCWProxyImpl(this._value);

  final RecipeShareTarget _value;

  @override
  RecipeShareTarget appPath(String appPath) => this(appPath: appPath);

  @override
  RecipeShareTarget recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  RecipeShareTarget shareId(String shareId) => this(shareId: shareId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeShareTarget(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeShareTarget(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeShareTarget call({
    Object? appPath = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? shareId = const $CopyWithPlaceholder(),
  }) {
    return RecipeShareTarget(
      appPath: appPath == const $CopyWithPlaceholder()
          ? _value.appPath
          // ignore: cast_nullable_to_non_nullable
          : appPath as String,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      shareId: shareId == const $CopyWithPlaceholder()
          ? _value.shareId
          // ignore: cast_nullable_to_non_nullable
          : shareId as String,
    );
  }
}

extension $RecipeShareTargetCopyWith on RecipeShareTarget {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeShareTarget.copyWith(...)` or like so:`instanceOfRecipeShareTarget.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeShareTargetCWProxy get copyWith =>
      _$RecipeShareTargetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeShareTarget _$RecipeShareTargetFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeShareTarget',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['app_path', 'recipe_id', 'share_id'],
        );
        final val = RecipeShareTarget(
          appPath: $checkedConvert('app_path', (v) => v as String),
          recipeId: $checkedConvert('recipe_id', (v) => v as String),
          shareId: $checkedConvert('share_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'appPath': 'app_path',
        'recipeId': 'recipe_id',
        'shareId': 'share_id',
      },
    );

Map<String, dynamic> _$RecipeShareTargetToJson(RecipeShareTarget instance) =>
    <String, dynamic>{
      'app_path': instance.appPath,
      'recipe_id': instance.recipeId,
      'share_id': instance.shareId,
    };
