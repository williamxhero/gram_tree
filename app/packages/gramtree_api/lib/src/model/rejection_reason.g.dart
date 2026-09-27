// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rejection_reason.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RejectionReasonCWProxy {
  RejectionReason code(String code);

  RejectionReason message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RejectionReason(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RejectionReason(...).copyWith(id: 12, name: "My name")
  /// ````
  RejectionReason call({String code, String message});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRejectionReason.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRejectionReason.copyWith.fieldName(...)`
class _$RejectionReasonCWProxyImpl implements _$RejectionReasonCWProxy {
  const _$RejectionReasonCWProxyImpl(this._value);

  final RejectionReason _value;

  @override
  RejectionReason code(String code) => this(code: code);

  @override
  RejectionReason message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RejectionReason(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RejectionReason(...).copyWith(id: 12, name: "My name")
  /// ````
  RejectionReason call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return RejectionReason(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $RejectionReasonCopyWith on RejectionReason {
  /// Returns a callable class that can be used as follows: `instanceOfRejectionReason.copyWith(...)` or like so:`instanceOfRejectionReason.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RejectionReasonCWProxy get copyWith => _$RejectionReasonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RejectionReason _$RejectionReasonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RejectionReason', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'message']);
      final val = RejectionReason(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RejectionReasonToJson(RejectionReason instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};
