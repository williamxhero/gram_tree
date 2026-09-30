// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_code_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailCodeRequestCWProxy {
  EmailCodeRequest email(String email);

  EmailCodeRequest purpose(EmailCodeRequestPurposeEnum purpose);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailCodeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailCodeRequest call({String email, EmailCodeRequestPurposeEnum purpose});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEmailCodeRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEmailCodeRequest.copyWith.fieldName(...)`
class _$EmailCodeRequestCWProxyImpl implements _$EmailCodeRequestCWProxy {
  const _$EmailCodeRequestCWProxyImpl(this._value);

  final EmailCodeRequest _value;

  @override
  EmailCodeRequest email(String email) => this(email: email);

  @override
  EmailCodeRequest purpose(EmailCodeRequestPurposeEnum purpose) =>
      this(purpose: purpose);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailCodeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailCodeRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
  }) {
    return EmailCodeRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      purpose: purpose == const $CopyWithPlaceholder()
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as EmailCodeRequestPurposeEnum,
    );
  }
}

extension $EmailCodeRequestCopyWith on EmailCodeRequest {
  /// Returns a callable class that can be used as follows: `instanceOfEmailCodeRequest.copyWith(...)` or like so:`instanceOfEmailCodeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailCodeRequestCWProxy get copyWith => _$EmailCodeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailCodeRequest _$EmailCodeRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EmailCodeRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'purpose']);
      final val = EmailCodeRequest(
        email: $checkedConvert('email', (v) => v as String),
        purpose: $checkedConvert(
          'purpose',
          (v) => $enumDecode(_$EmailCodeRequestPurposeEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EmailCodeRequestToJson(EmailCodeRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'purpose': _$EmailCodeRequestPurposeEnumEnumMap[instance.purpose]!,
    };

const _$EmailCodeRequestPurposeEnumEnumMap = {
  EmailCodeRequestPurposeEnum.login: 'login',
  EmailCodeRequestPurposeEnum.bind: 'bind',
  EmailCodeRequestPurposeEnum.reauth: 'reauth',
};
