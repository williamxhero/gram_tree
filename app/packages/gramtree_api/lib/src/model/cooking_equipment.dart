//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_equipment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingEquipment {
  /// Returns a new [CookingEquipment] instance.
  CookingEquipment({this.aliases, required this.id, required this.label});

  @JsonKey(name: r'aliases', required: false, includeIfNull: false)
  final List<String>? aliases;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingEquipment &&
          other.aliases == aliases &&
          other.id == id &&
          other.label == label;

  @override
  int get hashCode => aliases.hashCode + id.hashCode + label.hashCode;

  factory CookingEquipment.fromJson(Map<String, dynamic> json) =>
      _$CookingEquipmentFromJson(json);

  Map<String, dynamic> toJson() => _$CookingEquipmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
