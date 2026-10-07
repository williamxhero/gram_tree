//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'similar_recipe.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SimilarRecipe {
  /// Returns a new [SimilarRecipe] instance.
  SimilarRecipe({
    required this.aiAssisted,

    required this.basis,

    required this.dishName,

    required this.recipeId,

    required this.servings,

    required this.versionId,
  });

  @JsonKey(name: r'ai_assisted', required: true, includeIfNull: false)
  final bool aiAssisted;

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'dish_name', required: true, includeIfNull: false)
  final String dishName;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimilarRecipe &&
          other.aiAssisted == aiAssisted &&
          other.basis == basis &&
          other.dishName == dishName &&
          other.recipeId == recipeId &&
          other.servings == servings &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      basis.hashCode +
      dishName.hashCode +
      recipeId.hashCode +
      servings.hashCode +
      versionId.hashCode;

  factory SimilarRecipe.fromJson(Map<String, dynamic> json) =>
      _$SimilarRecipeFromJson(json);

  Map<String, dynamic> toJson() => _$SimilarRecipeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
