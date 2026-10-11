// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_avoidance_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyAvoidanceOutCWProxy {
  FamilyAvoidanceOut category(String? category);

  FamilyAvoidanceOut ingredientId(String? ingredientId);

  FamilyAvoidanceOut name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAvoidanceOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAvoidanceOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAvoidanceOut call({
    String? category,
    String? ingredientId,
    String name,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyAvoidanceOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyAvoidanceOut.copyWith.fieldName(...)`
class _$FamilyAvoidanceOutCWProxyImpl implements _$FamilyAvoidanceOutCWProxy {
  const _$FamilyAvoidanceOutCWProxyImpl(this._value);

  final FamilyAvoidanceOut _value;

  @override
  FamilyAvoidanceOut category(String? category) => this(category: category);

  @override
  FamilyAvoidanceOut ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  FamilyAvoidanceOut name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAvoidanceOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAvoidanceOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAvoidanceOut call({
    Object? category = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return FamilyAvoidanceOut(
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
    );
  }
}

extension $FamilyAvoidanceOutCopyWith on FamilyAvoidanceOut {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyAvoidanceOut.copyWith(...)` or like so:`instanceOfFamilyAvoidanceOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyAvoidanceOutCWProxy get copyWith =>
      _$FamilyAvoidanceOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyAvoidanceOut _$FamilyAvoidanceOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FamilyAvoidanceOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = FamilyAvoidanceOut(
        category: $checkedConvert('category', (v) => v as String?),
        ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$FamilyAvoidanceOutToJson(FamilyAvoidanceOut instance) =>
    <String, dynamic>{
      'category': ?instance.category,
      'ingredient_id': ?instance.ingredientId,
      'name': instance.name,
    };
