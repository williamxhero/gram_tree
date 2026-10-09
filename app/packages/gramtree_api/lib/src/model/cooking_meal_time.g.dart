// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_meal_time.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingMealTimeCWProxy {
  CookingMealTime dayType(CookingMealTimeDayTypeEnum dayType);

  CookingMealTime meal(CookingMealTimeMealEnum meal);

  CookingMealTime minutes(int minutes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingMealTime(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingMealTime(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingMealTime call({
    CookingMealTimeDayTypeEnum dayType,
    CookingMealTimeMealEnum meal,
    int minutes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingMealTime.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingMealTime.copyWith.fieldName(...)`
class _$CookingMealTimeCWProxyImpl implements _$CookingMealTimeCWProxy {
  const _$CookingMealTimeCWProxyImpl(this._value);

  final CookingMealTime _value;

  @override
  CookingMealTime dayType(CookingMealTimeDayTypeEnum dayType) =>
      this(dayType: dayType);

  @override
  CookingMealTime meal(CookingMealTimeMealEnum meal) => this(meal: meal);

  @override
  CookingMealTime minutes(int minutes) => this(minutes: minutes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingMealTime(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingMealTime(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingMealTime call({
    Object? dayType = const $CopyWithPlaceholder(),
    Object? meal = const $CopyWithPlaceholder(),
    Object? minutes = const $CopyWithPlaceholder(),
  }) {
    return CookingMealTime(
      dayType: dayType == const $CopyWithPlaceholder()
          ? _value.dayType
          // ignore: cast_nullable_to_non_nullable
          : dayType as CookingMealTimeDayTypeEnum,
      meal: meal == const $CopyWithPlaceholder()
          ? _value.meal
          // ignore: cast_nullable_to_non_nullable
          : meal as CookingMealTimeMealEnum,
      minutes: minutes == const $CopyWithPlaceholder()
          ? _value.minutes
          // ignore: cast_nullable_to_non_nullable
          : minutes as int,
    );
  }
}

extension $CookingMealTimeCopyWith on CookingMealTime {
  /// Returns a callable class that can be used as follows: `instanceOfCookingMealTime.copyWith(...)` or like so:`instanceOfCookingMealTime.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingMealTimeCWProxy get copyWith => _$CookingMealTimeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingMealTime _$CookingMealTimeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CookingMealTime', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['day_type', 'meal', 'minutes']);
      final val = CookingMealTime(
        dayType: $checkedConvert(
          'day_type',
          (v) => $enumDecode(_$CookingMealTimeDayTypeEnumEnumMap, v),
        ),
        meal: $checkedConvert(
          'meal',
          (v) => $enumDecode(_$CookingMealTimeMealEnumEnumMap, v),
        ),
        minutes: $checkedConvert('minutes', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'dayType': 'day_type'});

Map<String, dynamic> _$CookingMealTimeToJson(CookingMealTime instance) =>
    <String, dynamic>{
      'day_type': _$CookingMealTimeDayTypeEnumEnumMap[instance.dayType]!,
      'meal': _$CookingMealTimeMealEnumEnumMap[instance.meal]!,
      'minutes': instance.minutes,
    };

const _$CookingMealTimeDayTypeEnumEnumMap = {
  CookingMealTimeDayTypeEnum.weekday: 'weekday',
  CookingMealTimeDayTypeEnum.weekend: 'weekend',
};

const _$CookingMealTimeMealEnumEnumMap = {
  CookingMealTimeMealEnum.breakfast: 'breakfast',
  CookingMealTimeMealEnum.lunch: 'lunch',
  CookingMealTimeMealEnum.dinner: 'dinner',
};
