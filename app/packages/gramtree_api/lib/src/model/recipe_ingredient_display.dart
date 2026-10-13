//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_displayed_ingredient.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_ingredient_display.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeIngredientDisplay {
  /// Returns a new [RecipeIngredientDisplay] instance.
  RecipeIngredientDisplay({
    required this.ingredients,

    this.measureId,

    required this.mode,

    required this.recipeId,

    required this.versionId,
  });

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<RecipeDisplayedIngredient> ingredients;

  @JsonKey(name: r'measure_id', required: false, includeIfNull: false)
  final String? measureId;

  @JsonKey(name: r'mode', required: true, includeIfNull: false)
  final RecipeIngredientDisplayModeEnum mode;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientDisplay &&
          other.ingredients == ingredients &&
          other.measureId == measureId &&
          other.mode == mode &&
          other.recipeId == recipeId &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      ingredients.hashCode +
      (measureId == null ? 0 : measureId.hashCode) +
      mode.hashCode +
      recipeId.hashCode +
      versionId.hashCode;

  factory RecipeIngredientDisplay.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientDisplayFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeIngredientDisplayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeIngredientDisplayModeEnum {
  @JsonValue(r'base')
  base_(r'base'),
  @JsonValue(r'standard')
  standard(r'standard'),
  @JsonValue(r'home')
  home(r'home');

  const RecipeIngredientDisplayModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
