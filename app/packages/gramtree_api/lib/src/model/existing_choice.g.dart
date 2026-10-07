// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'existing_choice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExistingChoiceCWProxy {
  ExistingChoice recipeId(String recipeId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExistingChoice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExistingChoice(...).copyWith(id: 12, name: "My name")
  /// ````
  ExistingChoice call({String recipeId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExistingChoice.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExistingChoice.copyWith.fieldName(...)`
class _$ExistingChoiceCWProxyImpl implements _$ExistingChoiceCWProxy {
  const _$ExistingChoiceCWProxyImpl(this._value);

  final ExistingChoice _value;

  @override
  ExistingChoice recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExistingChoice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExistingChoice(...).copyWith(id: 12, name: "My name")
  /// ````
  ExistingChoice call({Object? recipeId = const $CopyWithPlaceholder()}) {
    return ExistingChoice(
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
    );
  }
}

extension $ExistingChoiceCopyWith on ExistingChoice {
  /// Returns a callable class that can be used as follows: `instanceOfExistingChoice.copyWith(...)` or like so:`instanceOfExistingChoice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExistingChoiceCWProxy get copyWith => _$ExistingChoiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExistingChoice _$ExistingChoiceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExistingChoice', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['recipe_id']);
      final val = ExistingChoice(
        recipeId: $checkedConvert('recipe_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'recipeId': 'recipe_id'});

Map<String, dynamic> _$ExistingChoiceToJson(ExistingChoice instance) =>
    <String, dynamic>{'recipe_id': instance.recipeId};
