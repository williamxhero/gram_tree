//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_replacement_allergens.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeReplacementAllergens {
  /// Returns a new [RecipeReplacementAllergens] instance.
  RecipeReplacementAllergens({
    this.allergens,

    required this.displayName,

    this.incomplete = false,

    required this.ingredientId,
  });

  @JsonKey(name: r'allergens', required: false, includeIfNull: false)
  final List<String>? allergens;

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(
    defaultValue: false,
    name: r'incomplete',
    required: false,
    includeIfNull: false,
  )
  final bool? incomplete;

  /// 替代品所属的菜谱内食材 ID
  @JsonKey(name: r'ingredient_id', required: true, includeIfNull: false)
  final String ingredientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeReplacementAllergens &&
          other.allergens == allergens &&
          other.displayName == displayName &&
          other.incomplete == incomplete &&
          other.ingredientId == ingredientId;

  @override
  int get hashCode =>
      allergens.hashCode +
      displayName.hashCode +
      incomplete.hashCode +
      ingredientId.hashCode;

  factory RecipeReplacementAllergens.fromJson(Map<String, dynamic> json) =>
      _$RecipeReplacementAllergensFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeReplacementAllergensToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
