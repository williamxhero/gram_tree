//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/cooking_meal_time.dart';
import 'package:gramtree_api/src/model/cooking_meal_template.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_constraints.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingConstraints {
  /// Returns a new [CookingConstraints] instance.
  CookingConstraints({
    this.equipment,

    this.householdServings,

    this.mealTemplates,

    this.mealTimes,
  });

  @JsonKey(name: r'equipment', required: false, includeIfNull: false)
  final List<String>? equipment;

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'household_servings', required: false, includeIfNull: false)
  final int? householdServings;

  @JsonKey(name: r'meal_templates', required: false, includeIfNull: false)
  final List<CookingMealTemplate>? mealTemplates;

  @JsonKey(name: r'meal_times', required: false, includeIfNull: false)
  final List<CookingMealTime>? mealTimes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingConstraints &&
          other.equipment == equipment &&
          other.householdServings == householdServings &&
          other.mealTemplates == mealTemplates &&
          other.mealTimes == mealTimes;

  @override
  int get hashCode =>
      equipment.hashCode +
      (householdServings == null ? 0 : householdServings.hashCode) +
      mealTemplates.hashCode +
      mealTimes.hashCode;

  factory CookingConstraints.fromJson(Map<String, dynamic> json) =>
      _$CookingConstraintsFromJson(json);

  Map<String, dynamic> toJson() => _$CookingConstraintsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
