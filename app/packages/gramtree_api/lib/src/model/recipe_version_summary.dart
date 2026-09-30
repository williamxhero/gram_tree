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

    required this.changeNote,

    required this.createdAt,

    required this.id,

    this.previousVersionId,

    required this.versionNumber,
  });

  @JsonKey(name: r'ai_assisted', required: true, includeIfNull: false)
  final bool aiAssisted;

  @JsonKey(name: r'change_note', required: true, includeIfNull: false)
  final String changeNote;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'previous_version_id', required: false, includeIfNull: false)
  final String? previousVersionId;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeVersionSummary &&
          other.aiAssisted == aiAssisted &&
          other.changeNote == changeNote &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.previousVersionId == previousVersionId &&
          other.versionNumber == versionNumber;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      changeNote.hashCode +
      createdAt.hashCode +
      id.hashCode +
      (previousVersionId == null ? 0 : previousVersionId.hashCode) +
      versionNumber.hashCode;

  factory RecipeVersionSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeVersionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeVersionSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
