//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_recipe_projection.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicRecipeProjection {
  /// Returns a new [PublicRecipeProjection] instance.
  PublicRecipeProjection({
    required this.description,

    required this.imageUrl,

    required this.license,

    required this.nickname,

    required this.photoRights,

    required this.title,
  });

  @JsonKey(name: r'description', required: true, includeIfNull: false)
  final String description;

  @JsonKey(name: r'image_url', required: true, includeIfNull: true)
  final String? imageUrl;

  @JsonKey(name: r'license', required: true, includeIfNull: false)
  final String license;

  @JsonKey(name: r'nickname', required: true, includeIfNull: false)
  final String nickname;

  @JsonKey(name: r'photo_rights', required: true, includeIfNull: false)
  final String photoRights;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicRecipeProjection &&
          other.description == description &&
          other.imageUrl == imageUrl &&
          other.license == license &&
          other.nickname == nickname &&
          other.photoRights == photoRights &&
          other.title == title;

  @override
  int get hashCode =>
      description.hashCode +
      (imageUrl == null ? 0 : imageUrl.hashCode) +
      license.hashCode +
      nickname.hashCode +
      photoRights.hashCode +
      title.hashCode;

  factory PublicRecipeProjection.fromJson(Map<String, dynamic> json) =>
      _$PublicRecipeProjectionFromJson(json);

  Map<String, dynamic> toJson() => _$PublicRecipeProjectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
