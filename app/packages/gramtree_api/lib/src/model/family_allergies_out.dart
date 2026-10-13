//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/allergy_ingredient_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_allergies_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyAllergiesOut {
  /// Returns a new [FamilyAllergiesOut] instance.
  FamilyAllergiesOut({required this.categories, required this.ingredients});

  @JsonKey(name: r'categories', required: true, includeIfNull: false)
  final List<String> categories;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<AllergyIngredientOut> ingredients;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyAllergiesOut &&
          other.categories == categories &&
          other.ingredients == ingredients;

  @override
  int get hashCode => categories.hashCode + ingredients.hashCode;

  factory FamilyAllergiesOut.fromJson(Map<String, dynamic> json) =>
      _$FamilyAllergiesOutFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyAllergiesOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
