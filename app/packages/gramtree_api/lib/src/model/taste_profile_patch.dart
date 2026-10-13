//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ingredient_preference.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_profile_patch.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteProfilePatch {
  /// Returns a new [TasteProfilePatch] instance.
  TasteProfilePatch({this.flavors, this.ingredientPreferences});

  @JsonKey(name: r'flavors', required: false, includeIfNull: false)
  final Map<String, num>? flavors;

  @JsonKey(
    name: r'ingredient_preferences',
    required: false,
    includeIfNull: false,
  )
  final List<IngredientPreference>? ingredientPreferences;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteProfilePatch &&
          other.flavors == flavors &&
          other.ingredientPreferences == ingredientPreferences;

  @override
  int get hashCode =>
      flavors.hashCode +
      (ingredientPreferences == null ? 0 : ingredientPreferences.hashCode);

  factory TasteProfilePatch.fromJson(Map<String, dynamic> json) =>
      _$TasteProfilePatchFromJson(json);

  Map<String, dynamic> toJson() => _$TasteProfilePatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
