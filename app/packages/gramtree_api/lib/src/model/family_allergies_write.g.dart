// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_allergies_write.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyAllergiesWriteCWProxy {
  FamilyAllergiesWrite categories(List<String>? categories);

  FamilyAllergiesWrite ingredientIds(List<String>? ingredientIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAllergiesWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAllergiesWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAllergiesWrite call({
    List<String>? categories,
    List<String>? ingredientIds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyAllergiesWrite.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyAllergiesWrite.copyWith.fieldName(...)`
class _$FamilyAllergiesWriteCWProxyImpl
    implements _$FamilyAllergiesWriteCWProxy {
  const _$FamilyAllergiesWriteCWProxyImpl(this._value);

  final FamilyAllergiesWrite _value;

  @override
  FamilyAllergiesWrite categories(List<String>? categories) =>
      this(categories: categories);

  @override
  FamilyAllergiesWrite ingredientIds(List<String>? ingredientIds) =>
      this(ingredientIds: ingredientIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAllergiesWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAllergiesWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAllergiesWrite call({
    Object? categories = const $CopyWithPlaceholder(),
    Object? ingredientIds = const $CopyWithPlaceholder(),
  }) {
    return FamilyAllergiesWrite(
      categories: categories == const $CopyWithPlaceholder()
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<String>?,
      ingredientIds: ingredientIds == const $CopyWithPlaceholder()
          ? _value.ingredientIds
          // ignore: cast_nullable_to_non_nullable
          : ingredientIds as List<String>?,
    );
  }
}

extension $FamilyAllergiesWriteCopyWith on FamilyAllergiesWrite {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyAllergiesWrite.copyWith(...)` or like so:`instanceOfFamilyAllergiesWrite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyAllergiesWriteCWProxy get copyWith =>
      _$FamilyAllergiesWriteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyAllergiesWrite _$FamilyAllergiesWriteFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FamilyAllergiesWrite', json, ($checkedConvert) {
  final val = FamilyAllergiesWrite(
    categories: $checkedConvert(
      'categories',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    ingredientIds: $checkedConvert(
      'ingredient_ids',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'ingredientIds': 'ingredient_ids'});

Map<String, dynamic> _$FamilyAllergiesWriteToJson(
  FamilyAllergiesWrite instance,
) => <String, dynamic>{
  'categories': ?instance.categories,
  'ingredient_ids': ?instance.ingredientIds,
};
