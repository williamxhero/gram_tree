//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_image_staged_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeImageStagedOut {
  /// Returns a new [RecipeImageStagedOut] instance.
  RecipeImageStagedOut({
    required this.byteSize,

    required this.contentType,

    required this.expiresInSeconds,

    this.height,

    required this.id,

    required this.url,

    this.width,
  });

  @JsonKey(name: r'byte_size', required: true, includeIfNull: false)
  final int byteSize;

  @JsonKey(name: r'content_type', required: true, includeIfNull: false)
  final String contentType;

  @JsonKey(name: r'expires_in_seconds', required: true, includeIfNull: false)
  final int expiresInSeconds;

  @JsonKey(name: r'height', required: false, includeIfNull: false)
  final int? height;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @JsonKey(name: r'width', required: false, includeIfNull: false)
  final int? width;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeImageStagedOut &&
          other.byteSize == byteSize &&
          other.contentType == contentType &&
          other.expiresInSeconds == expiresInSeconds &&
          other.height == height &&
          other.id == id &&
          other.url == url &&
          other.width == width;

  @override
  int get hashCode =>
      byteSize.hashCode +
      contentType.hashCode +
      expiresInSeconds.hashCode +
      height.hashCode +
      id.hashCode +
      url.hashCode +
      width.hashCode;

  factory RecipeImageStagedOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeImageStagedOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeImageStagedOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
