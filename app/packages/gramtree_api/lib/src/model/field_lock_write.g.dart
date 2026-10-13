// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_lock_write.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FieldLockWriteCWProxy {
  FieldLockWrite field(String field);

  FieldLockWrite locked(bool locked);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FieldLockWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FieldLockWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  FieldLockWrite call({String field, bool locked});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFieldLockWrite.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFieldLockWrite.copyWith.fieldName(...)`
class _$FieldLockWriteCWProxyImpl implements _$FieldLockWriteCWProxy {
  const _$FieldLockWriteCWProxyImpl(this._value);

  final FieldLockWrite _value;

  @override
  FieldLockWrite field(String field) => this(field: field);

  @override
  FieldLockWrite locked(bool locked) => this(locked: locked);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FieldLockWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FieldLockWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  FieldLockWrite call({
    Object? field = const $CopyWithPlaceholder(),
    Object? locked = const $CopyWithPlaceholder(),
  }) {
    return FieldLockWrite(
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      locked: locked == const $CopyWithPlaceholder()
          ? _value.locked
          // ignore: cast_nullable_to_non_nullable
          : locked as bool,
    );
  }
}

extension $FieldLockWriteCopyWith on FieldLockWrite {
  /// Returns a callable class that can be used as follows: `instanceOfFieldLockWrite.copyWith(...)` or like so:`instanceOfFieldLockWrite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FieldLockWriteCWProxy get copyWith => _$FieldLockWriteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldLockWrite _$FieldLockWriteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FieldLockWrite', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['field', 'locked']);
      final val = FieldLockWrite(
        field: $checkedConvert('field', (v) => v as String),
        locked: $checkedConvert('locked', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$FieldLockWriteToJson(FieldLockWrite instance) =>
    <String, dynamic>{'field': instance.field, 'locked': instance.locked};
