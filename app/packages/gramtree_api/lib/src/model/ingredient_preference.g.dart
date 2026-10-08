// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_preference.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IngredientPreferenceCWProxy {
  IngredientPreference category(String? category);

  IngredientPreference ingredientId(String? ingredientId);

  IngredientPreference preference(
    IngredientPreferencePreferenceEnum preference,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientPreference(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientPreference(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientPreference call({
    String? category,
    String? ingredientId,
    IngredientPreferencePreferenceEnum preference,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIngredientPreference.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIngredientPreference.copyWith.fieldName(...)`
class _$IngredientPreferenceCWProxyImpl
    implements _$IngredientPreferenceCWProxy {
  const _$IngredientPreferenceCWProxyImpl(this._value);

  final IngredientPreference _value;

  @override
  IngredientPreference category(String? category) => this(category: category);

  @override
  IngredientPreference ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  IngredientPreference preference(
    IngredientPreferencePreferenceEnum preference,
  ) => this(preference: preference);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientPreference(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientPreference(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientPreference call({
    Object? category = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? preference = const $CopyWithPlaceholder(),
  }) {
    return IngredientPreference(
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String?,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
      preference: preference == const $CopyWithPlaceholder()
          ? _value.preference
          // ignore: cast_nullable_to_non_nullable
          : preference as IngredientPreferencePreferenceEnum,
    );
  }
}

extension $IngredientPreferenceCopyWith on IngredientPreference {
  /// Returns a callable class that can be used as follows: `instanceOfIngredientPreference.copyWith(...)` or like so:`instanceOfIngredientPreference.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IngredientPreferenceCWProxy get copyWith =>
      _$IngredientPreferenceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientPreference _$IngredientPreferenceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('IngredientPreference', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['preference']);
  final val = IngredientPreference(
    category: $checkedConvert('category', (v) => v as String?),
    ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
    preference: $checkedConvert(
      'preference',
      (v) => $enumDecode(_$IngredientPreferencePreferenceEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$IngredientPreferenceToJson(
  IngredientPreference instance,
) => <String, dynamic>{
  'category': ?instance.category,
  'ingredient_id': ?instance.ingredientId,
  'preference':
      _$IngredientPreferencePreferenceEnumEnumMap[instance.preference]!,
};

const _$IngredientPreferencePreferenceEnumEnumMap = {
  IngredientPreferencePreferenceEnum.liked: 'liked',
  IngredientPreferencePreferenceEnum.disliked: 'disliked',
  IngredientPreferencePreferenceEnum.avoided: 'avoided',
};
