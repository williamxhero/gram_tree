//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ingredient_preference_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IngredientPreferenceOut {
  /// Returns a new [IngredientPreferenceOut] instance.
  IngredientPreferenceOut({
    this.category,

    this.ingredientId,

    required this.name,

    required this.preference,
  });

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final String? category;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'preference', required: true, includeIfNull: false)
  final IngredientPreferenceOutPreferenceEnum preference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientPreferenceOut &&
          other.category == category &&
          other.ingredientId == ingredientId &&
          other.name == name &&
          other.preference == preference;

  @override
  int get hashCode =>
      (category == null ? 0 : category.hashCode) +
      (ingredientId == null ? 0 : ingredientId.hashCode) +
      name.hashCode +
      preference.hashCode;

  factory IngredientPreferenceOut.fromJson(Map<String, dynamic> json) =>
      _$IngredientPreferenceOutFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientPreferenceOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum IngredientPreferenceOutPreferenceEnum {
  @JsonValue(r'liked')
  liked(r'liked'),
  @JsonValue(r'disliked')
  disliked(r'disliked'),
  @JsonValue(r'avoided')
  avoided(r'avoided');

  const IngredientPreferenceOutPreferenceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
