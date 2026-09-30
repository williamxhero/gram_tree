//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/dish_out.dart';
import 'package:gramtree_api/src/model/recipe_author.dart';
import 'package:gramtree_api/src/model/recipe_version_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeDetail {
  /// Returns a new [RecipeDetail] instance.
  RecipeDetail({
    required this.author,

    required this.createdAt,

    required this.dish,

    required this.id,

    this.rootRecipeId,

    this.sourceVersionId,

    required this.updatedAt,

    required this.version,

    required this.visibility,
  });

  @JsonKey(name: r'author', required: true, includeIfNull: false)
  final RecipeAuthor author;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'dish', required: true, includeIfNull: false)
  final DishOut dish;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'root_recipe_id', required: false, includeIfNull: false)
  final String? rootRecipeId;

  @JsonKey(name: r'source_version_id', required: false, includeIfNull: false)
  final String? sourceVersionId;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final String updatedAt;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final RecipeVersionOut version;

  @JsonKey(name: r'visibility', required: true, includeIfNull: false)
  final RecipeDetailVisibilityEnum visibility;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDetail &&
          other.author == author &&
          other.createdAt == createdAt &&
          other.dish == dish &&
          other.id == id &&
          other.rootRecipeId == rootRecipeId &&
          other.sourceVersionId == sourceVersionId &&
          other.updatedAt == updatedAt &&
          other.version == version &&
          other.visibility == visibility;

  @override
  int get hashCode =>
      author.hashCode +
      createdAt.hashCode +
      dish.hashCode +
      id.hashCode +
      rootRecipeId.hashCode +
      sourceVersionId.hashCode +
      updatedAt.hashCode +
      version.hashCode +
      visibility.hashCode;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeDetailVisibilityEnum {
  @JsonValue(r'private')
  private(r'private');

  const RecipeDetailVisibilityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
