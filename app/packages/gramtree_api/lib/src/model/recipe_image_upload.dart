//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_image_upload.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeImageUpload {
  /// Returns a new [RecipeImageUpload] instance.
  RecipeImageUpload({
    required this.contentBase64,

    required this.contentType,

    this.filename,
  });

  @JsonKey(name: r'content_base64', required: true, includeIfNull: false)
  final String contentBase64;

  @JsonKey(name: r'content_type', required: true, includeIfNull: false)
  final String contentType;

  @JsonKey(name: r'filename', required: false, includeIfNull: false)
  final String? filename;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeImageUpload &&
          other.contentBase64 == contentBase64 &&
          other.contentType == contentType &&
          other.filename == filename;

  @override
  int get hashCode =>
      contentBase64.hashCode +
      contentType.hashCode +
      (filename == null ? 0 : filename.hashCode);

  factory RecipeImageUpload.fromJson(Map<String, dynamic> json) =>
      _$RecipeImageUploadFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeImageUploadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
