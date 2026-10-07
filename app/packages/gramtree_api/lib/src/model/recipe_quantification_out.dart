//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/quantification_suggestion.dart';
import 'package:gramtree_api/src/model/reproducibility_problem.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_quantification_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeQuantificationOut {
  /// Returns a new [RecipeQuantificationOut] instance.
  RecipeQuantificationOut({
    required this.baseVersionId,

    required this.id,

    required this.problems,

    required this.suggestions,
  });

  @JsonKey(name: r'base_version_id', required: true, includeIfNull: false)
  final String baseVersionId;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'problems', required: true, includeIfNull: false)
  final List<ReproducibilityProblem> problems;

  @JsonKey(name: r'suggestions', required: true, includeIfNull: false)
  final List<QuantificationSuggestion> suggestions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeQuantificationOut &&
          other.baseVersionId == baseVersionId &&
          other.id == id &&
          other.problems == problems &&
          other.suggestions == suggestions;

  @override
  int get hashCode =>
      baseVersionId.hashCode +
      id.hashCode +
      problems.hashCode +
      suggestions.hashCode;

  factory RecipeQuantificationOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeQuantificationOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeQuantificationOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
