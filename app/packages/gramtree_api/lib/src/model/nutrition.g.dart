// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NutritionCWProxy {
  Nutrition carbohydrateG(num? carbohydrateG);

  Nutrition energyKcal(num? energyKcal);

  Nutrition fatG(num? fatG);

  Nutrition proteinG(num? proteinG);

  Nutrition sodiumMg(num? sodiumMg);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Nutrition(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Nutrition(...).copyWith(id: 12, name: "My name")
  /// ````
  Nutrition call({
    num? carbohydrateG,
    num? energyKcal,
    num? fatG,
    num? proteinG,
    num? sodiumMg,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNutrition.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNutrition.copyWith.fieldName(...)`
class _$NutritionCWProxyImpl implements _$NutritionCWProxy {
  const _$NutritionCWProxyImpl(this._value);

  final Nutrition _value;

  @override
  Nutrition carbohydrateG(num? carbohydrateG) =>
      this(carbohydrateG: carbohydrateG);

  @override
  Nutrition energyKcal(num? energyKcal) => this(energyKcal: energyKcal);

  @override
  Nutrition fatG(num? fatG) => this(fatG: fatG);

  @override
  Nutrition proteinG(num? proteinG) => this(proteinG: proteinG);

  @override
  Nutrition sodiumMg(num? sodiumMg) => this(sodiumMg: sodiumMg);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Nutrition(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Nutrition(...).copyWith(id: 12, name: "My name")
  /// ````
  Nutrition call({
    Object? carbohydrateG = const $CopyWithPlaceholder(),
    Object? energyKcal = const $CopyWithPlaceholder(),
    Object? fatG = const $CopyWithPlaceholder(),
    Object? proteinG = const $CopyWithPlaceholder(),
    Object? sodiumMg = const $CopyWithPlaceholder(),
  }) {
    return Nutrition(
      carbohydrateG: carbohydrateG == const $CopyWithPlaceholder()
          ? _value.carbohydrateG
          // ignore: cast_nullable_to_non_nullable
          : carbohydrateG as num?,
      energyKcal: energyKcal == const $CopyWithPlaceholder()
          ? _value.energyKcal
          // ignore: cast_nullable_to_non_nullable
          : energyKcal as num?,
      fatG: fatG == const $CopyWithPlaceholder()
          ? _value.fatG
          // ignore: cast_nullable_to_non_nullable
          : fatG as num?,
      proteinG: proteinG == const $CopyWithPlaceholder()
          ? _value.proteinG
          // ignore: cast_nullable_to_non_nullable
          : proteinG as num?,
      sodiumMg: sodiumMg == const $CopyWithPlaceholder()
          ? _value.sodiumMg
          // ignore: cast_nullable_to_non_nullable
          : sodiumMg as num?,
    );
  }
}

extension $NutritionCopyWith on Nutrition {
  /// Returns a callable class that can be used as follows: `instanceOfNutrition.copyWith(...)` or like so:`instanceOfNutrition.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NutritionCWProxy get copyWith => _$NutritionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Nutrition _$NutritionFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Nutrition',
  json,
  ($checkedConvert) {
    final val = Nutrition(
      carbohydrateG: $checkedConvert('carbohydrate_g', (v) => v as num?),
      energyKcal: $checkedConvert('energy_kcal', (v) => v as num?),
      fatG: $checkedConvert('fat_g', (v) => v as num?),
      proteinG: $checkedConvert('protein_g', (v) => v as num?),
      sodiumMg: $checkedConvert('sodium_mg', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {
    'carbohydrateG': 'carbohydrate_g',
    'energyKcal': 'energy_kcal',
    'fatG': 'fat_g',
    'proteinG': 'protein_g',
    'sodiumMg': 'sodium_mg',
  },
);

Map<String, dynamic> _$NutritionToJson(Nutrition instance) => <String, dynamic>{
  'carbohydrate_g': ?instance.carbohydrateG,
  'energy_kcal': ?instance.energyKcal,
  'fat_g': ?instance.fatG,
  'protein_g': ?instance.proteinG,
  'sodium_mg': ?instance.sodiumMg,
};
