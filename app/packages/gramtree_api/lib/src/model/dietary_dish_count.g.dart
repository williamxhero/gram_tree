// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dietary_dish_count.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DietaryDishCountCWProxy {
  DietaryDishCount count(int count);

  DietaryDishCount dishId(String dishId);

  DietaryDishCount firstCookedAt(String firstCookedAt);

  DietaryDishCount name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DietaryDishCount(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DietaryDishCount(...).copyWith(id: 12, name: "My name")
  /// ````
  DietaryDishCount call({
    int count,
    String dishId,
    String firstCookedAt,
    String name,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDietaryDishCount.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDietaryDishCount.copyWith.fieldName(...)`
class _$DietaryDishCountCWProxyImpl implements _$DietaryDishCountCWProxy {
  const _$DietaryDishCountCWProxyImpl(this._value);

  final DietaryDishCount _value;

  @override
  DietaryDishCount count(int count) => this(count: count);

  @override
  DietaryDishCount dishId(String dishId) => this(dishId: dishId);

  @override
  DietaryDishCount firstCookedAt(String firstCookedAt) =>
      this(firstCookedAt: firstCookedAt);

  @override
  DietaryDishCount name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DietaryDishCount(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DietaryDishCount(...).copyWith(id: 12, name: "My name")
  /// ````
  DietaryDishCount call({
    Object? count = const $CopyWithPlaceholder(),
    Object? dishId = const $CopyWithPlaceholder(),
    Object? firstCookedAt = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return DietaryDishCount(
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      dishId: dishId == const $CopyWithPlaceholder()
          ? _value.dishId
          // ignore: cast_nullable_to_non_nullable
          : dishId as String,
      firstCookedAt: firstCookedAt == const $CopyWithPlaceholder()
          ? _value.firstCookedAt
          // ignore: cast_nullable_to_non_nullable
          : firstCookedAt as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $DietaryDishCountCopyWith on DietaryDishCount {
  /// Returns a callable class that can be used as follows: `instanceOfDietaryDishCount.copyWith(...)` or like so:`instanceOfDietaryDishCount.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DietaryDishCountCWProxy get copyWith => _$DietaryDishCountCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DietaryDishCount _$DietaryDishCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DietaryDishCount',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['count', 'dish_id', 'first_cooked_at', 'name'],
        );
        final val = DietaryDishCount(
          count: $checkedConvert('count', (v) => (v as num).toInt()),
          dishId: $checkedConvert('dish_id', (v) => v as String),
          firstCookedAt: $checkedConvert('first_cooked_at', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'dishId': 'dish_id',
        'firstCookedAt': 'first_cooked_at',
      },
    );

Map<String, dynamic> _$DietaryDishCountToJson(DietaryDishCount instance) =>
    <String, dynamic>{
      'count': instance.count,
      'dish_id': instance.dishId,
      'first_cooked_at': instance.firstCookedAt,
      'name': instance.name,
    };
