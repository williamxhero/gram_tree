//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_version_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeVersionSummary {
  /// Returns a new [RecipeVersionSummary] instance.
  RecipeVersionSummary({
    required this.aiAssisted,

    this.baseVersionId,

    required this.changeNote,

    this.conclusion,

    required this.createdAt,

    required this.id,

    this.previousVersionId,

    this.rulesVersion,

    required this.versionNumber,
  });

  @JsonKey(name: r'ai_assisted', required: true, includeIfNull: false)
  final bool aiAssisted;

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(name: r'change_note', required: true, includeIfNull: false)
  final String changeNote;

  @JsonKey(name: r'conclusion', required: false, includeIfNull: false)
  final RecipeVersionSummaryConclusionEnum? conclusion;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'previous_version_id', required: false, includeIfNull: false)
  final String? previousVersionId;

  @JsonKey(name: r'rules_version', required: false, includeIfNull: false)
  final String? rulesVersion;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeVersionSummary &&
          other.aiAssisted == aiAssisted &&
          other.baseVersionId == baseVersionId &&
          other.changeNote == changeNote &&
          other.conclusion == conclusion &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.previousVersionId == previousVersionId &&
          other.rulesVersion == rulesVersion &&
          other.versionNumber == versionNumber;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      changeNote.hashCode +
      (conclusion == null ? 0 : conclusion.hashCode) +
      createdAt.hashCode +
      id.hashCode +
      (previousVersionId == null ? 0 : previousVersionId.hashCode) +
      (rulesVersion == null ? 0 : rulesVersion.hashCode) +
      versionNumber.hashCode;

  factory RecipeVersionSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeVersionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeVersionSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeVersionSummaryConclusionEnum {
  @JsonValue(r'no_change')
  noChange(r'no_change'),
  @JsonValue(r'minor_only')
  minorOnly(r'minor_only'),
  @JsonValue(r'general')
  general(r'general'),
  @JsonValue(r'significant')
  significant(r'significant');

  const RecipeVersionSummaryConclusionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
