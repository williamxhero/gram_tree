// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_cuisine_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalCuisineOutCWProxy {
  LocalCuisineOut adjustments(Map<String, num> adjustments);

  LocalCuisineOut cuisine(String cuisine);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LocalCuisineOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LocalCuisineOut(...).copyWith(id: 12, name: "My name")
  /// ````
  LocalCuisineOut call({Map<String, num> adjustments, String cuisine});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLocalCuisineOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLocalCuisineOut.copyWith.fieldName(...)`
class _$LocalCuisineOutCWProxyImpl implements _$LocalCuisineOutCWProxy {
  const _$LocalCuisineOutCWProxyImpl(this._value);

  final LocalCuisineOut _value;

  @override
  LocalCuisineOut adjustments(Map<String, num> adjustments) =>
      this(adjustments: adjustments);

  @override
  LocalCuisineOut cuisine(String cuisine) => this(cuisine: cuisine);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LocalCuisineOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LocalCuisineOut(...).copyWith(id: 12, name: "My name")
  /// ````
  LocalCuisineOut call({
    Object? adjustments = const $CopyWithPlaceholder(),
    Object? cuisine = const $CopyWithPlaceholder(),
  }) {
    return LocalCuisineOut(
      adjustments: adjustments == const $CopyWithPlaceholder()
          ? _value.adjustments
          // ignore: cast_nullable_to_non_nullable
          : adjustments as Map<String, num>,
      cuisine: cuisine == const $CopyWithPlaceholder()
          ? _value.cuisine
          // ignore: cast_nullable_to_non_nullable
          : cuisine as String,
    );
  }
}

extension $LocalCuisineOutCopyWith on LocalCuisineOut {
  /// Returns a callable class that can be used as follows: `instanceOfLocalCuisineOut.copyWith(...)` or like so:`instanceOfLocalCuisineOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalCuisineOutCWProxy get copyWith => _$LocalCuisineOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalCuisineOut _$LocalCuisineOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LocalCuisineOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['adjustments', 'cuisine']);
      final val = LocalCuisineOut(
        adjustments: $checkedConvert(
          'adjustments',
          (v) => Map<String, num>.from(v as Map),
        ),
        cuisine: $checkedConvert('cuisine', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LocalCuisineOutToJson(LocalCuisineOut instance) =>
    <String, dynamic>{
      'adjustments': instance.adjustments,
      'cuisine': instance.cuisine,
    };
