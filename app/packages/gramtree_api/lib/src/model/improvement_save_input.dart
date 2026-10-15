//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_save_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementSaveInput {
  /// Returns a new [ImprovementSaveInput] instance.
  ImprovementSaveInput({
    this.changeNote = '',

    this.expectedProfileVersion,

    this.explanationFingerprint,

    this.fromCookingRecordId,

    this.microadjustChoice,

    this.modificationRequestId,

    this.modificationRevision,

    required this.requestId,

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

  // minimum: 1
  @JsonKey(
    name: r'expected_profile_version',
    required: false,
    includeIfNull: false,
  )
  final int? expectedProfileVersion;

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

  @JsonKey(name: r'microadjust_choice', required: false, includeIfNull: false)
  final ImprovementSaveInputMicroadjustChoiceEnum? microadjustChoice;

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

  @JsonKey(name: r'request_id', required: true, includeIfNull: false)
  final String requestId;

  @JsonKey(name: r'snapshot', required: false, includeIfNull: false)
  final RecipeSnapshot? snapshot;

  @JsonKey(name: r'source_version_id', required: true, includeIfNull: false)
  final String sourceVersionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementSaveInput &&
          other.changeNote == changeNote &&
          other.expectedProfileVersion == expectedProfileVersion &&
          other.explanationFingerprint == explanationFingerprint &&
          other.fromCookingRecordId == fromCookingRecordId &&
          other.microadjustChoice == microadjustChoice &&
          other.modificationRequestId == modificationRequestId &&
          other.modificationRevision == modificationRevision &&
          other.requestId == requestId &&
          other.snapshot == snapshot &&
          other.sourceVersionId == sourceVersionId;

  @override
  int get hashCode =>
      changeNote.hashCode +
      (expectedProfileVersion == null ? 0 : expectedProfileVersion.hashCode) +
      (explanationFingerprint == null ? 0 : explanationFingerprint.hashCode) +
      (fromCookingRecordId == null ? 0 : fromCookingRecordId.hashCode) +
      (microadjustChoice == null ? 0 : microadjustChoice.hashCode) +
      (modificationRequestId == null ? 0 : modificationRequestId.hashCode) +
      (modificationRevision == null ? 0 : modificationRevision.hashCode) +
      requestId.hashCode +
      snapshot.hashCode +
      sourceVersionId.hashCode;

  factory ImprovementSaveInput.fromJson(Map<String, dynamic> json) =>
      _$ImprovementSaveInputFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementSaveInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ImprovementSaveInputMicroadjustChoiceEnum {
  @JsonValue(r'branch')
  branch(r'branch'),
  @JsonValue(r'taste')
  taste(r'taste');

  const ImprovementSaveInputMicroadjustChoiceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
