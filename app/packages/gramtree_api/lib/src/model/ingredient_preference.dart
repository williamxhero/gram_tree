//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ingredient_preference.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IngredientPreference {
  /// Returns a new [IngredientPreference] instance.
  IngredientPreference({
    this.category,

    this.ingredientId,

    required this.preference,
  });

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final String? category;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @JsonKey(name: r'preference', required: true, includeIfNull: false)
  final IngredientPreferencePreferenceEnum preference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientPreference &&
          other.category == category &&
          other.ingredientId == ingredientId &&
          other.preference == preference;

  @override
  int get hashCode =>
      (category == null ? 0 : category.hashCode) +
      (ingredientId == null ? 0 : ingredientId.hashCode) +
      preference.hashCode;

  factory IngredientPreference.fromJson(Map<String, dynamic> json) =>
      _$IngredientPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientPreferenceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum IngredientPreferencePreferenceEnum {
  @JsonValue(r'liked')
  liked(r'liked'),
  @JsonValue(r'disliked')
  disliked(r'disliked'),
  @JsonValue(r'avoided')
  avoided(r'avoided');

  const IngredientPreferencePreferenceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
