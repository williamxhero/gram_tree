// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bind_apple_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BindAppleRequestCWProxy {
  BindAppleRequest authorizationCode(String? authorizationCode);

  BindAppleRequest identityToken(String identityToken);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BindAppleRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BindAppleRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  BindAppleRequest call({String? authorizationCode, String identityToken});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBindAppleRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBindAppleRequest.copyWith.fieldName(...)`
class _$BindAppleRequestCWProxyImpl implements _$BindAppleRequestCWProxy {
  const _$BindAppleRequestCWProxyImpl(this._value);

  final BindAppleRequest _value;

  @override
  BindAppleRequest authorizationCode(String? authorizationCode) =>
      this(authorizationCode: authorizationCode);

  @override
  BindAppleRequest identityToken(String identityToken) =>
      this(identityToken: identityToken);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BindAppleRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BindAppleRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  BindAppleRequest call({
    Object? authorizationCode = const $CopyWithPlaceholder(),
    Object? identityToken = const $CopyWithPlaceholder(),
  }) {
    return BindAppleRequest(
      authorizationCode: authorizationCode == const $CopyWithPlaceholder()
          ? _value.authorizationCode
          // ignore: cast_nullable_to_non_nullable
          : authorizationCode as String?,
      identityToken: identityToken == const $CopyWithPlaceholder()
          ? _value.identityToken
          // ignore: cast_nullable_to_non_nullable
          : identityToken as String,
    );
  }
}

extension $BindAppleRequestCopyWith on BindAppleRequest {
  /// Returns a callable class that can be used as follows: `instanceOfBindAppleRequest.copyWith(...)` or like so:`instanceOfBindAppleRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BindAppleRequestCWProxy get copyWith => _$BindAppleRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BindAppleRequest _$BindAppleRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BindAppleRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['identity_token']);
        final val = BindAppleRequest(
          authorizationCode: $checkedConvert(
            'authorization_code',
            (v) => v as String?,
          ),
          identityToken: $checkedConvert('identity_token', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'authorizationCode': 'authorization_code',
        'identityToken': 'identity_token',
      },
    );

Map<String, dynamic> _$BindAppleRequestToJson(BindAppleRequest instance) =>
    <String, dynamic>{
      'authorization_code': ?instance.authorizationCode,
      'identity_token': instance.identityToken,
    };
