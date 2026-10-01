//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dish_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DishInput {
  /// Returns a new [DishInput] instance.
  DishInput({this.aliases, required this.name});

  @JsonKey(name: r'aliases', required: false, includeIfNull: false)
  final List<String>? aliases;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishInput && other.aliases == aliases && other.name == name;

  @override
  int get hashCode => aliases.hashCode + name.hashCode;

  factory DishInput.fromJson(Map<String, dynamic> json) =>
      _$DishInputFromJson(json);

  Map<String, dynamic> toJson() => _$DishInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
