//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personal_measure_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalMeasureUpdate {
  /// Returns a new [PersonalMeasureUpdate] instance.
  PersonalMeasureUpdate({this.capacityMl, this.kind, this.name});

  // maximum: 10000.0
  @JsonKey(name: r'capacity_ml', required: false, includeIfNull: false)
  final num? capacityMl;

  @JsonKey(name: r'kind', required: false, includeIfNull: false)
  final PersonalMeasureUpdateKindEnum? kind;

  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalMeasureUpdate &&
          other.capacityMl == capacityMl &&
          other.kind == kind &&
          other.name == name;

  @override
  int get hashCode =>
      (capacityMl == null ? 0 : capacityMl.hashCode) +
      (kind == null ? 0 : kind.hashCode) +
      (name == null ? 0 : name.hashCode);

  factory PersonalMeasureUpdate.fromJson(Map<String, dynamic> json) =>
      _$PersonalMeasureUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalMeasureUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalMeasureUpdateKindEnum {
  @JsonValue(r'spoon')
  spoon(r'spoon'),
  @JsonValue(r'bowl')
  bowl(r'bowl'),
  @JsonValue(r'cup')
  cup(r'cup');

  const PersonalMeasureUpdateKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
