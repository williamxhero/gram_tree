// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_advice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StorageAdviceCWProxy {
  StorageAdvice days(int days);

  StorageAdvice method(String method);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StorageAdvice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StorageAdvice(...).copyWith(id: 12, name: "My name")
  /// ````
  StorageAdvice call({int days, String method});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStorageAdvice.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStorageAdvice.copyWith.fieldName(...)`
class _$StorageAdviceCWProxyImpl implements _$StorageAdviceCWProxy {
  const _$StorageAdviceCWProxyImpl(this._value);

  final StorageAdvice _value;

  @override
  StorageAdvice days(int days) => this(days: days);

  @override
  StorageAdvice method(String method) => this(method: method);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StorageAdvice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StorageAdvice(...).copyWith(id: 12, name: "My name")
  /// ````
  StorageAdvice call({
    Object? days = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
  }) {
    return StorageAdvice(
      days: days == const $CopyWithPlaceholder()
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as int,
      method: method == const $CopyWithPlaceholder()
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as String,
    );
  }
}

extension $StorageAdviceCopyWith on StorageAdvice {
  /// Returns a callable class that can be used as follows: `instanceOfStorageAdvice.copyWith(...)` or like so:`instanceOfStorageAdvice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StorageAdviceCWProxy get copyWith => _$StorageAdviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageAdvice _$StorageAdviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StorageAdvice', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['days', 'method']);
      final val = StorageAdvice(
        days: $checkedConvert('days', (v) => (v as num).toInt()),
        method: $checkedConvert('method', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$StorageAdviceToJson(StorageAdvice instance) =>
    <String, dynamic>{'days': instance.days, 'method': instance.method};
