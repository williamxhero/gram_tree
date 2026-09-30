// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_estimate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NutritionEstimateCWProxy {
  NutritionEstimate carbohydrateG(num? carbohydrateG);

  NutritionEstimate energyKcal(num? energyKcal);

  NutritionEstimate estimated(bool? estimated);

  NutritionEstimate fatG(num? fatG);

  NutritionEstimate incomplete(bool? incomplete);

  NutritionEstimate proteinG(num? proteinG);

  NutritionEstimate sodiumMg(num? sodiumMg);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NutritionEstimate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NutritionEstimate(...).copyWith(id: 12, name: "My name")
  /// ````
  NutritionEstimate call({
    num? carbohydrateG,
    num? energyKcal,
    bool? estimated,
    num? fatG,
    bool? incomplete,
    num? proteinG,
    num? sodiumMg,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNutritionEstimate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNutritionEstimate.copyWith.fieldName(...)`
class _$NutritionEstimateCWProxyImpl implements _$NutritionEstimateCWProxy {
  const _$NutritionEstimateCWProxyImpl(this._value);

  final NutritionEstimate _value;

  @override
  NutritionEstimate carbohydrateG(num? carbohydrateG) =>
      this(carbohydrateG: carbohydrateG);

  @override
  NutritionEstimate energyKcal(num? energyKcal) => this(energyKcal: energyKcal);

  @override
  NutritionEstimate estimated(bool? estimated) => this(estimated: estimated);

  @override
  NutritionEstimate fatG(num? fatG) => this(fatG: fatG);

  @override
  NutritionEstimate incomplete(bool? incomplete) =>
      this(incomplete: incomplete);

  @override
  NutritionEstimate proteinG(num? proteinG) => this(proteinG: proteinG);

  @override
  NutritionEstimate sodiumMg(num? sodiumMg) => this(sodiumMg: sodiumMg);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NutritionEstimate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NutritionEstimate(...).copyWith(id: 12, name: "My name")
  /// ````
  NutritionEstimate call({
    Object? carbohydrateG = const $CopyWithPlaceholder(),
    Object? energyKcal = const $CopyWithPlaceholder(),
    Object? estimated = const $CopyWithPlaceholder(),
    Object? fatG = const $CopyWithPlaceholder(),
    Object? incomplete = const $CopyWithPlaceholder(),
    Object? proteinG = const $CopyWithPlaceholder(),
    Object? sodiumMg = const $CopyWithPlaceholder(),
  }) {
    return NutritionEstimate(
      carbohydrateG: carbohydrateG == const $CopyWithPlaceholder()
          ? _value.carbohydrateG
          // ignore: cast_nullable_to_non_nullable
          : carbohydrateG as num?,
      energyKcal: energyKcal == const $CopyWithPlaceholder()
          ? _value.energyKcal
          // ignore: cast_nullable_to_non_nullable
          : energyKcal as num?,
      estimated: estimated == const $CopyWithPlaceholder()
          ? _value.estimated
          // ignore: cast_nullable_to_non_nullable
          : estimated as bool?,
      fatG: fatG == const $CopyWithPlaceholder()
          ? _value.fatG
          // ignore: cast_nullable_to_non_nullable
          : fatG as num?,
      incomplete: incomplete == const $CopyWithPlaceholder()
          ? _value.incomplete
          // ignore: cast_nullable_to_non_nullable
          : incomplete as bool?,
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

extension $NutritionEstimateCopyWith on NutritionEstimate {
  /// Returns a callable class that can be used as follows: `instanceOfNutritionEstimate.copyWith(...)` or like so:`instanceOfNutritionEstimate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NutritionEstimateCWProxy get copyWith =>
      _$NutritionEstimateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutritionEstimate _$NutritionEstimateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NutritionEstimate',
      json,
      ($checkedConvert) {
        final val = NutritionEstimate(
          carbohydrateG: $checkedConvert('carbohydrate_g', (v) => v as num?),
          energyKcal: $checkedConvert('energy_kcal', (v) => v as num?),
          estimated: $checkedConvert('estimated', (v) => v as bool? ?? true),
          fatG: $checkedConvert('fat_g', (v) => v as num?),
          incomplete: $checkedConvert('incomplete', (v) => v as bool? ?? false),
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

Map<String, dynamic> _$NutritionEstimateToJson(NutritionEstimate instance) =>
    <String, dynamic>{
      'carbohydrate_g': ?instance.carbohydrateG,
      'energy_kcal': ?instance.energyKcal,
      'estimated': ?instance.estimated,
      'fat_g': ?instance.fatG,
      'incomplete': ?instance.incomplete,
      'protein_g': ?instance.proteinG,
      'sodium_mg': ?instance.sodiumMg,
    };
