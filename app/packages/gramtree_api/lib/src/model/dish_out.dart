//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dish_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DishOut {
  /// Returns a new [DishOut] instance.
  DishOut({required this.aliases, required this.id, required this.name});

  @JsonKey(name: r'aliases', required: true, includeIfNull: false)
  final List<String> aliases;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishOut &&
          other.aliases == aliases &&
          other.id == id &&
          other.name == name;

  @override
  int get hashCode => aliases.hashCode + id.hashCode + name.hashCode;

  factory DishOut.fromJson(Map<String, dynamic> json) =>
      _$DishOutFromJson(json);

  Map<String, dynamic> toJson() => _$DishOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
