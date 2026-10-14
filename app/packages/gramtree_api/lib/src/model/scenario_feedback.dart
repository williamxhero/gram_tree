//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scenario_feedback.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ScenarioFeedback {
  /// Returns a new [ScenarioFeedback] instance.
  ScenarioFeedback({required this.componentId, required this.sourceType});

  @JsonKey(name: r'component_id', required: true, includeIfNull: false)
  final String componentId;

  @JsonKey(name: r'source_type', required: true, includeIfNull: false)
  final ScenarioFeedbackSourceTypeEnum sourceType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenarioFeedback &&
          other.componentId == componentId &&
          other.sourceType == sourceType;

  @override
  int get hashCode => componentId.hashCode + sourceType.hashCode;

  factory ScenarioFeedback.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$ScenarioFeedbackToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ScenarioFeedbackSourceTypeEnum {
  @JsonValue(r'scenario_adjusted')
  scenarioAdjusted(r'scenario_adjusted');

  const ScenarioFeedbackSourceTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
