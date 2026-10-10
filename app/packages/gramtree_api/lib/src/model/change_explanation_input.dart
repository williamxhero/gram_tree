//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_explanation_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangeExplanationInput {
  /// Returns a new [ChangeExplanationInput] instance.
  ChangeExplanationInput({
    this.baseVersionId,

    this.generationRequestId,

    this.modificationId,

    this.recipeId,

    this.revision,

    this.snapshot,
  });

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(
    name: r'generation_request_id',
    required: false,
    includeIfNull: false,
  )
  final String? generationRequestId;

  @JsonKey(name: r'modification_id', required: false, includeIfNull: false)
  final String? modificationId;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  // minimum: 0
  @JsonKey(name: r'revision', required: false, includeIfNull: false)
  final int? revision;

  @JsonKey(name: r'snapshot', required: false, includeIfNull: false)
  final RecipeSnapshot? snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeExplanationInput &&
          other.baseVersionId == baseVersionId &&
          other.generationRequestId == generationRequestId &&
          other.modificationId == modificationId &&
          other.recipeId == recipeId &&
          other.revision == revision &&
          other.snapshot == snapshot;

  @override
  int get hashCode =>
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      (generationRequestId == null ? 0 : generationRequestId.hashCode) +
      (modificationId == null ? 0 : modificationId.hashCode) +
      (recipeId == null ? 0 : recipeId.hashCode) +
      (revision == null ? 0 : revision.hashCode) +
      snapshot.hashCode;

  factory ChangeExplanationInput.fromJson(Map<String, dynamic> json) =>
      _$ChangeExplanationInputFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeExplanationInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
