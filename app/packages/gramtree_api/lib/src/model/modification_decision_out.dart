//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_decision_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationDecisionOut {
  /// Returns a new [ModificationDecisionOut] instance.
  ModificationDecisionOut({
    this.after,

    this.blockedBy,

    required this.decision,

    required this.operationId,
  });

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final String? after;

  @JsonKey(name: r'blocked_by', required: false, includeIfNull: false)
  final List<String>? blockedBy;

  @JsonKey(name: r'decision', required: true, includeIfNull: false)
  final ModificationDecisionOutDecisionEnum decision;

  @JsonKey(name: r'operation_id', required: true, includeIfNull: false)
  final String operationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationDecisionOut &&
          other.after == after &&
          other.blockedBy == blockedBy &&
          other.decision == decision &&
          other.operationId == operationId;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      blockedBy.hashCode +
      decision.hashCode +
      operationId.hashCode;

  factory ModificationDecisionOut.fromJson(Map<String, dynamic> json) =>
      _$ModificationDecisionOutFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationDecisionOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ModificationDecisionOutDecisionEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'accept')
  accept(r'accept'),
  @JsonValue(r'reject')
  reject(r'reject'),
  @JsonValue(r'modify')
  modify(r'modify');

  const ModificationDecisionOutDecisionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
