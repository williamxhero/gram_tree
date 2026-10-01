// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient_display_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeIngredientDisplayOutCWProxy {
  RecipeIngredientDisplayOut display(RecipeIngredientDisplay display);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientDisplayOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientDisplayOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientDisplayOut call({RecipeIngredientDisplay display});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeIngredientDisplayOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeIngredientDisplayOut.copyWith.fieldName(...)`
class _$RecipeIngredientDisplayOutCWProxyImpl
    implements _$RecipeIngredientDisplayOutCWProxy {
  const _$RecipeIngredientDisplayOutCWProxyImpl(this._value);

  final RecipeIngredientDisplayOut _value;

  @override
  RecipeIngredientDisplayOut display(RecipeIngredientDisplay display) =>
      this(display: display);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientDisplayOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientDisplayOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientDisplayOut call({
    Object? display = const $CopyWithPlaceholder(),
  }) {
    return RecipeIngredientDisplayOut(
      display: display == const $CopyWithPlaceholder()
          ? _value.display
          // ignore: cast_nullable_to_non_nullable
          : display as RecipeIngredientDisplay,
    );
  }
}

extension $RecipeIngredientDisplayOutCopyWith on RecipeIngredientDisplayOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeIngredientDisplayOut.copyWith(...)` or like so:`instanceOfRecipeIngredientDisplayOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeIngredientDisplayOutCWProxy get copyWith =>
      _$RecipeIngredientDisplayOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredientDisplayOut _$RecipeIngredientDisplayOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeIngredientDisplayOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['display']);
  final val = RecipeIngredientDisplayOut(
    display: $checkedConvert(
      'display',
      (v) => RecipeIngredientDisplay.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecipeIngredientDisplayOutToJson(
  RecipeIngredientDisplayOut instance,
) => <String, dynamic>{'display': instance.display.toJson()};
