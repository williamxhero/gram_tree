//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/graded_ingredient_comparison_row.dart';
import 'package:gramtree_api/src/model/comparison_version.dart';
import 'package:gramtree_api/src/model/graded_comparison_change.dart';
import 'package:gramtree_api/src/model/step_comparison_row.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_full_comparison.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeFullComparison {
  /// Returns a new [RecipeFullComparison] instance.
  RecipeFullComparison({
    required this.basis,

    required this.conclusion,

    required this.fromVersion,

    required this.ingredients,

    required this.methodChanges,

    required this.normalizedServings,

    required this.rulesVersion,

    required this.scope,

    required this.snapshotFields,

    required this.steps,

    required this.toVersion,
  });

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final List<String> basis;

  @JsonKey(name: r'conclusion', required: true, includeIfNull: false)
  final RecipeFullComparisonConclusionEnum conclusion;

  @JsonKey(name: r'from_version', required: true, includeIfNull: false)
  final ComparisonVersion fromVersion;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<GradedIngredientComparisonRow> ingredients;

  @JsonKey(name: r'method_changes', required: true, includeIfNull: false)
  final List<GradedComparisonChange> methodChanges;

  @JsonKey(name: r'normalized_servings', required: true, includeIfNull: false)
  final int normalizedServings;

  @JsonKey(name: r'rules_version', required: true, includeIfNull: false)
  final String rulesVersion;

  @JsonKey(name: r'scope', required: true, includeIfNull: false)
  final RecipeFullComparisonScopeEnum scope;

  @JsonKey(name: r'snapshot_fields', required: true, includeIfNull: false)
  final List<GradedComparisonChange> snapshotFields;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<StepComparisonRow> steps;

  @JsonKey(name: r'to_version', required: true, includeIfNull: false)
  final ComparisonVersion toVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeFullComparison &&
          other.basis == basis &&
          other.conclusion == conclusion &&
          other.fromVersion == fromVersion &&
          other.ingredients == ingredients &&
          other.methodChanges == methodChanges &&
          other.normalizedServings == normalizedServings &&
          other.rulesVersion == rulesVersion &&
          other.scope == scope &&
          other.snapshotFields == snapshotFields &&
          other.steps == steps &&
          other.toVersion == toVersion;

  @override
  int get hashCode =>
      basis.hashCode +
      conclusion.hashCode +
      fromVersion.hashCode +
      ingredients.hashCode +
      methodChanges.hashCode +
      normalizedServings.hashCode +
      rulesVersion.hashCode +
      scope.hashCode +
      snapshotFields.hashCode +
      steps.hashCode +
      toVersion.hashCode;

  factory RecipeFullComparison.fromJson(Map<String, dynamic> json) =>
      _$RecipeFullComparisonFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeFullComparisonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeFullComparisonConclusionEnum {
  @JsonValue(r'no_change')
  noChange(r'no_change'),
  @JsonValue(r'minor_only')
  minorOnly(r'minor_only'),
  @JsonValue(r'general')
  general(r'general'),
  @JsonValue(r'significant')
  significant(r'significant');

  const RecipeFullComparisonConclusionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecipeFullComparisonScopeEnum {
  @JsonValue(r'full')
  full(r'full');

  const RecipeFullComparisonScopeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
