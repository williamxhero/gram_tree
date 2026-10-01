//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/nutrition_estimate.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_derived.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeDerived {
  /// Returns a new [RecipeDerived] instance.
  RecipeDerived({
    required this.activeTimeSeconds,

    this.allergens,

    this.allergensIncomplete = false,

    this.cookware,

    this.nutritionPerServing,

    required this.totalTimeSeconds,
  });

  @JsonKey(name: r'active_time_seconds', required: true, includeIfNull: false)
  final int activeTimeSeconds;

  @JsonKey(name: r'allergens', required: false, includeIfNull: false)
  final List<String>? allergens;

  @JsonKey(
    defaultValue: false,
    name: r'allergens_incomplete',
    required: false,
    includeIfNull: false,
  )
  final bool? allergensIncomplete;

  @JsonKey(name: r'cookware', required: false, includeIfNull: false)
  final List<String>? cookware;

  @JsonKey(
    name: r'nutrition_per_serving',
    required: false,
    includeIfNull: false,
  )
  final NutritionEstimate? nutritionPerServing;

  @JsonKey(name: r'total_time_seconds', required: true, includeIfNull: false)
  final int totalTimeSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDerived &&
          other.activeTimeSeconds == activeTimeSeconds &&
          other.allergens == allergens &&
          other.allergensIncomplete == allergensIncomplete &&
          other.cookware == cookware &&
          other.nutritionPerServing == nutritionPerServing &&
          other.totalTimeSeconds == totalTimeSeconds;

  @override
  int get hashCode =>
      activeTimeSeconds.hashCode +
      allergens.hashCode +
      allergensIncomplete.hashCode +
      cookware.hashCode +
      nutritionPerServing.hashCode +
      totalTimeSeconds.hashCode;

  factory RecipeDerived.fromJson(Map<String, dynamic> json) =>
      _$RecipeDerivedFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDerivedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
