//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quantification_decision.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuantificationDecision {
  /// Returns a new [QuantificationDecision] instance.
  QuantificationDecision({
    required this.decision,

    required this.problemId,

    this.unit,

    this.value,
  });

  @JsonKey(name: r'decision', required: true, includeIfNull: false)
  final QuantificationDecisionDecisionEnum decision;

  @JsonKey(name: r'problem_id', required: true, includeIfNull: false)
  final String problemId;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final String? unit;

  @JsonKey(name: r'value', required: false, includeIfNull: false)
  final String? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantificationDecision &&
          other.decision == decision &&
          other.problemId == problemId &&
          other.unit == unit &&
          other.value == value;

  @override
  int get hashCode =>
      decision.hashCode +
      problemId.hashCode +
      (unit == null ? 0 : unit.hashCode) +
      (value == null ? 0 : value.hashCode);

  factory QuantificationDecision.fromJson(Map<String, dynamic> json) =>
      _$QuantificationDecisionFromJson(json);

  Map<String, dynamic> toJson() => _$QuantificationDecisionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum QuantificationDecisionDecisionEnum {
  @JsonValue(r'accept')
  accept(r'accept'),
  @JsonValue(r'modify')
  modify(r'modify'),
  @JsonValue(r'ignore')
  ignore(r'ignore');

  const QuantificationDecisionDecisionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
