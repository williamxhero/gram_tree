//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_avoidance.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyAvoidance {
  /// Returns a new [FamilyAvoidance] instance.
  FamilyAvoidance({this.category, this.ingredientId});

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final String? category;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyAvoidance &&
          other.category == category &&
          other.ingredientId == ingredientId;

  @override
  int get hashCode =>
      (category == null ? 0 : category.hashCode) +
      (ingredientId == null ? 0 : ingredientId.hashCode);

  factory FamilyAvoidance.fromJson(Map<String, dynamic> json) =>
      _$FamilyAvoidanceFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyAvoidanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
