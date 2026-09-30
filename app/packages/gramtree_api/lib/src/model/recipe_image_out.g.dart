// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_image_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeImageOutCWProxy {
  RecipeImageOut byteSize(int byteSize);

  RecipeImageOut contentType(String contentType);

  RecipeImageOut expiresInSeconds(int expiresInSeconds);

  RecipeImageOut height(int? height);

  RecipeImageOut id(String id);

  RecipeImageOut url(String url);

  RecipeImageOut versionId(String versionId);

  RecipeImageOut width(int? width);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeImageOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeImageOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeImageOut call({
    int byteSize,
    String contentType,
    int expiresInSeconds,
    int? height,
    String id,
    String url,
    String versionId,
    int? width,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeImageOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeImageOut.copyWith.fieldName(...)`
class _$RecipeImageOutCWProxyImpl implements _$RecipeImageOutCWProxy {
  const _$RecipeImageOutCWProxyImpl(this._value);

  final RecipeImageOut _value;

  @override
  RecipeImageOut byteSize(int byteSize) => this(byteSize: byteSize);

  @override
  RecipeImageOut contentType(String contentType) =>
      this(contentType: contentType);

  @override
  RecipeImageOut expiresInSeconds(int expiresInSeconds) =>
      this(expiresInSeconds: expiresInSeconds);

  @override
  RecipeImageOut height(int? height) => this(height: height);

  @override
  RecipeImageOut id(String id) => this(id: id);

  @override
  RecipeImageOut url(String url) => this(url: url);

  @override
  RecipeImageOut versionId(String versionId) => this(versionId: versionId);

  @override
  RecipeImageOut width(int? width) => this(width: width);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeImageOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeImageOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeImageOut call({
    Object? byteSize = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? expiresInSeconds = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
  }) {
    return RecipeImageOut(
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
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
      width: width == const $CopyWithPlaceholder()
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as int?,
    );
  }
}

extension $RecipeImageOutCopyWith on RecipeImageOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeImageOut.copyWith(...)` or like so:`instanceOfRecipeImageOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeImageOutCWProxy get copyWith => _$RecipeImageOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeImageOut _$RecipeImageOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeImageOut',
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
            'version_id',
          ],
        );
        final val = RecipeImageOut(
          byteSize: $checkedConvert('byte_size', (v) => (v as num).toInt()),
          contentType: $checkedConvert('content_type', (v) => v as String),
          expiresInSeconds: $checkedConvert(
            'expires_in_seconds',
            (v) => (v as num).toInt(),
          ),
          height: $checkedConvert('height', (v) => (v as num?)?.toInt()),
          id: $checkedConvert('id', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          versionId: $checkedConvert('version_id', (v) => v as String),
          width: $checkedConvert('width', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'byteSize': 'byte_size',
        'contentType': 'content_type',
        'expiresInSeconds': 'expires_in_seconds',
        'versionId': 'version_id',
      },
    );

Map<String, dynamic> _$RecipeImageOutToJson(RecipeImageOut instance) =>
    <String, dynamic>{
      'byte_size': instance.byteSize,
      'content_type': instance.contentType,
      'expires_in_seconds': instance.expiresInSeconds,
      'height': ?instance.height,
      'id': instance.id,
      'url': instance.url,
      'version_id': instance.versionId,
      'width': ?instance.width,
    };
