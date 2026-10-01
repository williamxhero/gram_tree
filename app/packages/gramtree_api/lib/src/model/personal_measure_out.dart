//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personal_measure_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalMeasureOut {
  /// Returns a new [PersonalMeasureOut] instance.
  PersonalMeasureOut({
    required this.capacityMl,

    required this.createdAt,

    required this.id,

    required this.kind,

    required this.name,

    required this.updatedAt,
  });

  @JsonKey(name: r'capacity_ml', required: true, includeIfNull: false)
  final num capacityMl;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final PersonalMeasureOutKindEnum kind;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final String updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalMeasureOut &&
          other.capacityMl == capacityMl &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.kind == kind &&
          other.name == name &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      capacityMl.hashCode +
      createdAt.hashCode +
      id.hashCode +
      kind.hashCode +
      name.hashCode +
      updatedAt.hashCode;

  factory PersonalMeasureOut.fromJson(Map<String, dynamic> json) =>
      _$PersonalMeasureOutFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalMeasureOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalMeasureOutKindEnum {
  @JsonValue(r'spoon')
  spoon(r'spoon'),
  @JsonValue(r'bowl')
  bowl(r'bowl'),
  @JsonValue(r'cup')
  cup(r'cup');

  const PersonalMeasureOutKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
