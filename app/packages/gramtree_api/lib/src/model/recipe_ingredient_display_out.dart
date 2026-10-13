//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_ingredient_display.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_ingredient_display_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeIngredientDisplayOut {
  /// Returns a new [RecipeIngredientDisplayOut] instance.
  RecipeIngredientDisplayOut({required this.display});

  @JsonKey(name: r'display', required: true, includeIfNull: false)
  final RecipeIngredientDisplay display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientDisplayOut && other.display == display;

  @override
  int get hashCode => display.hashCode;

  factory RecipeIngredientDisplayOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientDisplayOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeIngredientDisplayOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
