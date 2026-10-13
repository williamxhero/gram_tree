//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/reproducibility_problem.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_reproducibility_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeReproducibilityResult {
  /// Returns a new [RecipeReproducibilityResult] instance.
  RecipeReproducibilityResult({
    required this.concreteFieldCount,

    required this.fieldCompleteness,

    this.problems,

    required this.remainingCount,

    required this.requiredFieldCount,

    required this.rulesVersion,

    required this.state,
  });

  @JsonKey(name: r'concrete_field_count', required: true, includeIfNull: false)
  final int concreteFieldCount;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'field_completeness', required: true, includeIfNull: false)
  final num fieldCompleteness;

  @JsonKey(name: r'problems', required: false, includeIfNull: false)
  final List<ReproducibilityProblem>? problems;

  @JsonKey(name: r'remaining_count', required: true, includeIfNull: false)
  final int remainingCount;

  @JsonKey(name: r'required_field_count', required: true, includeIfNull: false)
  final int requiredFieldCount;

  @JsonKey(name: r'rules_version', required: true, includeIfNull: false)
  final String rulesVersion;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final RecipeReproducibilityResultStateEnum state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeReproducibilityResult &&
          other.concreteFieldCount == concreteFieldCount &&
          other.fieldCompleteness == fieldCompleteness &&
          other.problems == problems &&
          other.remainingCount == remainingCount &&
          other.requiredFieldCount == requiredFieldCount &&
          other.rulesVersion == rulesVersion &&
          other.state == state;

  @override
  int get hashCode =>
      concreteFieldCount.hashCode +
      fieldCompleteness.hashCode +
      problems.hashCode +
      remainingCount.hashCode +
      requiredFieldCount.hashCode +
      rulesVersion.hashCode +
      state.hashCode;

  factory RecipeReproducibilityResult.fromJson(Map<String, dynamic> json) =>
      _$RecipeReproducibilityResultFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeReproducibilityResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeReproducibilityResultStateEnum {
  @JsonValue(r'incomplete')
  incomplete(r'incomplete'),
  @JsonValue(r'reproducible')
  reproducible(r'reproducible');

  const RecipeReproducibilityResultStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
