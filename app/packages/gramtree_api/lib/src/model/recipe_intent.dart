//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_intent.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeIntent {
  /// Returns a new [RecipeIntent] instance.
  RecipeIntent({
    this.cookware,

    required this.dishName,

    this.restrictions,

    this.servings,

    this.taste,
  });

  @JsonKey(name: r'cookware', required: false, includeIfNull: false)
  final List<String>? cookware;

  @JsonKey(name: r'dish_name', required: true, includeIfNull: false)
  final String dishName;

  @JsonKey(name: r'restrictions', required: false, includeIfNull: false)
  final List<String>? restrictions;

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'servings', required: false, includeIfNull: false)
  final int? servings;

  @JsonKey(name: r'taste', required: false, includeIfNull: false)
  final List<String>? taste;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIntent &&
          other.cookware == cookware &&
          other.dishName == dishName &&
          other.restrictions == restrictions &&
          other.servings == servings &&
          other.taste == taste;

  @override
  int get hashCode =>
      cookware.hashCode +
      dishName.hashCode +
      restrictions.hashCode +
      (servings == null ? 0 : servings.hashCode) +
      taste.hashCode;

  factory RecipeIntent.fromJson(Map<String, dynamic> json) =>
      _$RecipeIntentFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeIntentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
