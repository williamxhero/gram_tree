//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attribution_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttributionOut {
  /// Returns a new [AttributionOut] instance.
  AttributionOut({
    required this.answered,

    required this.asked,

    required this.decisionSource,

    required this.flavors,

    required this.learningEligibility,

    required this.reasonCode,

    this.recipeVersionId,

    required this.recordId,

    required this.rulesVersion,

    required this.sampleSize,

    required this.updatedAt,

    required this.verdict,
  });

  @JsonKey(name: r'answered', required: true, includeIfNull: false)
  final bool answered;

  @JsonKey(name: r'asked', required: true, includeIfNull: false)
  final bool asked;

  @JsonKey(name: r'decision_source', required: true, includeIfNull: false)
  final AttributionOutDecisionSourceEnum decisionSource;

  @JsonKey(name: r'flavors', required: true, includeIfNull: false)
  final Map<String, int> flavors;

  @JsonKey(name: r'learning_eligibility', required: true, includeIfNull: false)
  final AttributionOutLearningEligibilityEnum learningEligibility;

  @JsonKey(name: r'reason_code', required: true, includeIfNull: false)
  final String reasonCode;

  @JsonKey(name: r'recipe_version_id', required: false, includeIfNull: false)
  final String? recipeVersionId;

  @JsonKey(name: r'record_id', required: true, includeIfNull: false)
  final String recordId;

  @JsonKey(name: r'rules_version', required: true, includeIfNull: false)
  final String rulesVersion;

  @JsonKey(name: r'sample_size', required: true, includeIfNull: false)
  final int sampleSize;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final String updatedAt;

  @JsonKey(name: r'verdict', required: true, includeIfNull: false)
  final AttributionOutVerdictEnum verdict;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttributionOut &&
          other.answered == answered &&
          other.asked == asked &&
          other.decisionSource == decisionSource &&
          other.flavors == flavors &&
          other.learningEligibility == learningEligibility &&
          other.reasonCode == reasonCode &&
          other.recipeVersionId == recipeVersionId &&
          other.recordId == recordId &&
          other.rulesVersion == rulesVersion &&
          other.sampleSize == sampleSize &&
          other.updatedAt == updatedAt &&
          other.verdict == verdict;

  @override
  int get hashCode =>
      answered.hashCode +
      asked.hashCode +
      decisionSource.hashCode +
      flavors.hashCode +
      learningEligibility.hashCode +
      reasonCode.hashCode +
      (recipeVersionId == null ? 0 : recipeVersionId.hashCode) +
      recordId.hashCode +
      rulesVersion.hashCode +
      sampleSize.hashCode +
      updatedAt.hashCode +
      verdict.hashCode;

  factory AttributionOut.fromJson(Map<String, dynamic> json) =>
      _$AttributionOutFromJson(json);

  Map<String, dynamic> toJson() => _$AttributionOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AttributionOutDecisionSourceEnum {
  @JsonValue(r'rule')
  rule(r'rule'),
  @JsonValue(r'user')
  user(r'user'),
  @JsonValue(r'unanswered')
  unanswered(r'unanswered');

  const AttributionOutDecisionSourceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AttributionOutLearningEligibilityEnum {
  @JsonValue(r'strong')
  strong(r'strong'),
  @JsonValue(r'reduced')
  reduced(r'reduced'),
  @JsonValue(r'excluded')
  excluded(r'excluded');

  const AttributionOutLearningEligibilityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AttributionOutVerdictEnum {
  @JsonValue(r'personal')
  personal(r'personal'),
  @JsonValue(r'recipe')
  recipe(r'recipe'),
  @JsonValue(r'pending')
  pending(r'pending');

  const AttributionOutVerdictEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
