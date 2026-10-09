//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/allergy_ingredient_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'allergies_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AllergiesOut {
  /// Returns a new [AllergiesOut] instance.
  AllergiesOut({
    required this.authorizationVersion,

    required this.availableCategories,

    required this.categories,

    required this.consentId,

    required this.consentVersion,

    required this.ingredients,

    required this.profileVersion,
  });

  @JsonKey(name: r'authorization_version', required: true, includeIfNull: false)
  final int authorizationVersion;

  @JsonKey(name: r'available_categories', required: true, includeIfNull: false)
  final List<String> availableCategories;

  @JsonKey(name: r'categories', required: true, includeIfNull: false)
  final List<String> categories;

  @JsonKey(name: r'consent_id', required: true, includeIfNull: true)
  final String? consentId;

  @JsonKey(name: r'consent_version', required: true, includeIfNull: false)
  final String consentVersion;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<AllergyIngredientOut> ingredients;

  @JsonKey(name: r'profile_version', required: true, includeIfNull: false)
  final int profileVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllergiesOut &&
          other.authorizationVersion == authorizationVersion &&
          other.availableCategories == availableCategories &&
          other.categories == categories &&
          other.consentId == consentId &&
          other.consentVersion == consentVersion &&
          other.ingredients == ingredients &&
          other.profileVersion == profileVersion;

  @override
  int get hashCode =>
      authorizationVersion.hashCode +
      availableCategories.hashCode +
      categories.hashCode +
      (consentId == null ? 0 : consentId.hashCode) +
      consentVersion.hashCode +
      ingredients.hashCode +
      profileVersion.hashCode;

  factory AllergiesOut.fromJson(Map<String, dynamic> json) =>
      _$AllergiesOutFromJson(json);

  Map<String, dynamic> toJson() => _$AllergiesOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
