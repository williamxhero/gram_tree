// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_login_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailLoginRequestCWProxy {
  EmailLoginRequest code(String code);

  EmailLoginRequest email(String email);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailLoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailLoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailLoginRequest call({String code, String email});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEmailLoginRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEmailLoginRequest.copyWith.fieldName(...)`
class _$EmailLoginRequestCWProxyImpl implements _$EmailLoginRequestCWProxy {
  const _$EmailLoginRequestCWProxyImpl(this._value);

  final EmailLoginRequest _value;

  @override
  EmailLoginRequest code(String code) => this(code: code);

  @override
  EmailLoginRequest email(String email) => this(email: email);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailLoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailLoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailLoginRequest call({
    Object? code = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
  }) {
    return EmailLoginRequest(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
    );
  }
}

extension $EmailLoginRequestCopyWith on EmailLoginRequest {
  /// Returns a callable class that can be used as follows: `instanceOfEmailLoginRequest.copyWith(...)` or like so:`instanceOfEmailLoginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailLoginRequestCWProxy get copyWith =>
      _$EmailLoginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailLoginRequest _$EmailLoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EmailLoginRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'email']);
      final val = EmailLoginRequest(
        code: $checkedConvert('code', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$EmailLoginRequestToJson(EmailLoginRequest instance) =>
    <String, dynamic>{'code': instance.code, 'email': instance.email};
