// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_share_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeShareLinkCWProxy {
  RecipeShareLink appPath(String appPath);

  RecipeShareLink shareId(String shareId);

  RecipeShareLink url(String url);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeShareLink(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeShareLink(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeShareLink call({String appPath, String shareId, String url});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeShareLink.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeShareLink.copyWith.fieldName(...)`
class _$RecipeShareLinkCWProxyImpl implements _$RecipeShareLinkCWProxy {
  const _$RecipeShareLinkCWProxyImpl(this._value);

  final RecipeShareLink _value;

  @override
  RecipeShareLink appPath(String appPath) => this(appPath: appPath);

  @override
  RecipeShareLink shareId(String shareId) => this(shareId: shareId);

  @override
  RecipeShareLink url(String url) => this(url: url);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeShareLink(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeShareLink(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeShareLink call({
    Object? appPath = const $CopyWithPlaceholder(),
    Object? shareId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return RecipeShareLink(
      appPath: appPath == const $CopyWithPlaceholder()
          ? _value.appPath
          // ignore: cast_nullable_to_non_nullable
          : appPath as String,
      shareId: shareId == const $CopyWithPlaceholder()
          ? _value.shareId
          // ignore: cast_nullable_to_non_nullable
          : shareId as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $RecipeShareLinkCopyWith on RecipeShareLink {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeShareLink.copyWith(...)` or like so:`instanceOfRecipeShareLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeShareLinkCWProxy get copyWith => _$RecipeShareLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeShareLink _$RecipeShareLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecipeShareLink', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['app_path', 'share_id', 'url']);
      final val = RecipeShareLink(
        appPath: $checkedConvert('app_path', (v) => v as String),
        shareId: $checkedConvert('share_id', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'appPath': 'app_path', 'shareId': 'share_id'});

Map<String, dynamic> _$RecipeShareLinkToJson(RecipeShareLink instance) =>
    <String, dynamic>{
      'app_path': instance.appPath,
      'share_id': instance.shareId,
      'url': instance.url,
    };
