//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/quantification_decision.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quantification_decisions_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuantificationDecisionsInput {
  /// Returns a new [QuantificationDecisionsInput] instance.
  QuantificationDecisionsInput({this.acceptAll = false, this.decisions});

  @JsonKey(
    defaultValue: false,
    name: r'accept_all',
    required: false,
    includeIfNull: false,
  )
  final bool? acceptAll;

  @JsonKey(name: r'decisions', required: false, includeIfNull: false)
  final List<QuantificationDecision>? decisions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantificationDecisionsInput &&
          other.acceptAll == acceptAll &&
          other.decisions == decisions;

  @override
  int get hashCode => acceptAll.hashCode + decisions.hashCode;

  factory QuantificationDecisionsInput.fromJson(Map<String, dynamic> json) =>
      _$QuantificationDecisionsInputFromJson(json);

  Map<String, dynamic> toJson() => _$QuantificationDecisionsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
