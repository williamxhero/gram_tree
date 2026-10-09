// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergy_ingredient_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AllergyIngredientOutCWProxy {
  AllergyIngredientOut ingredientId(String ingredientId);

  AllergyIngredientOut name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergyIngredientOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergyIngredientOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergyIngredientOut call({String ingredientId, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAllergyIngredientOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAllergyIngredientOut.copyWith.fieldName(...)`
class _$AllergyIngredientOutCWProxyImpl
    implements _$AllergyIngredientOutCWProxy {
  const _$AllergyIngredientOutCWProxyImpl(this._value);

  final AllergyIngredientOut _value;

  @override
  AllergyIngredientOut ingredientId(String ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  AllergyIngredientOut name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergyIngredientOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergyIngredientOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergyIngredientOut call({
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return AllergyIngredientOut(
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $AllergyIngredientOutCopyWith on AllergyIngredientOut {
  /// Returns a callable class that can be used as follows: `instanceOfAllergyIngredientOut.copyWith(...)` or like so:`instanceOfAllergyIngredientOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AllergyIngredientOutCWProxy get copyWith =>
      _$AllergyIngredientOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergyIngredientOut _$AllergyIngredientOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AllergyIngredientOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['ingredient_id', 'name']);
  final val = AllergyIngredientOut(
    ingredientId: $checkedConvert('ingredient_id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$AllergyIngredientOutToJson(
  AllergyIngredientOut instance,
) => <String, dynamic>{
  'ingredient_id': instance.ingredientId,
  'name': instance.name,
};
