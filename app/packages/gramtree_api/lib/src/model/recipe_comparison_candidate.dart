//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_comparison_candidate.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeComparisonCandidate {
  /// Returns a new [RecipeComparisonCandidate] instance.
  RecipeComparisonCandidate({
    required this.aiAssisted,

    required this.author,

    this.baseVersionId,

    required this.changeNote,

    this.conclusion,

    required this.createdAt,

    required this.id,

    this.previousVersionId,

    required this.recipeId,

    this.rulesVersion,

    required this.versionNumber,
  });

  @JsonKey(name: r'ai_assisted', required: true, includeIfNull: false)
  final bool aiAssisted;

  @JsonKey(name: r'author', required: true, includeIfNull: false)
  final String author;

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(name: r'change_note', required: true, includeIfNull: false)
  final String changeNote;

  @JsonKey(name: r'conclusion', required: false, includeIfNull: false)
  final RecipeComparisonCandidateConclusionEnum? conclusion;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'previous_version_id', required: false, includeIfNull: false)
  final String? previousVersionId;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'rules_version', required: false, includeIfNull: false)
  final String? rulesVersion;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeComparisonCandidate &&
          other.aiAssisted == aiAssisted &&
          other.author == author &&
          other.baseVersionId == baseVersionId &&
          other.changeNote == changeNote &&
          other.conclusion == conclusion &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.previousVersionId == previousVersionId &&
          other.recipeId == recipeId &&
          other.rulesVersion == rulesVersion &&
          other.versionNumber == versionNumber;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      author.hashCode +
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      changeNote.hashCode +
      (conclusion == null ? 0 : conclusion.hashCode) +
      createdAt.hashCode +
      id.hashCode +
      (previousVersionId == null ? 0 : previousVersionId.hashCode) +
      recipeId.hashCode +
      (rulesVersion == null ? 0 : rulesVersion.hashCode) +
      versionNumber.hashCode;

  factory RecipeComparisonCandidate.fromJson(Map<String, dynamic> json) =>
      _$RecipeComparisonCandidateFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeComparisonCandidateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeComparisonCandidateConclusionEnum {
  @JsonValue(r'no_change')
  noChange(r'no_change'),
  @JsonValue(r'minor_only')
  minorOnly(r'minor_only'),
  @JsonValue(r'general')
  general(r'general'),
  @JsonValue(r'significant')
  significant(r'significant');

  const RecipeComparisonCandidateConclusionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
