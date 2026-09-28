// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'component_reason.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComponentReasonCWProxy {
  ComponentReason code(String code);

  ComponentReason text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentReason(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentReason(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentReason call({String code, String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComponentReason.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComponentReason.copyWith.fieldName(...)`
class _$ComponentReasonCWProxyImpl implements _$ComponentReasonCWProxy {
  const _$ComponentReasonCWProxyImpl(this._value);

  final ComponentReason _value;

  @override
  ComponentReason code(String code) => this(code: code);

  @override
  ComponentReason text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentReason(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentReason(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentReason call({
    Object? code = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return ComponentReason(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $ComponentReasonCopyWith on ComponentReason {
  /// Returns a callable class that can be used as follows: `instanceOfComponentReason.copyWith(...)` or like so:`instanceOfComponentReason.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComponentReasonCWProxy get copyWith => _$ComponentReasonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComponentReason _$ComponentReasonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComponentReason', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'text']);
      final val = ComponentReason(
        code: $checkedConvert('code', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ComponentReasonToJson(ComponentReason instance) =>
    <String, dynamic>{'code': instance.code, 'text': instance.text};
