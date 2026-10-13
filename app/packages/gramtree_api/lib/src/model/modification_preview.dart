//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ai_status.dart';
import 'package:gramtree_api/src/model/modification_intent.dart';
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:gramtree_api/src/model/modification_decision_out.dart';
import 'package:gramtree_api/src/model/recipe_reproducibility_result.dart';
import 'package:gramtree_api/src/model/recipe_safety_result.dart';
import 'package:gramtree_api/src/model/modification_operation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_preview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationPreview {
  /// Returns a new [ModificationPreview] instance.
  ModificationPreview({
    this.baseVersionId,

    this.decisions,

    this.error,

    this.generationRequestId,

    required this.id,

    this.intent,

    this.operations,

    this.recipeId,

    required this.reproducibility,

    required this.revision,

    required this.safety,

    required this.snapshot,

    required this.status,

    this.warnings,
  });

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(name: r'decisions', required: false, includeIfNull: false)
  final List<ModificationDecisionOut>? decisions;

  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @JsonKey(
    name: r'generation_request_id',
    required: false,
    includeIfNull: false,
  )
  final String? generationRequestId;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'intent', required: false, includeIfNull: false)
  final ModificationIntent? intent;

  @JsonKey(name: r'operations', required: false, includeIfNull: false)
  final List<ModificationOperation>? operations;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @JsonKey(name: r'reproducibility', required: true, includeIfNull: false)
  final RecipeReproducibilityResult reproducibility;

  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final int revision;

  @JsonKey(name: r'safety', required: true, includeIfNull: false)
  final RecipeSafetyResult safety;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AIStatus status;

  @JsonKey(name: r'warnings', required: false, includeIfNull: false)
  final List<String>? warnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationPreview &&
          other.baseVersionId == baseVersionId &&
          other.decisions == decisions &&
          other.error == error &&
          other.generationRequestId == generationRequestId &&
          other.id == id &&
          other.intent == intent &&
          other.operations == operations &&
          other.recipeId == recipeId &&
          other.reproducibility == reproducibility &&
          other.revision == revision &&
          other.safety == safety &&
          other.snapshot == snapshot &&
          other.status == status &&
          other.warnings == warnings;

  @override
  int get hashCode =>
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      decisions.hashCode +
      (error == null ? 0 : error.hashCode) +
      (generationRequestId == null ? 0 : generationRequestId.hashCode) +
      id.hashCode +
      intent.hashCode +
      operations.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode) +
      reproducibility.hashCode +
      revision.hashCode +
      safety.hashCode +
      snapshot.hashCode +
      status.hashCode +
      warnings.hashCode;

  factory ModificationPreview.fromJson(Map<String, dynamic> json) =>
      _$ModificationPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
