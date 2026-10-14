//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personalized_step_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalizedStepOut {
  /// Returns a new [PersonalizedStepOut] instance.
  PersonalizedStepOut({
    this.changed = false,

    this.cookware,

    required this.id,

    required this.instruction,

    required this.originalInstruction,

    required this.source_,
  });

  @JsonKey(
    defaultValue: false,
    name: r'changed',
    required: false,
    includeIfNull: false,
  )
  final bool? changed;

  @JsonKey(name: r'cookware', required: false, includeIfNull: false)
  final String? cookware;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'instruction', required: true, includeIfNull: false)
  final String instruction;

  @JsonKey(name: r'original_instruction', required: true, includeIfNull: false)
  final String originalInstruction;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final PersonalizedStepOutSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedStepOut &&
          other.changed == changed &&
          other.cookware == cookware &&
          other.id == id &&
          other.instruction == instruction &&
          other.originalInstruction == originalInstruction &&
          other.source_ == source_;

  @override
  int get hashCode =>
      changed.hashCode +
      (cookware == null ? 0 : cookware.hashCode) +
      id.hashCode +
      instruction.hashCode +
      originalInstruction.hashCode +
      source_.hashCode;

  factory PersonalizedStepOut.fromJson(Map<String, dynamic> json) =>
      _$PersonalizedStepOutFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalizedStepOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalizedStepOutSource_Enum {
  @JsonValue(r'recipe')
  recipe(r'recipe'),
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated'),
  @JsonValue(r'scenario_adjusted')
  scenarioAdjusted(r'scenario_adjusted');

  const PersonalizedStepOutSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
