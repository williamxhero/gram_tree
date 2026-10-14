//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_preview_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementPreviewInput {
  /// Returns a new [ImprovementPreviewInput] instance.
  ImprovementPreviewInput({
    this.changeNote = '',

    this.explanationFingerprint,

    this.fromCookingRecordId,

    this.modificationRequestId,

    this.modificationRevision,

    this.snapshot,

    required this.sourceVersionId,
  });

  @JsonKey(
    defaultValue: '',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  @JsonKey(
    name: r'explanation_fingerprint',
    required: false,
    includeIfNull: false,
  )
  final String? explanationFingerprint;

  @JsonKey(
    name: r'from_cooking_record_id',
    required: false,
    includeIfNull: false,
  )
  final String? fromCookingRecordId;

  @JsonKey(
    name: r'modification_request_id',
    required: false,
    includeIfNull: false,
  )
  final String? modificationRequestId;

  // minimum: 0
  @JsonKey(
    name: r'modification_revision',
    required: false,
    includeIfNull: false,
  )
  final int? modificationRevision;

  @JsonKey(name: r'snapshot', required: false, includeIfNull: false)
  final RecipeSnapshot? snapshot;

  @JsonKey(name: r'source_version_id', required: true, includeIfNull: false)
  final String sourceVersionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementPreviewInput &&
          other.changeNote == changeNote &&
          other.explanationFingerprint == explanationFingerprint &&
          other.fromCookingRecordId == fromCookingRecordId &&
          other.modificationRequestId == modificationRequestId &&
          other.modificationRevision == modificationRevision &&
          other.snapshot == snapshot &&
          other.sourceVersionId == sourceVersionId;

  @override
  int get hashCode =>
      changeNote.hashCode +
      (explanationFingerprint == null ? 0 : explanationFingerprint.hashCode) +
      (fromCookingRecordId == null ? 0 : fromCookingRecordId.hashCode) +
      (modificationRequestId == null ? 0 : modificationRequestId.hashCode) +
      (modificationRevision == null ? 0 : modificationRevision.hashCode) +
      snapshot.hashCode +
      sourceVersionId.hashCode;

  factory ImprovementPreviewInput.fromJson(Map<String, dynamic> json) =>
      _$ImprovementPreviewInputFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementPreviewInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
