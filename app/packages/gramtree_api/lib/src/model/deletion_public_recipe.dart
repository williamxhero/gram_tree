//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deletion_public_recipe.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletionPublicRecipe {
  /// Returns a new [DeletionPublicRecipe] instance.
  DeletionPublicRecipe({
    required this.id,

    required this.publishedVersions,

    required this.title,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'published_versions', required: true, includeIfNull: false)
  final int publishedVersions;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletionPublicRecipe &&
          other.id == id &&
          other.publishedVersions == publishedVersions &&
          other.title == title;

  @override
  int get hashCode => id.hashCode + publishedVersions.hashCode + title.hashCode;

  factory DeletionPublicRecipe.fromJson(Map<String, dynamic> json) =>
      _$DeletionPublicRecipeFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionPublicRecipeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
