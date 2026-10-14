// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_recipe_projection.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicRecipeProjectionCWProxy {
  PublicRecipeProjection description(String description);

  PublicRecipeProjection imageUrl(String? imageUrl);

  PublicRecipeProjection license(String license);

  PublicRecipeProjection nickname(String nickname);

  PublicRecipeProjection photoRights(String photoRights);

  PublicRecipeProjection title(String title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicRecipeProjection(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicRecipeProjection(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicRecipeProjection call({
    String description,
    String? imageUrl,
    String license,
    String nickname,
    String photoRights,
    String title,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicRecipeProjection.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicRecipeProjection.copyWith.fieldName(...)`
class _$PublicRecipeProjectionCWProxyImpl
    implements _$PublicRecipeProjectionCWProxy {
  const _$PublicRecipeProjectionCWProxyImpl(this._value);

  final PublicRecipeProjection _value;

  @override
  PublicRecipeProjection description(String description) =>
      this(description: description);

  @override
  PublicRecipeProjection imageUrl(String? imageUrl) => this(imageUrl: imageUrl);

  @override
  PublicRecipeProjection license(String license) => this(license: license);

  @override
  PublicRecipeProjection nickname(String nickname) => this(nickname: nickname);

  @override
  PublicRecipeProjection photoRights(String photoRights) =>
      this(photoRights: photoRights);

  @override
  PublicRecipeProjection title(String title) => this(title: title);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicRecipeProjection(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicRecipeProjection(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicRecipeProjection call({
    Object? description = const $CopyWithPlaceholder(),
    Object? imageUrl = const $CopyWithPlaceholder(),
    Object? license = const $CopyWithPlaceholder(),
    Object? nickname = const $CopyWithPlaceholder(),
    Object? photoRights = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return PublicRecipeProjection(
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      imageUrl: imageUrl == const $CopyWithPlaceholder()
          ? _value.imageUrl
          // ignore: cast_nullable_to_non_nullable
          : imageUrl as String?,
      license: license == const $CopyWithPlaceholder()
          ? _value.license
          // ignore: cast_nullable_to_non_nullable
          : license as String,
      nickname: nickname == const $CopyWithPlaceholder()
          ? _value.nickname
          // ignore: cast_nullable_to_non_nullable
          : nickname as String,
      photoRights: photoRights == const $CopyWithPlaceholder()
          ? _value.photoRights
          // ignore: cast_nullable_to_non_nullable
          : photoRights as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $PublicRecipeProjectionCopyWith on PublicRecipeProjection {
  /// Returns a callable class that can be used as follows: `instanceOfPublicRecipeProjection.copyWith(...)` or like so:`instanceOfPublicRecipeProjection.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicRecipeProjectionCWProxy get copyWith =>
      _$PublicRecipeProjectionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicRecipeProjection _$PublicRecipeProjectionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicRecipeProjection', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'description',
      'image_url',
      'license',
      'nickname',
      'photo_rights',
      'title',
    ],
  );
  final val = PublicRecipeProjection(
    description: $checkedConvert('description', (v) => v as String),
    imageUrl: $checkedConvert('image_url', (v) => v as String?),
    license: $checkedConvert('license', (v) => v as String),
    nickname: $checkedConvert('nickname', (v) => v as String),
    photoRights: $checkedConvert('photo_rights', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'imageUrl': 'image_url', 'photoRights': 'photo_rights'});

Map<String, dynamic> _$PublicRecipeProjectionToJson(
  PublicRecipeProjection instance,
) => <String, dynamic>{
  'description': instance.description,
  'image_url': instance.imageUrl,
  'license': instance.license,
  'nickname': instance.nickname,
  'photo_rights': instance.photoRights,
  'title': instance.title,
};
