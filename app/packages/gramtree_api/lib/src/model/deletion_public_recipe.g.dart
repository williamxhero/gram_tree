// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_public_recipe.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletionPublicRecipeCWProxy {
  DeletionPublicRecipe id(String id);

  DeletionPublicRecipe publishedVersions(int publishedVersions);

  DeletionPublicRecipe title(String title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionPublicRecipe(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionPublicRecipe(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionPublicRecipe call({String id, int publishedVersions, String title});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletionPublicRecipe.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletionPublicRecipe.copyWith.fieldName(...)`
class _$DeletionPublicRecipeCWProxyImpl
    implements _$DeletionPublicRecipeCWProxy {
  const _$DeletionPublicRecipeCWProxyImpl(this._value);

  final DeletionPublicRecipe _value;

  @override
  DeletionPublicRecipe id(String id) => this(id: id);

  @override
  DeletionPublicRecipe publishedVersions(int publishedVersions) =>
      this(publishedVersions: publishedVersions);

  @override
  DeletionPublicRecipe title(String title) => this(title: title);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionPublicRecipe(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionPublicRecipe(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionPublicRecipe call({
    Object? id = const $CopyWithPlaceholder(),
    Object? publishedVersions = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return DeletionPublicRecipe(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      publishedVersions: publishedVersions == const $CopyWithPlaceholder()
          ? _value.publishedVersions
          // ignore: cast_nullable_to_non_nullable
          : publishedVersions as int,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $DeletionPublicRecipeCopyWith on DeletionPublicRecipe {
  /// Returns a callable class that can be used as follows: `instanceOfDeletionPublicRecipe.copyWith(...)` or like so:`instanceOfDeletionPublicRecipe.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletionPublicRecipeCWProxy get copyWith =>
      _$DeletionPublicRecipeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletionPublicRecipe _$DeletionPublicRecipeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeletionPublicRecipe', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'published_versions', 'title']);
  final val = DeletionPublicRecipe(
    id: $checkedConvert('id', (v) => v as String),
    publishedVersions: $checkedConvert(
      'published_versions',
      (v) => (v as num).toInt(),
    ),
    title: $checkedConvert('title', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'publishedVersions': 'published_versions'});

Map<String, dynamic> _$DeletionPublicRecipeToJson(
  DeletionPublicRecipe instance,
) => <String, dynamic>{
  'id': instance.id,
  'published_versions': instance.publishedVersions,
  'title': instance.title,
};
