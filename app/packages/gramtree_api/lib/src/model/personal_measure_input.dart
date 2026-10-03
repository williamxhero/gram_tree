//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personal_measure_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalMeasureInput {
  /// Returns a new [PersonalMeasureInput] instance.
  PersonalMeasureInput({
    required this.capacityMl,

    required this.kind,

    required this.name,
  });

  // maximum: 10000.0
  @JsonKey(name: r'capacity_ml', required: true, includeIfNull: false)
  final num capacityMl;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final PersonalMeasureInputKindEnum kind;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalMeasureInput &&
          other.capacityMl == capacityMl &&
          other.kind == kind &&
          other.name == name;

  @override
  int get hashCode => capacityMl.hashCode + kind.hashCode + name.hashCode;

  factory PersonalMeasureInput.fromJson(Map<String, dynamic> json) =>
      _$PersonalMeasureInputFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalMeasureInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalMeasureInputKindEnum {
  @JsonValue(r'spoon')
  spoon(r'spoon'),
  @JsonValue(r'bowl')
  bowl(r'bowl'),
  @JsonValue(r'cup')
  cup(r'cup');

  const PersonalMeasureInputKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
