//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dietary_dish_count.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DietaryDishCount {
  /// Returns a new [DietaryDishCount] instance.
  DietaryDishCount({
    required this.count,

    required this.dishId,

    required this.firstCookedAt,

    required this.name,
  });

  // minimum: 1
  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'dish_id', required: true, includeIfNull: false)
  final String dishId;

  @JsonKey(name: r'first_cooked_at', required: true, includeIfNull: false)
  final String firstCookedAt;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryDishCount &&
          other.count == count &&
          other.dishId == dishId &&
          other.firstCookedAt == firstCookedAt &&
          other.name == name;

  @override
  int get hashCode =>
      count.hashCode + dishId.hashCode + firstCookedAt.hashCode + name.hashCode;

  factory DietaryDishCount.fromJson(Map<String, dynamic> json) =>
      _$DietaryDishCountFromJson(json);

  Map<String, dynamic> toJson() => _$DietaryDishCountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
