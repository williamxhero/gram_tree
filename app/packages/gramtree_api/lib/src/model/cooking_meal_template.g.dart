// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_meal_template.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingMealTemplateCWProxy {
  CookingMealTemplate composition(
    List<CookingMealTemplateCompositionEnum> composition,
  );

  CookingMealTemplate dayType(CookingMealTemplateDayTypeEnum dayType);

  CookingMealTemplate dishCount(int dishCount);

  CookingMealTemplate meal(CookingMealTemplateMealEnum meal);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingMealTemplate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingMealTemplate(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingMealTemplate call({
    List<CookingMealTemplateCompositionEnum> composition,
    CookingMealTemplateDayTypeEnum dayType,
    int dishCount,
    CookingMealTemplateMealEnum meal,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingMealTemplate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingMealTemplate.copyWith.fieldName(...)`
class _$CookingMealTemplateCWProxyImpl implements _$CookingMealTemplateCWProxy {
  const _$CookingMealTemplateCWProxyImpl(this._value);

  final CookingMealTemplate _value;

  @override
  CookingMealTemplate composition(
    List<CookingMealTemplateCompositionEnum> composition,
  ) => this(composition: composition);

  @override
  CookingMealTemplate dayType(CookingMealTemplateDayTypeEnum dayType) =>
      this(dayType: dayType);

  @override
  CookingMealTemplate dishCount(int dishCount) => this(dishCount: dishCount);

  @override
  CookingMealTemplate meal(CookingMealTemplateMealEnum meal) =>
      this(meal: meal);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingMealTemplate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingMealTemplate(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingMealTemplate call({
    Object? composition = const $CopyWithPlaceholder(),
    Object? dayType = const $CopyWithPlaceholder(),
    Object? dishCount = const $CopyWithPlaceholder(),
    Object? meal = const $CopyWithPlaceholder(),
  }) {
    return CookingMealTemplate(
      composition: composition == const $CopyWithPlaceholder()
          ? _value.composition
          // ignore: cast_nullable_to_non_nullable
          : composition as List<CookingMealTemplateCompositionEnum>,
      dayType: dayType == const $CopyWithPlaceholder()
          ? _value.dayType
          // ignore: cast_nullable_to_non_nullable
          : dayType as CookingMealTemplateDayTypeEnum,
      dishCount: dishCount == const $CopyWithPlaceholder()
          ? _value.dishCount
          // ignore: cast_nullable_to_non_nullable
          : dishCount as int,
      meal: meal == const $CopyWithPlaceholder()
          ? _value.meal
          // ignore: cast_nullable_to_non_nullable
          : meal as CookingMealTemplateMealEnum,
    );
  }
}

extension $CookingMealTemplateCopyWith on CookingMealTemplate {
  /// Returns a callable class that can be used as follows: `instanceOfCookingMealTemplate.copyWith(...)` or like so:`instanceOfCookingMealTemplate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingMealTemplateCWProxy get copyWith =>
      _$CookingMealTemplateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingMealTemplate _$CookingMealTemplateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CookingMealTemplate', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['composition', 'day_type', 'dish_count', 'meal'],
      );
      final val = CookingMealTemplate(
        composition: $checkedConvert(
          'composition',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    $enumDecode(_$CookingMealTemplateCompositionEnumEnumMap, e),
              )
              .toList(),
        ),
        dayType: $checkedConvert(
          'day_type',
          (v) => $enumDecode(_$CookingMealTemplateDayTypeEnumEnumMap, v),
        ),
        dishCount: $checkedConvert('dish_count', (v) => (v as num).toInt()),
        meal: $checkedConvert(
          'meal',
          (v) => $enumDecode(_$CookingMealTemplateMealEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'dayType': 'day_type', 'dishCount': 'dish_count'});

Map<String, dynamic> _$CookingMealTemplateToJson(
  CookingMealTemplate instance,
) => <String, dynamic>{
  'composition': instance.composition
      .map((e) => _$CookingMealTemplateCompositionEnumEnumMap[e]!)
      .toList(),
  'day_type': _$CookingMealTemplateDayTypeEnumEnumMap[instance.dayType]!,
  'dish_count': instance.dishCount,
  'meal': _$CookingMealTemplateMealEnumEnumMap[instance.meal]!,
};

const _$CookingMealTemplateCompositionEnumEnumMap = {
  CookingMealTemplateCompositionEnum.meat: 'meat',
  CookingMealTemplateCompositionEnum.vegetable: 'vegetable',
  CookingMealTemplateCompositionEnum.soup: 'soup',
  CookingMealTemplateCompositionEnum.staple: 'staple',
  CookingMealTemplateCompositionEnum.other: 'other',
};

const _$CookingMealTemplateDayTypeEnumEnumMap = {
  CookingMealTemplateDayTypeEnum.weekday: 'weekday',
  CookingMealTemplateDayTypeEnum.weekend: 'weekend',
};

const _$CookingMealTemplateMealEnumEnumMap = {
  CookingMealTemplateMealEnum.breakfast: 'breakfast',
  CookingMealTemplateMealEnum.lunch: 'lunch',
  CookingMealTemplateMealEnum.dinner: 'dinner',
};
