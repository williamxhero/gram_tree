// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_pair.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TokenPairCWProxy {
  TokenPair accessExpiresIn(int accessExpiresIn);

  TokenPair accessToken(String accessToken);

  TokenPair refreshToken(String refreshToken);

  TokenPair user(UserOut user);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TokenPair(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TokenPair(...).copyWith(id: 12, name: "My name")
  /// ````
  TokenPair call({
    int accessExpiresIn,
    String accessToken,
    String refreshToken,
    UserOut user,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTokenPair.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTokenPair.copyWith.fieldName(...)`
class _$TokenPairCWProxyImpl implements _$TokenPairCWProxy {
  const _$TokenPairCWProxyImpl(this._value);

  final TokenPair _value;

  @override
  TokenPair accessExpiresIn(int accessExpiresIn) =>
      this(accessExpiresIn: accessExpiresIn);

  @override
  TokenPair accessToken(String accessToken) => this(accessToken: accessToken);

  @override
  TokenPair refreshToken(String refreshToken) =>
      this(refreshToken: refreshToken);

  @override
  TokenPair user(UserOut user) => this(user: user);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TokenPair(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TokenPair(...).copyWith(id: 12, name: "My name")
  /// ````
  TokenPair call({
    Object? accessExpiresIn = const $CopyWithPlaceholder(),
    Object? accessToken = const $CopyWithPlaceholder(),
    Object? refreshToken = const $CopyWithPlaceholder(),
    Object? user = const $CopyWithPlaceholder(),
  }) {
    return TokenPair(
      accessExpiresIn: accessExpiresIn == const $CopyWithPlaceholder()
          ? _value.accessExpiresIn
          // ignore: cast_nullable_to_non_nullable
          : accessExpiresIn as int,
      accessToken: accessToken == const $CopyWithPlaceholder()
          ? _value.accessToken
          // ignore: cast_nullable_to_non_nullable
          : accessToken as String,
      refreshToken: refreshToken == const $CopyWithPlaceholder()
          ? _value.refreshToken
          // ignore: cast_nullable_to_non_nullable
          : refreshToken as String,
      user: user == const $CopyWithPlaceholder()
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as UserOut,
    );
  }
}

extension $TokenPairCopyWith on TokenPair {
  /// Returns a callable class that can be used as follows: `instanceOfTokenPair.copyWith(...)` or like so:`instanceOfTokenPair.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TokenPairCWProxy get copyWith => _$TokenPairCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenPair _$TokenPairFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TokenPair',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'access_expires_in',
        'access_token',
        'refresh_token',
        'user',
      ],
    );
    final val = TokenPair(
      accessExpiresIn: $checkedConvert(
        'access_expires_in',
        (v) => (v as num).toInt(),
      ),
      accessToken: $checkedConvert('access_token', (v) => v as String),
      refreshToken: $checkedConvert('refresh_token', (v) => v as String),
      user: $checkedConvert(
        'user',
        (v) => UserOut.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'accessExpiresIn': 'access_expires_in',
    'accessToken': 'access_token',
    'refreshToken': 'refresh_token',
  },
);

Map<String, dynamic> _$TokenPairToJson(TokenPair instance) => <String, dynamic>{
  'access_expires_in': instance.accessExpiresIn,
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'user': instance.user.toJson(),
};
