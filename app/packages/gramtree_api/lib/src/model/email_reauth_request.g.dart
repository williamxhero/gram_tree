// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_reauth_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailReauthRequestCWProxy {
  EmailReauthRequest code(String code);

  EmailReauthRequest email(String email);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailReauthRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailReauthRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailReauthRequest call({String code, String email});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEmailReauthRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEmailReauthRequest.copyWith.fieldName(...)`
class _$EmailReauthRequestCWProxyImpl implements _$EmailReauthRequestCWProxy {
  const _$EmailReauthRequestCWProxyImpl(this._value);

  final EmailReauthRequest _value;

  @override
  EmailReauthRequest code(String code) => this(code: code);

  @override
  EmailReauthRequest email(String email) => this(email: email);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailReauthRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailReauthRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailReauthRequest call({
    Object? code = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
  }) {
    return EmailReauthRequest(
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

extension $EmailReauthRequestCopyWith on EmailReauthRequest {
  /// Returns a callable class that can be used as follows: `instanceOfEmailReauthRequest.copyWith(...)` or like so:`instanceOfEmailReauthRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailReauthRequestCWProxy get copyWith =>
      _$EmailReauthRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailReauthRequest _$EmailReauthRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EmailReauthRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'email']);
      final val = EmailReauthRequest(
        code: $checkedConvert('code', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$EmailReauthRequestToJson(EmailReauthRequest instance) =>
    <String, dynamic>{'code': instance.code, 'email': instance.email};
