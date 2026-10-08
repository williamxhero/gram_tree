// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_reproducibility_check_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeReproducibilityCheckRequestCWProxy {
  RecipeReproducibilityCheckRequest snapshot(RecipeSnapshot snapshot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReproducibilityCheckRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReproducibilityCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReproducibilityCheckRequest call({RecipeSnapshot snapshot});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeReproducibilityCheckRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeReproducibilityCheckRequest.copyWith.fieldName(...)`
class _$RecipeReproducibilityCheckRequestCWProxyImpl
    implements _$RecipeReproducibilityCheckRequestCWProxy {
  const _$RecipeReproducibilityCheckRequestCWProxyImpl(this._value);

  final RecipeReproducibilityCheckRequest _value;

  @override
  RecipeReproducibilityCheckRequest snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReproducibilityCheckRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReproducibilityCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReproducibilityCheckRequest call({
    Object? snapshot = const $CopyWithPlaceholder(),
  }) {
    return RecipeReproducibilityCheckRequest(
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
    );
  }
}

extension $RecipeReproducibilityCheckRequestCopyWith
    on RecipeReproducibilityCheckRequest {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeReproducibilityCheckRequest.copyWith(...)` or like so:`instanceOfRecipeReproducibilityCheckRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeReproducibilityCheckRequestCWProxy get copyWith =>
      _$RecipeReproducibilityCheckRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeReproducibilityCheckRequest _$RecipeReproducibilityCheckRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeReproducibilityCheckRequest', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['snapshot']);
  final val = RecipeReproducibilityCheckRequest(
    snapshot: $checkedConvert(
      'snapshot',
      (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecipeReproducibilityCheckRequestToJson(
  RecipeReproducibilityCheckRequest instance,
) => <String, dynamic>{'snapshot': instance.snapshot.toJson()};
