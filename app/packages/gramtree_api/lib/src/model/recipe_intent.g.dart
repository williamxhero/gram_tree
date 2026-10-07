// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_intent.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeIntentCWProxy {
  RecipeIntent cookware(List<String>? cookware);

  RecipeIntent dishName(String dishName);

  RecipeIntent restrictions(List<String>? restrictions);

  RecipeIntent servings(int? servings);

  RecipeIntent taste(List<String>? taste);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIntent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIntent(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIntent call({
    List<String>? cookware,
    String dishName,
    List<String>? restrictions,
    int? servings,
    List<String>? taste,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeIntent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeIntent.copyWith.fieldName(...)`
class _$RecipeIntentCWProxyImpl implements _$RecipeIntentCWProxy {
  const _$RecipeIntentCWProxyImpl(this._value);

  final RecipeIntent _value;

  @override
  RecipeIntent cookware(List<String>? cookware) => this(cookware: cookware);

  @override
  RecipeIntent dishName(String dishName) => this(dishName: dishName);

  @override
  RecipeIntent restrictions(List<String>? restrictions) =>
      this(restrictions: restrictions);

  @override
  RecipeIntent servings(int? servings) => this(servings: servings);

  @override
  RecipeIntent taste(List<String>? taste) => this(taste: taste);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIntent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIntent(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIntent call({
    Object? cookware = const $CopyWithPlaceholder(),
    Object? dishName = const $CopyWithPlaceholder(),
    Object? restrictions = const $CopyWithPlaceholder(),
    Object? servings = const $CopyWithPlaceholder(),
    Object? taste = const $CopyWithPlaceholder(),
  }) {
    return RecipeIntent(
      cookware: cookware == const $CopyWithPlaceholder()
          ? _value.cookware
          // ignore: cast_nullable_to_non_nullable
          : cookware as List<String>?,
      dishName: dishName == const $CopyWithPlaceholder()
          ? _value.dishName
          // ignore: cast_nullable_to_non_nullable
          : dishName as String,
      restrictions: restrictions == const $CopyWithPlaceholder()
          ? _value.restrictions
          // ignore: cast_nullable_to_non_nullable
          : restrictions as List<String>?,
      servings: servings == const $CopyWithPlaceholder()
          ? _value.servings
          // ignore: cast_nullable_to_non_nullable
          : servings as int?,
      taste: taste == const $CopyWithPlaceholder()
          ? _value.taste
          // ignore: cast_nullable_to_non_nullable
          : taste as List<String>?,
    );
  }
}

extension $RecipeIntentCopyWith on RecipeIntent {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeIntent.copyWith(...)` or like so:`instanceOfRecipeIntent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeIntentCWProxy get copyWith => _$RecipeIntentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIntent _$RecipeIntentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecipeIntent', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['dish_name']);
      final val = RecipeIntent(
        cookware: $checkedConvert(
          'cookware',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        dishName: $checkedConvert('dish_name', (v) => v as String),
        restrictions: $checkedConvert(
          'restrictions',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        servings: $checkedConvert('servings', (v) => (v as num?)?.toInt()),
        taste: $checkedConvert(
          'taste',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'dishName': 'dish_name'});

Map<String, dynamic> _$RecipeIntentToJson(RecipeIntent instance) =>
    <String, dynamic>{
      'cookware': ?instance.cookware,
      'dish_name': instance.dishName,
      'restrictions': ?instance.restrictions,
      'servings': ?instance.servings,
      'taste': ?instance.taste,
    };
