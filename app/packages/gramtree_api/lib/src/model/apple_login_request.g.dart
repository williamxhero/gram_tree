// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_login_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppleLoginRequestCWProxy {
  AppleLoginRequest authorizationCode(String? authorizationCode);

  AppleLoginRequest familyName(String? familyName);

  AppleLoginRequest givenName(String? givenName);

  AppleLoginRequest identityToken(String identityToken);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppleLoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppleLoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AppleLoginRequest call({
    String? authorizationCode,
    String? familyName,
    String? givenName,
    String identityToken,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppleLoginRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppleLoginRequest.copyWith.fieldName(...)`
class _$AppleLoginRequestCWProxyImpl implements _$AppleLoginRequestCWProxy {
  const _$AppleLoginRequestCWProxyImpl(this._value);

  final AppleLoginRequest _value;

  @override
  AppleLoginRequest authorizationCode(String? authorizationCode) =>
      this(authorizationCode: authorizationCode);

  @override
  AppleLoginRequest familyName(String? familyName) =>
      this(familyName: familyName);

  @override
  AppleLoginRequest givenName(String? givenName) => this(givenName: givenName);

  @override
  AppleLoginRequest identityToken(String identityToken) =>
      this(identityToken: identityToken);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppleLoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppleLoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AppleLoginRequest call({
    Object? authorizationCode = const $CopyWithPlaceholder(),
    Object? familyName = const $CopyWithPlaceholder(),
    Object? givenName = const $CopyWithPlaceholder(),
    Object? identityToken = const $CopyWithPlaceholder(),
  }) {
    return AppleLoginRequest(
      authorizationCode: authorizationCode == const $CopyWithPlaceholder()
          ? _value.authorizationCode
          // ignore: cast_nullable_to_non_nullable
          : authorizationCode as String?,
      familyName: familyName == const $CopyWithPlaceholder()
          ? _value.familyName
          // ignore: cast_nullable_to_non_nullable
          : familyName as String?,
      givenName: givenName == const $CopyWithPlaceholder()
          ? _value.givenName
          // ignore: cast_nullable_to_non_nullable
          : givenName as String?,
      identityToken: identityToken == const $CopyWithPlaceholder()
          ? _value.identityToken
          // ignore: cast_nullable_to_non_nullable
          : identityToken as String,
    );
  }
}

extension $AppleLoginRequestCopyWith on AppleLoginRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAppleLoginRequest.copyWith(...)` or like so:`instanceOfAppleLoginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppleLoginRequestCWProxy get copyWith =>
      _$AppleLoginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleLoginRequest _$AppleLoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppleLoginRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['identity_token']);
        final val = AppleLoginRequest(
          authorizationCode: $checkedConvert(
            'authorization_code',
            (v) => v as String?,
          ),
          familyName: $checkedConvert('family_name', (v) => v as String?),
          givenName: $checkedConvert('given_name', (v) => v as String?),
          identityToken: $checkedConvert('identity_token', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'authorizationCode': 'authorization_code',
        'familyName': 'family_name',
        'givenName': 'given_name',
        'identityToken': 'identity_token',
      },
    );

Map<String, dynamic> _$AppleLoginRequestToJson(AppleLoginRequest instance) =>
    <String, dynamic>{
      'authorization_code': ?instance.authorizationCode,
      'family_name': ?instance.familyName,
      'given_name': ?instance.givenName,
      'identity_token': instance.identityToken,
    };
