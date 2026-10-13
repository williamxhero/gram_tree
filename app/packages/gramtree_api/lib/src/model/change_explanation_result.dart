//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ai_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_explanation_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangeExplanationResult {
  /// Returns a new [ChangeExplanationResult] instance.
  ChangeExplanationResult({
    this.changeNote,

    required this.changesFingerprint,

    this.error,

    this.source_,

    required this.status,

    this.tags,
  });

  @JsonKey(name: r'change_note', required: false, includeIfNull: false)
  final String? changeNote;

  @JsonKey(name: r'changes_fingerprint', required: true, includeIfNull: false)
  final String changesFingerprint;

  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @JsonKey(name: r'source', required: false, includeIfNull: false)
  final ChangeExplanationResultSource_Enum? source_;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AIStatus status;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeExplanationResult &&
          other.changeNote == changeNote &&
          other.changesFingerprint == changesFingerprint &&
          other.error == error &&
          other.source_ == source_ &&
          other.status == status &&
          other.tags == tags;

  @override
  int get hashCode =>
      (changeNote == null ? 0 : changeNote.hashCode) +
      changesFingerprint.hashCode +
      (error == null ? 0 : error.hashCode) +
      (source_ == null ? 0 : source_.hashCode) +
      status.hashCode +
      tags.hashCode;

  factory ChangeExplanationResult.fromJson(Map<String, dynamic> json) =>
      _$ChangeExplanationResultFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeExplanationResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ChangeExplanationResultSource_Enum {
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated');

  const ChangeExplanationResultSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
