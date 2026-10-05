// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_safety_check_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeSafetyCheckOutCWProxy {
  RecipeSafetyCheckOut result(RecipeSafetyResult result);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyCheckOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyCheckOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyCheckOut call({RecipeSafetyResult result});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeSafetyCheckOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeSafetyCheckOut.copyWith.fieldName(...)`
class _$RecipeSafetyCheckOutCWProxyImpl
    implements _$RecipeSafetyCheckOutCWProxy {
  const _$RecipeSafetyCheckOutCWProxyImpl(this._value);

  final RecipeSafetyCheckOut _value;

  @override
  RecipeSafetyCheckOut result(RecipeSafetyResult result) =>
      this(result: result);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyCheckOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyCheckOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyCheckOut call({Object? result = const $CopyWithPlaceholder()}) {
    return RecipeSafetyCheckOut(
      result: result == const $CopyWithPlaceholder()
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as RecipeSafetyResult,
    );
  }
}

extension $RecipeSafetyCheckOutCopyWith on RecipeSafetyCheckOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeSafetyCheckOut.copyWith(...)` or like so:`instanceOfRecipeSafetyCheckOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeSafetyCheckOutCWProxy get copyWith =>
      _$RecipeSafetyCheckOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSafetyCheckOut _$RecipeSafetyCheckOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeSafetyCheckOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['result']);
  final val = RecipeSafetyCheckOut(
    result: $checkedConvert(
      'result',
      (v) => RecipeSafetyResult.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecipeSafetyCheckOutToJson(
  RecipeSafetyCheckOut instance,
) => <String, dynamic>{'result': instance.result.toJson()};
