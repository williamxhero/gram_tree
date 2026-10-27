//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/dietary_unclassified_dish.dart';
import 'package:gramtree_api/src/model/dietary_dish_count.dart';
import 'package:gramtree_api/src/model/dietary_distribution_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dietary_statistics_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DietaryStatisticsOut {
  /// Returns a new [DietaryStatisticsOut] instance.
  DietaryStatisticsOut({
    required this.cookingCount,

    required this.cuisineDistribution,

    required this.endAt,

    required this.frequentDishes,

    required this.generatedAt,

    required this.ingredientDistribution,

    required this.ingredientRecordCount,

    required this.localEnd,

    required this.localStart,

    required this.newDishes,

    required this.period,

    required this.startAt,

    required this.timezone,

    required this.unclassifiedDishCount,

    required this.unclassifiedDishes,
  });

  // minimum: 0
  @JsonKey(name: r'cooking_count', required: true, includeIfNull: false)
  final int cookingCount;

  @JsonKey(name: r'cuisine_distribution', required: true, includeIfNull: false)
  final List<DietaryDistributionItem> cuisineDistribution;

  @JsonKey(name: r'end_at', required: true, includeIfNull: false)
  final String endAt;

  @JsonKey(name: r'frequent_dishes', required: true, includeIfNull: false)
  final List<DietaryDishCount> frequentDishes;

  @JsonKey(name: r'generated_at', required: true, includeIfNull: false)
  final String generatedAt;

  @JsonKey(
    name: r'ingredient_distribution',
    required: true,
    includeIfNull: false,
  )
  final List<DietaryDistributionItem> ingredientDistribution;

  // minimum: 0
  @JsonKey(
    name: r'ingredient_record_count',
    required: true,
    includeIfNull: false,
  )
  final int ingredientRecordCount;

  /// Exclusive local end date
  @JsonKey(name: r'local_end', required: true, includeIfNull: false)
  final DateTime localEnd;

  @JsonKey(name: r'local_start', required: true, includeIfNull: false)
  final DateTime localStart;

  @JsonKey(name: r'new_dishes', required: true, includeIfNull: false)
  final List<DietaryDishCount> newDishes;

  @JsonKey(name: r'period', required: true, includeIfNull: false)
  final DietaryStatisticsOutPeriodEnum period;

  @JsonKey(name: r'start_at', required: true, includeIfNull: false)
  final String startAt;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  // minimum: 0
  @JsonKey(
    name: r'unclassified_dish_count',
    required: true,
    includeIfNull: false,
  )
  final int unclassifiedDishCount;

  /// Unresolved record facts, not merged dishes or claims of first attempts
  @JsonKey(name: r'unclassified_dishes', required: true, includeIfNull: false)
  final List<DietaryUnclassifiedDish> unclassifiedDishes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryStatisticsOut &&
          other.cookingCount == cookingCount &&
          other.cuisineDistribution == cuisineDistribution &&
          other.endAt == endAt &&
          other.frequentDishes == frequentDishes &&
          other.generatedAt == generatedAt &&
          other.ingredientDistribution == ingredientDistribution &&
          other.ingredientRecordCount == ingredientRecordCount &&
          other.localEnd == localEnd &&
          other.localStart == localStart &&
          other.newDishes == newDishes &&
          other.period == period &&
          other.startAt == startAt &&
          other.timezone == timezone &&
          other.unclassifiedDishCount == unclassifiedDishCount &&
          other.unclassifiedDishes == unclassifiedDishes;

  @override
  int get hashCode =>
      cookingCount.hashCode +
      cuisineDistribution.hashCode +
      endAt.hashCode +
      frequentDishes.hashCode +
      generatedAt.hashCode +
      ingredientDistribution.hashCode +
      ingredientRecordCount.hashCode +
      localEnd.hashCode +
      localStart.hashCode +
      newDishes.hashCode +
      period.hashCode +
      startAt.hashCode +
      timezone.hashCode +
      unclassifiedDishCount.hashCode +
      unclassifiedDishes.hashCode;

  factory DietaryStatisticsOut.fromJson(Map<String, dynamic> json) =>
      _$DietaryStatisticsOutFromJson(json);

  Map<String, dynamic> toJson() => _$DietaryStatisticsOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum DietaryStatisticsOutPeriodEnum {
  @JsonValue(r'week')
  week(r'week'),
  @JsonValue(r'month')
  month(r'month'),
  @JsonValue(r'year')
  year(r'year');

  const DietaryStatisticsOutPeriodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
