//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_safety_finding.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSafetyFinding {
  /// Returns a new [RecipeSafetyFinding] instance.
  RecipeSafetyFinding({
    required this.basis,

    this.ingredientIds,

    required this.message,

    this.restMinutes,

    required this.ruleId,

    required this.severity,

    this.stepIds,

    this.thresholdCelsius,
  });

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'ingredient_ids', required: false, includeIfNull: false)
  final List<String>? ingredientIds;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'rest_minutes', required: false, includeIfNull: false)
  final int? restMinutes;

  @JsonKey(name: r'rule_id', required: true, includeIfNull: false)
  final String ruleId;

  @JsonKey(name: r'severity', required: true, includeIfNull: false)
  final RecipeSafetyFindingSeverityEnum severity;

  @JsonKey(name: r'step_ids', required: false, includeIfNull: false)
  final List<String>? stepIds;

  @JsonKey(name: r'threshold_celsius', required: false, includeIfNull: false)
  final num? thresholdCelsius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSafetyFinding &&
          other.basis == basis &&
          other.ingredientIds == ingredientIds &&
          other.message == message &&
          other.restMinutes == restMinutes &&
          other.ruleId == ruleId &&
          other.severity == severity &&
          other.stepIds == stepIds &&
          other.thresholdCelsius == thresholdCelsius;

  @override
  int get hashCode =>
      basis.hashCode +
      ingredientIds.hashCode +
      message.hashCode +
      (restMinutes == null ? 0 : restMinutes.hashCode) +
      ruleId.hashCode +
      severity.hashCode +
      stepIds.hashCode +
      (thresholdCelsius == null ? 0 : thresholdCelsius.hashCode);

  factory RecipeSafetyFinding.fromJson(Map<String, dynamic> json) =>
      _$RecipeSafetyFindingFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSafetyFindingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeSafetyFindingSeverityEnum {
  @JsonValue(r'info')
  info(r'info'),
  @JsonValue(r'warning')
  warning(r'warning'),
  @JsonValue(r'high_risk')
  highRisk(r'high_risk');

  const RecipeSafetyFindingSeverityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
