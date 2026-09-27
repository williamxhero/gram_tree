// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_body.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ErrorBodyCWProxy {
  ErrorBody code(String code);

  ErrorBody detail(String? detail);

  ErrorBody message(String message);

  ErrorBody requestId(String? requestId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ErrorBody(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ErrorBody(...).copyWith(id: 12, name: "My name")
  /// ````
  ErrorBody call({
    String code,
    String? detail,
    String message,
    String? requestId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfErrorBody.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfErrorBody.copyWith.fieldName(...)`
class _$ErrorBodyCWProxyImpl implements _$ErrorBodyCWProxy {
  const _$ErrorBodyCWProxyImpl(this._value);

  final ErrorBody _value;

  @override
  ErrorBody code(String code) => this(code: code);

  @override
  ErrorBody detail(String? detail) => this(detail: detail);

  @override
  ErrorBody message(String message) => this(message: message);

  @override
  ErrorBody requestId(String? requestId) => this(requestId: requestId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ErrorBody(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ErrorBody(...).copyWith(id: 12, name: "My name")
  /// ````
  ErrorBody call({
    Object? code = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
  }) {
    return ErrorBody(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String?,
    );
  }
}

extension $ErrorBodyCopyWith on ErrorBody {
  /// Returns a callable class that can be used as follows: `instanceOfErrorBody.copyWith(...)` or like so:`instanceOfErrorBody.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ErrorBodyCWProxy get copyWith => _$ErrorBodyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorBody _$ErrorBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorBody', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'message']);
      final val = ErrorBody(
        code: $checkedConvert('code', (v) => v as String),
        detail: $checkedConvert('detail', (v) => v as String?),
        message: $checkedConvert('message', (v) => v as String),
        requestId: $checkedConvert('request_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'requestId': 'request_id'});

Map<String, dynamic> _$ErrorBodyToJson(ErrorBody instance) => <String, dynamic>{
  'code': instance.code,
  'detail': ?instance.detail,
  'message': instance.message,
  'request_id': ?instance.requestId,
};
