//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_draft_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementDraftInput {
  /// Returns a new [ImprovementDraftInput] instance.
  ImprovementDraftInput({required this.sourceVersionId});

  @JsonKey(name: r'source_version_id', required: true, includeIfNull: false)
  final String sourceVersionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementDraftInput &&
          other.sourceVersionId == sourceVersionId;

  @override
  int get hashCode => sourceVersionId.hashCode;

  factory ImprovementDraftInput.fromJson(Map<String, dynamic> json) =>
      _$ImprovementDraftInputFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementDraftInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
