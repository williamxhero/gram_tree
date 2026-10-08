//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'allergy_ingredient_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AllergyIngredientOut {
  /// Returns a new [AllergyIngredientOut] instance.
  AllergyIngredientOut({required this.ingredientId, required this.name});

  @JsonKey(name: r'ingredient_id', required: true, includeIfNull: false)
  final String ingredientId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllergyIngredientOut &&
          other.ingredientId == ingredientId &&
          other.name == name;

  @override
  int get hashCode => ingredientId.hashCode + name.hashCode;

  factory AllergyIngredientOut.fromJson(Map<String, dynamic> json) =>
      _$AllergyIngredientOutFromJson(json);

  Map<String, dynamic> toJson() => _$AllergyIngredientOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
