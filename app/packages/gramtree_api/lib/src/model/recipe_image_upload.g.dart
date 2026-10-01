// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_image_upload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeImageUploadCWProxy {
  RecipeImageUpload contentBase64(String contentBase64);

  RecipeImageUpload contentType(String contentType);

  RecipeImageUpload filename(String? filename);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeImageUpload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeImageUpload(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeImageUpload call({
    String contentBase64,
    String contentType,
    String? filename,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeImageUpload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeImageUpload.copyWith.fieldName(...)`
class _$RecipeImageUploadCWProxyImpl implements _$RecipeImageUploadCWProxy {
  const _$RecipeImageUploadCWProxyImpl(this._value);

  final RecipeImageUpload _value;

  @override
  RecipeImageUpload contentBase64(String contentBase64) =>
      this(contentBase64: contentBase64);

  @override
  RecipeImageUpload contentType(String contentType) =>
      this(contentType: contentType);

  @override
  RecipeImageUpload filename(String? filename) => this(filename: filename);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeImageUpload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeImageUpload(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeImageUpload call({
    Object? contentBase64 = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? filename = const $CopyWithPlaceholder(),
  }) {
    return RecipeImageUpload(
      contentBase64: contentBase64 == const $CopyWithPlaceholder()
          ? _value.contentBase64
          // ignore: cast_nullable_to_non_nullable
          : contentBase64 as String,
      contentType: contentType == const $CopyWithPlaceholder()
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as String,
      filename: filename == const $CopyWithPlaceholder()
          ? _value.filename
          // ignore: cast_nullable_to_non_nullable
          : filename as String?,
    );
  }
}

extension $RecipeImageUploadCopyWith on RecipeImageUpload {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeImageUpload.copyWith(...)` or like so:`instanceOfRecipeImageUpload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeImageUploadCWProxy get copyWith =>
      _$RecipeImageUploadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeImageUpload _$RecipeImageUploadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeImageUpload',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['content_base64', 'content_type'],
        );
        final val = RecipeImageUpload(
          contentBase64: $checkedConvert('content_base64', (v) => v as String),
          contentType: $checkedConvert('content_type', (v) => v as String),
          filename: $checkedConvert('filename', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'contentBase64': 'content_base64',
        'contentType': 'content_type',
      },
    );

Map<String, dynamic> _$RecipeImageUploadToJson(RecipeImageUpload instance) =>
    <String, dynamic>{
      'content_base64': instance.contentBase64,
      'content_type': instance.contentType,
      'filename': ?instance.filename,
    };
