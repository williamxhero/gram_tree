// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_preference_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IngredientPreferenceOutCWProxy {
  IngredientPreferenceOut category(String? category);

  IngredientPreferenceOut ingredientId(String? ingredientId);

  IngredientPreferenceOut name(String name);

  IngredientPreferenceOut preference(
    IngredientPreferenceOutPreferenceEnum preference,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientPreferenceOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientPreferenceOut(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientPreferenceOut call({
    String? category,
    String? ingredientId,
    String name,
    IngredientPreferenceOutPreferenceEnum preference,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIngredientPreferenceOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIngredientPreferenceOut.copyWith.fieldName(...)`
class _$IngredientPreferenceOutCWProxyImpl
    implements _$IngredientPreferenceOutCWProxy {
  const _$IngredientPreferenceOutCWProxyImpl(this._value);

  final IngredientPreferenceOut _value;

  @override
  IngredientPreferenceOut category(String? category) =>
      this(category: category);

  @override
  IngredientPreferenceOut ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  IngredientPreferenceOut name(String name) => this(name: name);

  @override
  IngredientPreferenceOut preference(
    IngredientPreferenceOutPreferenceEnum preference,
  ) => this(preference: preference);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientPreferenceOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientPreferenceOut(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientPreferenceOut call({
    Object? category = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? preference = const $CopyWithPlaceholder(),
  }) {
    return IngredientPreferenceOut(
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String?,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      preference: preference == const $CopyWithPlaceholder()
          ? _value.preference
          // ignore: cast_nullable_to_non_nullable
          : preference as IngredientPreferenceOutPreferenceEnum,
    );
  }
}

extension $IngredientPreferenceOutCopyWith on IngredientPreferenceOut {
  /// Returns a callable class that can be used as follows: `instanceOfIngredientPreferenceOut.copyWith(...)` or like so:`instanceOfIngredientPreferenceOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IngredientPreferenceOutCWProxy get copyWith =>
      _$IngredientPreferenceOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientPreferenceOut _$IngredientPreferenceOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('IngredientPreferenceOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'preference']);
  final val = IngredientPreferenceOut(
    category: $checkedConvert('category', (v) => v as String?),
    ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
    name: $checkedConvert('name', (v) => v as String),
    preference: $checkedConvert(
      'preference',
      (v) => $enumDecode(_$IngredientPreferenceOutPreferenceEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$IngredientPreferenceOutToJson(
  IngredientPreferenceOut instance,
) => <String, dynamic>{
  'category': ?instance.category,
  'ingredient_id': ?instance.ingredientId,
  'name': instance.name,
  'preference':
      _$IngredientPreferenceOutPreferenceEnumEnumMap[instance.preference]!,
};

const _$IngredientPreferenceOutPreferenceEnumEnumMap = {
  IngredientPreferenceOutPreferenceEnum.liked: 'liked',
  IngredientPreferenceOutPreferenceEnum.disliked: 'disliked',
  IngredientPreferenceOutPreferenceEnum.avoided: 'avoided',
};
