//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/modification_decision.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_decisions_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationDecisionsInput {
  /// Returns a new [ModificationDecisionsInput] instance.
  ModificationDecisionsInput({this.decisions});

  @JsonKey(name: r'decisions', required: false, includeIfNull: false)
  final List<ModificationDecision>? decisions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationDecisionsInput && other.decisions == decisions;

  @override
  int get hashCode => decisions.hashCode;

  factory ModificationDecisionsInput.fromJson(Map<String, dynamic> json) =>
      _$ModificationDecisionsInputFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationDecisionsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
