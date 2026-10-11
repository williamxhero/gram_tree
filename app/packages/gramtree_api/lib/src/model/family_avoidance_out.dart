//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_avoidance_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyAvoidanceOut {
  /// Returns a new [FamilyAvoidanceOut] instance.
  FamilyAvoidanceOut({this.category, this.ingredientId, required this.name});

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final String? category;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyAvoidanceOut &&
          other.category == category &&
          other.ingredientId == ingredientId &&
          other.name == name;

  @override
  int get hashCode =>
      (category == null ? 0 : category.hashCode) +
      (ingredientId == null ? 0 : ingredientId.hashCode) +
      name.hashCode;

  factory FamilyAvoidanceOut.fromJson(Map<String, dynamic> json) =>
      _$FamilyAvoidanceOutFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyAvoidanceOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
