//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:gramtree_api/src/model/recipe_derived.dart';
import 'package:gramtree_api/src/model/recipe_image_out.dart';
import 'package:gramtree_api/src/model/recipe_reproducibility_result.dart';
import 'package:gramtree_api/src/model/recipe_safety_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_version_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeVersionOut {
  /// Returns a new [RecipeVersionOut] instance.
  RecipeVersionOut({
    required this.aiAssisted,

    this.baseVersionId,

    required this.changeNote,

    this.conclusion,

    required this.createdAt,

    required this.derived,

    required this.editOperations,

    required this.id,

    this.images,

    this.previousVersionId,

    this.reproducibility,

    this.rulesVersion,

    this.safety,

    this.safetyAtSave,

    required this.snapshot,

    required this.versionNumber,
  });

  @JsonKey(name: r'ai_assisted', required: true, includeIfNull: false)
  final bool aiAssisted;

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(name: r'change_note', required: true, includeIfNull: false)
  final String changeNote;

  @JsonKey(name: r'conclusion', required: false, includeIfNull: false)
  final RecipeVersionOutConclusionEnum? conclusion;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'derived', required: true, includeIfNull: false)
  final RecipeDerived derived;

  @JsonKey(name: r'edit_operations', required: true, includeIfNull: false)
  final List<Object> editOperations;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'images', required: false, includeIfNull: false)
  final List<RecipeImageOut>? images;

  @JsonKey(name: r'previous_version_id', required: false, includeIfNull: false)
  final String? previousVersionId;

  @JsonKey(name: r'reproducibility', required: false, includeIfNull: false)
  final RecipeReproducibilityResult? reproducibility;

  @JsonKey(name: r'rules_version', required: false, includeIfNull: false)
  final String? rulesVersion;

  @JsonKey(name: r'safety', required: false, includeIfNull: false)
  final RecipeSafetyResult? safety;

  @JsonKey(name: r'safety_at_save', required: false, includeIfNull: false)
  final RecipeSafetyResult? safetyAtSave;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeVersionOut &&
          other.aiAssisted == aiAssisted &&
          other.baseVersionId == baseVersionId &&
          other.changeNote == changeNote &&
          other.conclusion == conclusion &&
          other.createdAt == createdAt &&
          other.derived == derived &&
          other.editOperations == editOperations &&
          other.id == id &&
          other.images == images &&
          other.previousVersionId == previousVersionId &&
          other.reproducibility == reproducibility &&
          other.rulesVersion == rulesVersion &&
          other.safety == safety &&
          other.safetyAtSave == safetyAtSave &&
          other.snapshot == snapshot &&
          other.versionNumber == versionNumber;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      changeNote.hashCode +
      (conclusion == null ? 0 : conclusion.hashCode) +
      createdAt.hashCode +
      derived.hashCode +
      editOperations.hashCode +
      id.hashCode +
      images.hashCode +
      (previousVersionId == null ? 0 : previousVersionId.hashCode) +
      reproducibility.hashCode +
      (rulesVersion == null ? 0 : rulesVersion.hashCode) +
      safety.hashCode +
      safetyAtSave.hashCode +
      snapshot.hashCode +
      versionNumber.hashCode;

  factory RecipeVersionOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeVersionOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeVersionOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeVersionOutConclusionEnum {
  @JsonValue(r'no_change')
  noChange(r'no_change'),
  @JsonValue(r'minor_only')
  minorOnly(r'minor_only'),
  @JsonValue(r'general')
  general(r'general'),
  @JsonValue(r'significant')
  significant(r'significant');

  const RecipeVersionOutConclusionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
