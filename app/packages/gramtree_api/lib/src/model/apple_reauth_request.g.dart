// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_reauth_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppleReauthRequestCWProxy {
  AppleReauthRequest identityToken(String identityToken);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppleReauthRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppleReauthRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AppleReauthRequest call({String identityToken});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppleReauthRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppleReauthRequest.copyWith.fieldName(...)`
class _$AppleReauthRequestCWProxyImpl implements _$AppleReauthRequestCWProxy {
  const _$AppleReauthRequestCWProxyImpl(this._value);

  final AppleReauthRequest _value;

  @override
  AppleReauthRequest identityToken(String identityToken) =>
      this(identityToken: identityToken);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppleReauthRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppleReauthRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AppleReauthRequest call({
    Object? identityToken = const $CopyWithPlaceholder(),
  }) {
    return AppleReauthRequest(
      identityToken: identityToken == const $CopyWithPlaceholder()
          ? _value.identityToken
          // ignore: cast_nullable_to_non_nullable
          : identityToken as String,
    );
  }
}

extension $AppleReauthRequestCopyWith on AppleReauthRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAppleReauthRequest.copyWith(...)` or like so:`instanceOfAppleReauthRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppleReauthRequestCWProxy get copyWith =>
      _$AppleReauthRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleReauthRequest _$AppleReauthRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppleReauthRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['identity_token']);
      final val = AppleReauthRequest(
        identityToken: $checkedConvert('identity_token', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'identityToken': 'identity_token'});

Map<String, dynamic> _$AppleReauthRequestToJson(AppleReauthRequest instance) =>
    <String, dynamic>{'identity_token': instance.identityToken};
