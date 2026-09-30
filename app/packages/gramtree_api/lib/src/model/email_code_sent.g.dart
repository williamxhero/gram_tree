// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_code_sent.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailCodeSentCWProxy {
  EmailCodeSent expiresInSeconds(int expiresInSeconds);

  EmailCodeSent resendAfterSeconds(int resendAfterSeconds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailCodeSent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailCodeSent(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailCodeSent call({int expiresInSeconds, int resendAfterSeconds});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEmailCodeSent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEmailCodeSent.copyWith.fieldName(...)`
class _$EmailCodeSentCWProxyImpl implements _$EmailCodeSentCWProxy {
  const _$EmailCodeSentCWProxyImpl(this._value);

  final EmailCodeSent _value;

  @override
  EmailCodeSent expiresInSeconds(int expiresInSeconds) =>
      this(expiresInSeconds: expiresInSeconds);

  @override
  EmailCodeSent resendAfterSeconds(int resendAfterSeconds) =>
      this(resendAfterSeconds: resendAfterSeconds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailCodeSent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailCodeSent(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailCodeSent call({
    Object? expiresInSeconds = const $CopyWithPlaceholder(),
    Object? resendAfterSeconds = const $CopyWithPlaceholder(),
  }) {
    return EmailCodeSent(
      expiresInSeconds: expiresInSeconds == const $CopyWithPlaceholder()
          ? _value.expiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : expiresInSeconds as int,
      resendAfterSeconds: resendAfterSeconds == const $CopyWithPlaceholder()
          ? _value.resendAfterSeconds
          // ignore: cast_nullable_to_non_nullable
          : resendAfterSeconds as int,
    );
  }
}

extension $EmailCodeSentCopyWith on EmailCodeSent {
  /// Returns a callable class that can be used as follows: `instanceOfEmailCodeSent.copyWith(...)` or like so:`instanceOfEmailCodeSent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailCodeSentCWProxy get copyWith => _$EmailCodeSentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailCodeSent _$EmailCodeSentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EmailCodeSent',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['expires_in_seconds', 'resend_after_seconds'],
        );
        final val = EmailCodeSent(
          expiresInSeconds: $checkedConvert(
            'expires_in_seconds',
            (v) => (v as num).toInt(),
          ),
          resendAfterSeconds: $checkedConvert(
            'resend_after_seconds',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'expiresInSeconds': 'expires_in_seconds',
        'resendAfterSeconds': 'resend_after_seconds',
      },
    );

Map<String, dynamic> _$EmailCodeSentToJson(EmailCodeSent instance) =>
    <String, dynamic>{
      'expires_in_seconds': instance.expiresInSeconds,
      'resend_after_seconds': instance.resendAfterSeconds,
    };
