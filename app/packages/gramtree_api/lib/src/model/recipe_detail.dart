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

    this.defaultServings,

    required this.dish,

    this.everPublic = false,

    required this.id,

    this.license = '菜谱内容按 CC BY-NC-SA 4.0 共享；成品图版权归上传者。',

    this.rootRecipeId,

    this.sourceAttribution,

    this.sourceLinks,

    this.sourceVersionId,

    this.tasteProfileVersion,

    required this.updatedAt,

    required this.version,

    required this.visibility,

    this.withdrawn = false,
  });

  @JsonKey(name: r'author', required: true, includeIfNull: false)
  final RecipeAuthor author;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'default_servings', required: false, includeIfNull: false)
  final int? defaultServings;

  @JsonKey(name: r'dish', required: true, includeIfNull: false)
  final DishOut dish;

  @JsonKey(
    defaultValue: false,
    name: r'ever_public',
    required: false,
    includeIfNull: false,
  )
  final bool? everPublic;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(
    defaultValue: '菜谱内容按 CC BY-NC-SA 4.0 共享；成品图版权归上传者。',
    name: r'license',
    required: false,
    includeIfNull: false,
  )
  final String? license;

  @JsonKey(name: r'root_recipe_id', required: false, includeIfNull: false)
  final String? rootRecipeId;

  @JsonKey(name: r'source_attribution', required: false, includeIfNull: false)
  final Object? sourceAttribution;

  @JsonKey(name: r'source_links', required: false, includeIfNull: false)
  final List<String>? sourceLinks;

  @JsonKey(name: r'source_version_id', required: false, includeIfNull: false)
  final String? sourceVersionId;

  @JsonKey(
    name: r'taste_profile_version',
    required: false,
    includeIfNull: false,
  )
  final int? tasteProfileVersion;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final String updatedAt;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final RecipeVersionOut version;

  @JsonKey(name: r'visibility', required: true, includeIfNull: false)
  final RecipeDetailVisibilityEnum visibility;

  @JsonKey(
    defaultValue: false,
    name: r'withdrawn',
    required: false,
    includeIfNull: false,
  )
  final bool? withdrawn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDetail &&
          other.author == author &&
          other.createdAt == createdAt &&
          other.defaultServings == defaultServings &&
          other.dish == dish &&
          other.everPublic == everPublic &&
          other.id == id &&
          other.license == license &&
          other.rootRecipeId == rootRecipeId &&
          other.sourceAttribution == sourceAttribution &&
          other.sourceLinks == sourceLinks &&
          other.sourceVersionId == sourceVersionId &&
          other.tasteProfileVersion == tasteProfileVersion &&
          other.updatedAt == updatedAt &&
          other.version == version &&
          other.visibility == visibility &&
          other.withdrawn == withdrawn;

  @override
  int get hashCode =>
      author.hashCode +
      createdAt.hashCode +
      (defaultServings == null ? 0 : defaultServings.hashCode) +
      dish.hashCode +
      everPublic.hashCode +
      id.hashCode +
      license.hashCode +
      (rootRecipeId == null ? 0 : rootRecipeId.hashCode) +
      (sourceAttribution == null ? 0 : sourceAttribution.hashCode) +
      sourceLinks.hashCode +
      (sourceVersionId == null ? 0 : sourceVersionId.hashCode) +
      (tasteProfileVersion == null ? 0 : tasteProfileVersion.hashCode) +
      updatedAt.hashCode +
      version.hashCode +
      visibility.hashCode +
      withdrawn.hashCode;

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
  private(r'private'),
  @JsonValue(r'public')
  public(r'public');

  const RecipeDetailVisibilityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
