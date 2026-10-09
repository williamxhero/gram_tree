//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/assisted_step_pair.dart';
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_comparison_assistance.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeComparisonAssistance {
  /// Returns a new [RecipeComparisonAssistance] instance.
  RecipeComparisonAssistance({
    this.alignments,

    required this.fromVersionId,

    this.interpretation,

    this.reasonCode,

    required this.rulesVersion,

    required this.status,

    required this.toVersionId,
  });

  @JsonKey(name: r'alignments', required: false, includeIfNull: false)
  final List<AssistedStepPair>? alignments;

  @JsonKey(name: r'from_version_id', required: true, includeIfNull: false)
  final String fromVersionId;

  @JsonKey(name: r'interpretation', required: false, includeIfNull: false)
  final SourcedValue? interpretation;

  @JsonKey(name: r'reason_code', required: false, includeIfNull: false)
  final String? reasonCode;

  @JsonKey(name: r'rules_version', required: true, includeIfNull: false)
  final String rulesVersion;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecipeComparisonAssistanceStatusEnum status;

  @JsonKey(name: r'to_version_id', required: true, includeIfNull: false)
  final String toVersionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeComparisonAssistance &&
          other.alignments == alignments &&
          other.fromVersionId == fromVersionId &&
          other.interpretation == interpretation &&
          other.reasonCode == reasonCode &&
          other.rulesVersion == rulesVersion &&
          other.status == status &&
          other.toVersionId == toVersionId;

  @override
  int get hashCode =>
      alignments.hashCode +
      fromVersionId.hashCode +
      interpretation.hashCode +
      (reasonCode == null ? 0 : reasonCode.hashCode) +
      rulesVersion.hashCode +
      status.hashCode +
      toVersionId.hashCode;

  factory RecipeComparisonAssistance.fromJson(Map<String, dynamic> json) =>
      _$RecipeComparisonAssistanceFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeComparisonAssistanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeComparisonAssistanceStatusEnum {
  @JsonValue(r'ready')
  ready(r'ready'),
  @JsonValue(r'unavailable')
  unavailable(r'unavailable');

  const RecipeComparisonAssistanceStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
