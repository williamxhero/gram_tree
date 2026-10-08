// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_constraints.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingConstraintsCWProxy {
  CookingConstraints equipment(List<String>? equipment);

  CookingConstraints householdServings(int? householdServings);

  CookingConstraints mealTemplates(List<CookingMealTemplate>? mealTemplates);

  CookingConstraints mealTimes(List<CookingMealTime>? mealTimes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingConstraints(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingConstraints(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingConstraints call({
    List<String>? equipment,
    int? householdServings,
    List<CookingMealTemplate>? mealTemplates,
    List<CookingMealTime>? mealTimes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingConstraints.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingConstraints.copyWith.fieldName(...)`
class _$CookingConstraintsCWProxyImpl implements _$CookingConstraintsCWProxy {
  const _$CookingConstraintsCWProxyImpl(this._value);

  final CookingConstraints _value;

  @override
  CookingConstraints equipment(List<String>? equipment) =>
      this(equipment: equipment);

  @override
  CookingConstraints householdServings(int? householdServings) =>
      this(householdServings: householdServings);

  @override
  CookingConstraints mealTemplates(List<CookingMealTemplate>? mealTemplates) =>
      this(mealTemplates: mealTemplates);

  @override
  CookingConstraints mealTimes(List<CookingMealTime>? mealTimes) =>
      this(mealTimes: mealTimes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingConstraints(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingConstraints(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingConstraints call({
    Object? equipment = const $CopyWithPlaceholder(),
    Object? householdServings = const $CopyWithPlaceholder(),
    Object? mealTemplates = const $CopyWithPlaceholder(),
    Object? mealTimes = const $CopyWithPlaceholder(),
  }) {
    return CookingConstraints(
      equipment: equipment == const $CopyWithPlaceholder()
          ? _value.equipment
          // ignore: cast_nullable_to_non_nullable
          : equipment as List<String>?,
      householdServings: householdServings == const $CopyWithPlaceholder()
          ? _value.householdServings
          // ignore: cast_nullable_to_non_nullable
          : householdServings as int?,
      mealTemplates: mealTemplates == const $CopyWithPlaceholder()
          ? _value.mealTemplates
          // ignore: cast_nullable_to_non_nullable
          : mealTemplates as List<CookingMealTemplate>?,
      mealTimes: mealTimes == const $CopyWithPlaceholder()
          ? _value.mealTimes
          // ignore: cast_nullable_to_non_nullable
          : mealTimes as List<CookingMealTime>?,
    );
  }
}

extension $CookingConstraintsCopyWith on CookingConstraints {
  /// Returns a callable class that can be used as follows: `instanceOfCookingConstraints.copyWith(...)` or like so:`instanceOfCookingConstraints.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingConstraintsCWProxy get copyWith =>
      _$CookingConstraintsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingConstraints _$CookingConstraintsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CookingConstraints',
      json,
      ($checkedConvert) {
        final val = CookingConstraints(
          equipment: $checkedConvert(
            'equipment',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          householdServings: $checkedConvert(
            'household_servings',
            (v) => (v as num?)?.toInt(),
          ),
          mealTemplates: $checkedConvert(
            'meal_templates',
            (v) => (v as List<dynamic>?)
                ?.map(
                  (e) =>
                      CookingMealTemplate.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          mealTimes: $checkedConvert(
            'meal_times',
            (v) => (v as List<dynamic>?)
                ?.map(
                  (e) => CookingMealTime.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'householdServings': 'household_servings',
        'mealTemplates': 'meal_templates',
        'mealTimes': 'meal_times',
      },
    );

Map<String, dynamic> _$CookingConstraintsToJson(
  CookingConstraints instance,
) => <String, dynamic>{
  'equipment': ?instance.equipment,
  'household_servings': ?instance.householdServings,
  'meal_templates': ?instance.mealTemplates?.map((e) => e.toJson()).toList(),
  'meal_times': ?instance.mealTimes?.map((e) => e.toJson()).toList(),
};
