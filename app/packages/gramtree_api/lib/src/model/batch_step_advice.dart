//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_step_advice.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchStepAdvice {
  /// Returns a new [BatchStepAdvice] instance.
  BatchStepAdvice({
    required this.basis,

    required this.batchCount,

    required this.batchGuidance,

    required this.confidence,

    required this.doneness,

    required this.risk,

    required this.source_,

    required this.stepId,

    required this.suggestedDurationSeconds,
  });

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  // minimum: 1
  // maximum: 100
  @JsonKey(name: r'batch_count', required: true, includeIfNull: false)
  final int batchCount;

  @JsonKey(name: r'batch_guidance', required: true, includeIfNull: false)
  final String batchGuidance;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final num confidence;

  @JsonKey(name: r'doneness', required: true, includeIfNull: false)
  final String doneness;

  @JsonKey(name: r'risk', required: true, includeIfNull: false)
  final String risk;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final BatchStepAdviceSource_Enum source_;

  @JsonKey(name: r'step_id', required: true, includeIfNull: false)
  final String stepId;

  // minimum: 1
  // maximum: 86400
  @JsonKey(
    name: r'suggested_duration_seconds',
    required: true,
    includeIfNull: false,
  )
  final int suggestedDurationSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchStepAdvice &&
          other.basis == basis &&
          other.batchCount == batchCount &&
          other.batchGuidance == batchGuidance &&
          other.confidence == confidence &&
          other.doneness == doneness &&
          other.risk == risk &&
          other.source_ == source_ &&
          other.stepId == stepId &&
          other.suggestedDurationSeconds == suggestedDurationSeconds;

  @override
  int get hashCode =>
      basis.hashCode +
      batchCount.hashCode +
      batchGuidance.hashCode +
      confidence.hashCode +
      doneness.hashCode +
      risk.hashCode +
      source_.hashCode +
      stepId.hashCode +
      suggestedDurationSeconds.hashCode;

  factory BatchStepAdvice.fromJson(Map<String, dynamic> json) =>
      _$BatchStepAdviceFromJson(json);

  Map<String, dynamic> toJson() => _$BatchStepAdviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum BatchStepAdviceSource_Enum {
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated');

  const BatchStepAdviceSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
