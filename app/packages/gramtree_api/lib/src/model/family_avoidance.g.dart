// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_avoidance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyAvoidanceCWProxy {
  FamilyAvoidance category(String? category);

  FamilyAvoidance ingredientId(String? ingredientId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAvoidance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAvoidance(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAvoidance call({String? category, String? ingredientId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyAvoidance.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyAvoidance.copyWith.fieldName(...)`
class _$FamilyAvoidanceCWProxyImpl implements _$FamilyAvoidanceCWProxy {
  const _$FamilyAvoidanceCWProxyImpl(this._value);

  final FamilyAvoidance _value;

  @override
  FamilyAvoidance category(String? category) => this(category: category);

  @override
  FamilyAvoidance ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyAvoidance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyAvoidance(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyAvoidance call({
    Object? category = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
  }) {
    return FamilyAvoidance(
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String?,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
    );
  }
}

extension $FamilyAvoidanceCopyWith on FamilyAvoidance {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyAvoidance.copyWith(...)` or like so:`instanceOfFamilyAvoidance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyAvoidanceCWProxy get copyWith => _$FamilyAvoidanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyAvoidance _$FamilyAvoidanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FamilyAvoidance', json, ($checkedConvert) {
      final val = FamilyAvoidance(
        category: $checkedConvert('category', (v) => v as String?),
        ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$FamilyAvoidanceToJson(FamilyAvoidance instance) =>
    <String, dynamic>{
      'category': ?instance.category,
      'ingredient_id': ?instance.ingredientId,
    };
