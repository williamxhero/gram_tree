// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_image_staged_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeImageStagedOutCWProxy {
  RecipeImageStagedOut byteSize(int byteSize);

  RecipeImageStagedOut contentType(String contentType);

  RecipeImageStagedOut expiresInSeconds(int expiresInSeconds);

  RecipeImageStagedOut height(int? height);

  RecipeImageStagedOut id(String id);

  RecipeImageStagedOut url(String url);

  RecipeImageStagedOut width(int? width);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeImageStagedOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeImageStagedOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeImageStagedOut call({
    int byteSize,
    String contentType,
    int expiresInSeconds,
    int? height,
    String id,
    String url,
    int? width,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeImageStagedOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeImageStagedOut.copyWith.fieldName(...)`
class _$RecipeImageStagedOutCWProxyImpl
    implements _$RecipeImageStagedOutCWProxy {
  const _$RecipeImageStagedOutCWProxyImpl(this._value);

  final RecipeImageStagedOut _value;

  @override
  RecipeImageStagedOut byteSize(int byteSize) => this(byteSize: byteSize);

  @override
  RecipeImageStagedOut contentType(String contentType) =>
      this(contentType: contentType);

  @override
  RecipeImageStagedOut expiresInSeconds(int expiresInSeconds) =>
      this(expiresInSeconds: expiresInSeconds);

  @override
  RecipeImageStagedOut height(int? height) => this(height: height);

  @override
  RecipeImageStagedOut id(String id) => this(id: id);

  @override
  RecipeImageStagedOut url(String url) => this(url: url);

  @override
  RecipeImageStagedOut width(int? width) => this(width: width);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeImageStagedOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeImageStagedOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeImageStagedOut call({
    Object? byteSize = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? expiresInSeconds = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
  }) {
    return RecipeImageStagedOut(
      byteSize: byteSize == const $CopyWithPlaceholder()
          ? _value.byteSize
          // ignore: cast_nullable_to_non_nullable
          : byteSize as int,
      contentType: contentType == const $CopyWithPlaceholder()
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as String,
      expiresInSeconds: expiresInSeconds == const $CopyWithPlaceholder()
          ? _value.expiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : expiresInSeconds as int,
      height: height == const $CopyWithPlaceholder()
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as int?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      width: width == const $CopyWithPlaceholder()
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as int?,
    );
  }
}

extension $RecipeImageStagedOutCopyWith on RecipeImageStagedOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeImageStagedOut.copyWith(...)` or like so:`instanceOfRecipeImageStagedOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeImageStagedOutCWProxy get copyWith =>
      _$RecipeImageStagedOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeImageStagedOut _$RecipeImageStagedOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeImageStagedOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'byte_size',
        'content_type',
        'expires_in_seconds',
        'id',
        'url',
      ],
    );
    final val = RecipeImageStagedOut(
      byteSize: $checkedConvert('byte_size', (v) => (v as num).toInt()),
      contentType: $checkedConvert('content_type', (v) => v as String),
      expiresInSeconds: $checkedConvert(
        'expires_in_seconds',
        (v) => (v as num).toInt(),
      ),
      height: $checkedConvert('height', (v) => (v as num?)?.toInt()),
      id: $checkedConvert('id', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      width: $checkedConvert('width', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'byteSize': 'byte_size',
    'contentType': 'content_type',
    'expiresInSeconds': 'expires_in_seconds',
  },
);

Map<String, dynamic> _$RecipeImageStagedOutToJson(
  RecipeImageStagedOut instance,
) => <String, dynamic>{
  'byte_size': instance.byteSize,
  'content_type': instance.contentType,
  'expires_in_seconds': instance.expiresInSeconds,
  'height': ?instance.height,
  'id': instance.id,
  'url': instance.url,
  'width': ?instance.width,
};
