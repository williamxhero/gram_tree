//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/comparison_change.dart';
import 'package:gramtree_api/src/model/comparison_version.dart';
import 'package:gramtree_api/src/model/ingredient_comparison_row.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_ingredient_comparison.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeIngredientComparison {
  /// Returns a new [RecipeIngredientComparison] instance.
  RecipeIngredientComparison({
    required this.fromVersion,

    required this.ingredients,

    required this.normalizedServings,

    required this.scope,

    this.snapshotFields,

    required this.toVersion,
  });

  @JsonKey(name: r'from_version', required: true, includeIfNull: false)
  final ComparisonVersion fromVersion;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<IngredientComparisonRow> ingredients;

  @JsonKey(name: r'normalized_servings', required: true, includeIfNull: false)
  final int normalizedServings;

  @JsonKey(name: r'scope', required: true, includeIfNull: false)
  final RecipeIngredientComparisonScopeEnum scope;

  @JsonKey(name: r'snapshot_fields', required: false, includeIfNull: false)
  final List<ComparisonChange>? snapshotFields;

  @JsonKey(name: r'to_version', required: true, includeIfNull: false)
  final ComparisonVersion toVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientComparison &&
          other.fromVersion == fromVersion &&
          other.ingredients == ingredients &&
          other.normalizedServings == normalizedServings &&
          other.scope == scope &&
          other.snapshotFields == snapshotFields &&
          other.toVersion == toVersion;

  @override
  int get hashCode =>
      fromVersion.hashCode +
      ingredients.hashCode +
      normalizedServings.hashCode +
      scope.hashCode +
      snapshotFields.hashCode +
      toVersion.hashCode;

  factory RecipeIngredientComparison.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientComparisonFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeIngredientComparisonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeIngredientComparisonScopeEnum {
  @JsonValue(r'ingredients')
  ingredients(r'ingredients');

  const RecipeIngredientComparisonScopeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
