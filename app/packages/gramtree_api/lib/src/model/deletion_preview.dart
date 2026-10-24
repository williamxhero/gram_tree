//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/deletion_public_recipe.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deletion_preview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletionPreview {
  /// Returns a new [DeletionPreview] instance.
  DeletionPreview({
    required this.canExport,

    required this.deletes,

    required this.publicRecipeActionRequired,

    required this.publicRecipes,

    required this.retains,
  });

  @JsonKey(name: r'can_export', required: true, includeIfNull: false)
  final bool canExport;

  @JsonKey(name: r'deletes', required: true, includeIfNull: false)
  final List<String> deletes;

  @JsonKey(
    name: r'public_recipe_action_required',
    required: true,
    includeIfNull: false,
  )
  final bool publicRecipeActionRequired;

  @JsonKey(name: r'public_recipes', required: true, includeIfNull: false)
  final List<DeletionPublicRecipe> publicRecipes;

  @JsonKey(name: r'retains', required: true, includeIfNull: false)
  final List<String> retains;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletionPreview &&
          other.canExport == canExport &&
          other.deletes == deletes &&
          other.publicRecipeActionRequired == publicRecipeActionRequired &&
          other.publicRecipes == publicRecipes &&
          other.retains == retains;

  @override
  int get hashCode =>
      canExport.hashCode +
      deletes.hashCode +
      publicRecipeActionRequired.hashCode +
      publicRecipes.hashCode +
      retains.hashCode;

  factory DeletionPreview.fromJson(Map<String, dynamic> json) =>
      _$DeletionPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
