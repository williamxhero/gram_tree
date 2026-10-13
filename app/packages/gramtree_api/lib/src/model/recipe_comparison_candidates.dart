//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_comparison_candidate.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_comparison_candidates.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeComparisonCandidates {
  /// Returns a new [RecipeComparisonCandidates] instance.
  RecipeComparisonCandidates({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<RecipeComparisonCandidate> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeComparisonCandidates &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory RecipeComparisonCandidates.fromJson(Map<String, dynamic> json) =>
      _$RecipeComparisonCandidatesFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeComparisonCandidatesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
