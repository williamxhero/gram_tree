// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_derived.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeDerivedCWProxy {
  RecipeDerived activeTimeSeconds(int activeTimeSeconds);

  RecipeDerived allergens(List<String>? allergens);

  RecipeDerived allergensIncomplete(bool? allergensIncomplete);

  RecipeDerived cookware(List<String>? cookware);

  RecipeDerived nutritionPerServing(NutritionEstimate? nutritionPerServing);

  RecipeDerived totalTimeSeconds(int totalTimeSeconds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeDerived(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeDerived(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeDerived call({
    int activeTimeSeconds,
    List<String>? allergens,
    bool? allergensIncomplete,
    List<String>? cookware,
    NutritionEstimate? nutritionPerServing,
    int totalTimeSeconds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeDerived.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeDerived.copyWith.fieldName(...)`
class _$RecipeDerivedCWProxyImpl implements _$RecipeDerivedCWProxy {
  const _$RecipeDerivedCWProxyImpl(this._value);

  final RecipeDerived _value;

  @override
  RecipeDerived activeTimeSeconds(int activeTimeSeconds) =>
      this(activeTimeSeconds: activeTimeSeconds);

  @override
  RecipeDerived allergens(List<String>? allergens) =>
      this(allergens: allergens);

  @override
  RecipeDerived allergensIncomplete(bool? allergensIncomplete) =>
      this(allergensIncomplete: allergensIncomplete);

  @override
  RecipeDerived cookware(List<String>? cookware) => this(cookware: cookware);

  @override
  RecipeDerived nutritionPerServing(NutritionEstimate? nutritionPerServing) =>
      this(nutritionPerServing: nutritionPerServing);

  @override
  RecipeDerived totalTimeSeconds(int totalTimeSeconds) =>
      this(totalTimeSeconds: totalTimeSeconds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeDerived(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeDerived(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeDerived call({
    Object? activeTimeSeconds = const $CopyWithPlaceholder(),
    Object? allergens = const $CopyWithPlaceholder(),
    Object? allergensIncomplete = const $CopyWithPlaceholder(),
    Object? cookware = const $CopyWithPlaceholder(),
    Object? nutritionPerServing = const $CopyWithPlaceholder(),
    Object? totalTimeSeconds = const $CopyWithPlaceholder(),
  }) {
    return RecipeDerived(
      activeTimeSeconds: activeTimeSeconds == const $CopyWithPlaceholder()
          ? _value.activeTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : activeTimeSeconds as int,
      allergens: allergens == const $CopyWithPlaceholder()
          ? _value.allergens
          // ignore: cast_nullable_to_non_nullable
          : allergens as List<String>?,
      allergensIncomplete: allergensIncomplete == const $CopyWithPlaceholder()
          ? _value.allergensIncomplete
          // ignore: cast_nullable_to_non_nullable
          : allergensIncomplete as bool?,
      cookware: cookware == const $CopyWithPlaceholder()
          ? _value.cookware
          // ignore: cast_nullable_to_non_nullable
          : cookware as List<String>?,
      nutritionPerServing: nutritionPerServing == const $CopyWithPlaceholder()
          ? _value.nutritionPerServing
          // ignore: cast_nullable_to_non_nullable
          : nutritionPerServing as NutritionEstimate?,
      totalTimeSeconds: totalTimeSeconds == const $CopyWithPlaceholder()
          ? _value.totalTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : totalTimeSeconds as int,
    );
  }
}

extension $RecipeDerivedCopyWith on RecipeDerived {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeDerived.copyWith(...)` or like so:`instanceOfRecipeDerived.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeDerivedCWProxy get copyWith => _$RecipeDerivedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeDerived _$RecipeDerivedFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeDerived',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['active_time_seconds', 'total_time_seconds'],
        );
        final val = RecipeDerived(
          activeTimeSeconds: $checkedConvert(
            'active_time_seconds',
            (v) => (v as num).toInt(),
          ),
          allergens: $checkedConvert(
            'allergens',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          allergensIncomplete: $checkedConvert(
            'allergens_incomplete',
            (v) => v as bool? ?? false,
          ),
          cookware: $checkedConvert(
            'cookware',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          nutritionPerServing: $checkedConvert(
            'nutrition_per_serving',
            (v) => v == null
                ? null
                : NutritionEstimate.fromJson(v as Map<String, dynamic>),
          ),
          totalTimeSeconds: $checkedConvert(
            'total_time_seconds',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'activeTimeSeconds': 'active_time_seconds',
        'allergensIncomplete': 'allergens_incomplete',
        'nutritionPerServing': 'nutrition_per_serving',
        'totalTimeSeconds': 'total_time_seconds',
      },
    );

Map<String, dynamic> _$RecipeDerivedToJson(RecipeDerived instance) =>
    <String, dynamic>{
      'active_time_seconds': instance.activeTimeSeconds,
      'allergens': ?instance.allergens,
      'allergens_incomplete': ?instance.allergensIncomplete,
      'cookware': ?instance.cookware,
      'nutrition_per_serving': ?instance.nutritionPerServing?.toJson(),
      'total_time_seconds': instance.totalTimeSeconds,
    };
