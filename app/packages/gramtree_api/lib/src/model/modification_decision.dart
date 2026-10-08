//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_decision.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationDecision {
  /// Returns a new [ModificationDecision] instance.
  ModificationDecision({
    this.after,

    required this.decision,

    required this.operationId,
  });

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final String? after;

  @JsonKey(name: r'decision', required: true, includeIfNull: false)
  final ModificationDecisionDecisionEnum decision;

  @JsonKey(name: r'operation_id', required: true, includeIfNull: false)
  final String operationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationDecision &&
          other.after == after &&
          other.decision == decision &&
          other.operationId == operationId;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      decision.hashCode +
      operationId.hashCode;

  factory ModificationDecision.fromJson(Map<String, dynamic> json) =>
      _$ModificationDecisionFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationDecisionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ModificationDecisionDecisionEnum {
  @JsonValue(r'accept')
  accept(r'accept'),
  @JsonValue(r'reject')
  reject(r'reject'),
  @JsonValue(r'modify')
  modify(r'modify');

  const ModificationDecisionDecisionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
