//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_replacement.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_ingredient_replacement.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeIngredientReplacement {
  /// Returns a new [RecipeIngredientReplacement] instance.
  RecipeIngredientReplacement({
    required this.displayName,

    required this.ingredientId,

    required this.note,

    this.ratio = 1,
  });

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(name: r'ingredient_id', required: true, includeIfNull: false)
  final String ingredientId;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  // maximum: 100.0
  @JsonKey(
    defaultValue: 1,
    name: r'ratio',
    required: false,
    includeIfNull: false,
  )
  final num? ratio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientReplacement &&
          other.displayName == displayName &&
          other.ingredientId == ingredientId &&
          other.note == note &&
          other.ratio == ratio;

  @override
  int get hashCode =>
      displayName.hashCode +
      ingredientId.hashCode +
      note.hashCode +
      ratio.hashCode;

  factory RecipeIngredientReplacement.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientReplacementFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeIngredientReplacementToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
