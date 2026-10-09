//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_meal_time.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingMealTime {
  /// Returns a new [CookingMealTime] instance.
  CookingMealTime({
    required this.dayType,

    required this.meal,

    required this.minutes,
  });

  @JsonKey(name: r'day_type', required: true, includeIfNull: false)
  final CookingMealTimeDayTypeEnum dayType;

  @JsonKey(name: r'meal', required: true, includeIfNull: false)
  final CookingMealTimeMealEnum meal;

  // minimum: 1
  // maximum: 1440
  @JsonKey(name: r'minutes', required: true, includeIfNull: false)
  final int minutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingMealTime &&
          other.dayType == dayType &&
          other.meal == meal &&
          other.minutes == minutes;

  @override
  int get hashCode => dayType.hashCode + meal.hashCode + minutes.hashCode;

  factory CookingMealTime.fromJson(Map<String, dynamic> json) =>
      _$CookingMealTimeFromJson(json);

  Map<String, dynamic> toJson() => _$CookingMealTimeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CookingMealTimeDayTypeEnum {
  @JsonValue(r'weekday')
  weekday(r'weekday'),
  @JsonValue(r'weekend')
  weekend(r'weekend');

  const CookingMealTimeDayTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CookingMealTimeMealEnum {
  @JsonValue(r'breakfast')
  breakfast(r'breakfast'),
  @JsonValue(r'lunch')
  lunch(r'lunch'),
  @JsonValue(r'dinner')
  dinner(r'dinner');

  const CookingMealTimeMealEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
