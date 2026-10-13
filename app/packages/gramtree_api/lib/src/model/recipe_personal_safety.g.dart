// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_personal_safety.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipePersonalSafetyCWProxy {
  RecipePersonalSafety alerts(List<RecipePersonalSafetyAlert>? alerts);

  RecipePersonalSafety incomplete(bool? incomplete);

  RecipePersonalSafety status(RecipePersonalSafetyStatusEnum status);

  RecipePersonalSafety unknownIngredients(List<String>? unknownIngredients);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipePersonalSafety(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipePersonalSafety(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipePersonalSafety call({
    List<RecipePersonalSafetyAlert>? alerts,
    bool? incomplete,
    RecipePersonalSafetyStatusEnum status,
    List<String>? unknownIngredients,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipePersonalSafety.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipePersonalSafety.copyWith.fieldName(...)`
class _$RecipePersonalSafetyCWProxyImpl
    implements _$RecipePersonalSafetyCWProxy {
  const _$RecipePersonalSafetyCWProxyImpl(this._value);

  final RecipePersonalSafety _value;

  @override
  RecipePersonalSafety alerts(List<RecipePersonalSafetyAlert>? alerts) =>
      this(alerts: alerts);

  @override
  RecipePersonalSafety incomplete(bool? incomplete) =>
      this(incomplete: incomplete);

  @override
  RecipePersonalSafety status(RecipePersonalSafetyStatusEnum status) =>
      this(status: status);

  @override
  RecipePersonalSafety unknownIngredients(List<String>? unknownIngredients) =>
      this(unknownIngredients: unknownIngredients);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipePersonalSafety(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipePersonalSafety(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipePersonalSafety call({
    Object? alerts = const $CopyWithPlaceholder(),
    Object? incomplete = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? unknownIngredients = const $CopyWithPlaceholder(),
  }) {
    return RecipePersonalSafety(
      alerts: alerts == const $CopyWithPlaceholder()
          ? _value.alerts
          // ignore: cast_nullable_to_non_nullable
          : alerts as List<RecipePersonalSafetyAlert>?,
      incomplete: incomplete == const $CopyWithPlaceholder()
          ? _value.incomplete
          // ignore: cast_nullable_to_non_nullable
          : incomplete as bool?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecipePersonalSafetyStatusEnum,
      unknownIngredients: unknownIngredients == const $CopyWithPlaceholder()
          ? _value.unknownIngredients
          // ignore: cast_nullable_to_non_nullable
          : unknownIngredients as List<String>?,
    );
  }
}

extension $RecipePersonalSafetyCopyWith on RecipePersonalSafety {
  /// Returns a callable class that can be used as follows: `instanceOfRecipePersonalSafety.copyWith(...)` or like so:`instanceOfRecipePersonalSafety.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipePersonalSafetyCWProxy get copyWith =>
      _$RecipePersonalSafetyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipePersonalSafety _$RecipePersonalSafetyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipePersonalSafety', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = RecipePersonalSafety(
    alerts: $checkedConvert(
      'alerts',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) =>
                RecipePersonalSafetyAlert.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    incomplete: $checkedConvert('incomplete', (v) => v as bool? ?? false),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecipePersonalSafetyStatusEnumEnumMap, v),
    ),
    unknownIngredients: $checkedConvert(
      'unknown_ingredients',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'unknownIngredients': 'unknown_ingredients'});

Map<String, dynamic> _$RecipePersonalSafetyToJson(
  RecipePersonalSafety instance,
) => <String, dynamic>{
  'alerts': ?instance.alerts?.map((e) => e.toJson()).toList(),
  'incomplete': ?instance.incomplete,
  'status': _$RecipePersonalSafetyStatusEnumEnumMap[instance.status]!,
  'unknown_ingredients': ?instance.unknownIngredients,
};

const _$RecipePersonalSafetyStatusEnumEnumMap = {
  RecipePersonalSafetyStatusEnum.available: 'available',
  RecipePersonalSafetyStatusEnum.notAuthorized: 'not_authorized',
};
