// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_allergies_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyAllergiesOutCWProxy {
  FamilyAllergiesOut categories(List<String> categories);

  FamilyAllergiesOut ingredients(List<AllergyIngredientOut> ingredients);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAllergiesOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAllergiesOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAllergiesOut call({
    List<String> categories,
    List<AllergyIngredientOut> ingredients,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyAllergiesOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyAllergiesOut.copyWith.fieldName(...)`
class _$FamilyAllergiesOutCWProxyImpl implements _$FamilyAllergiesOutCWProxy {
  const _$FamilyAllergiesOutCWProxyImpl(this._value);

  final FamilyAllergiesOut _value;

  @override
  FamilyAllergiesOut categories(List<String> categories) =>
      this(categories: categories);

  @override
  FamilyAllergiesOut ingredients(List<AllergyIngredientOut> ingredients) =>
      this(ingredients: ingredients);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAllergiesOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAllergiesOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAllergiesOut call({
    Object? categories = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
  }) {
    return FamilyAllergiesOut(
      categories: categories == const $CopyWithPlaceholder()
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<String>,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<AllergyIngredientOut>,
    );
  }
}

extension $FamilyAllergiesOutCopyWith on FamilyAllergiesOut {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyAllergiesOut.copyWith(...)` or like so:`instanceOfFamilyAllergiesOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyAllergiesOutCWProxy get copyWith =>
      _$FamilyAllergiesOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyAllergiesOut _$FamilyAllergiesOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FamilyAllergiesOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['categories', 'ingredients']);
      final val = FamilyAllergiesOut(
        categories: $checkedConvert(
          'categories',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        ingredients: $checkedConvert(
          'ingredients',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AllergyIngredientOut.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FamilyAllergiesOutToJson(FamilyAllergiesOut instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
    };
