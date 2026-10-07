// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_reproducibility_check_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeReproducibilityCheckOutCWProxy {
  RecipeReproducibilityCheckOut result(RecipeReproducibilityResult result);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReproducibilityCheckOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReproducibilityCheckOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReproducibilityCheckOut call({RecipeReproducibilityResult result});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeReproducibilityCheckOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeReproducibilityCheckOut.copyWith.fieldName(...)`
class _$RecipeReproducibilityCheckOutCWProxyImpl
    implements _$RecipeReproducibilityCheckOutCWProxy {
  const _$RecipeReproducibilityCheckOutCWProxyImpl(this._value);

  final RecipeReproducibilityCheckOut _value;

  @override
  RecipeReproducibilityCheckOut result(RecipeReproducibilityResult result) =>
      this(result: result);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReproducibilityCheckOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReproducibilityCheckOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReproducibilityCheckOut call({
    Object? result = const $CopyWithPlaceholder(),
  }) {
    return RecipeReproducibilityCheckOut(
      result: result == const $CopyWithPlaceholder()
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as RecipeReproducibilityResult,
    );
  }
}

extension $RecipeReproducibilityCheckOutCopyWith
    on RecipeReproducibilityCheckOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeReproducibilityCheckOut.copyWith(...)` or like so:`instanceOfRecipeReproducibilityCheckOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeReproducibilityCheckOutCWProxy get copyWith =>
      _$RecipeReproducibilityCheckOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeReproducibilityCheckOut _$RecipeReproducibilityCheckOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeReproducibilityCheckOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['result']);
  final val = RecipeReproducibilityCheckOut(
    result: $checkedConvert(
      'result',
      (v) => RecipeReproducibilityResult.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecipeReproducibilityCheckOutToJson(
  RecipeReproducibilityCheckOut instance,
) => <String, dynamic>{'result': instance.result.toJson()};
