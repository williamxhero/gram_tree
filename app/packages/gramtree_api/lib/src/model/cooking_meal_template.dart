//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_meal_template.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingMealTemplate {
  /// Returns a new [CookingMealTemplate] instance.
  CookingMealTemplate({
    required this.composition,

    required this.dayType,

    required this.dishCount,

    required this.meal,
  });

  @JsonKey(name: r'composition', required: true, includeIfNull: false)
  final List<CookingMealTemplateCompositionEnum> composition;

  @JsonKey(name: r'day_type', required: true, includeIfNull: false)
  final CookingMealTemplateDayTypeEnum dayType;

  // minimum: 1
  // maximum: 20
  @JsonKey(name: r'dish_count', required: true, includeIfNull: false)
  final int dishCount;

  @JsonKey(name: r'meal', required: true, includeIfNull: false)
  final CookingMealTemplateMealEnum meal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingMealTemplate &&
          other.composition == composition &&
          other.dayType == dayType &&
          other.dishCount == dishCount &&
          other.meal == meal;

  @override
  int get hashCode =>
      composition.hashCode +
      dayType.hashCode +
      dishCount.hashCode +
      meal.hashCode;

  factory CookingMealTemplate.fromJson(Map<String, dynamic> json) =>
      _$CookingMealTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$CookingMealTemplateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CookingMealTemplateCompositionEnum {
  @JsonValue(r'meat')
  meat(r'meat'),
  @JsonValue(r'vegetable')
  vegetable(r'vegetable'),
  @JsonValue(r'soup')
  soup(r'soup'),
  @JsonValue(r'staple')
  staple(r'staple'),
  @JsonValue(r'other')
  other(r'other');

  const CookingMealTemplateCompositionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CookingMealTemplateDayTypeEnum {
  @JsonValue(r'weekday')
  weekday(r'weekday'),
  @JsonValue(r'weekend')
  weekend(r'weekend');

  const CookingMealTemplateDayTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CookingMealTemplateMealEnum {
  @JsonValue(r'breakfast')
  breakfast(r'breakfast'),
  @JsonValue(r'lunch')
  lunch(r'lunch'),
  @JsonValue(r'dinner')
  dinner(r'dinner');

  const CookingMealTemplateMealEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
