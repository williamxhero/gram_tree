// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captcha_verification.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CaptchaVerificationCWProxy {
  CaptchaVerification challengeId(String challengeId);

  CaptchaVerification response(String response);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CaptchaVerification(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CaptchaVerification(...).copyWith(id: 12, name: "My name")
  /// ````
  CaptchaVerification call({String challengeId, String response});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCaptchaVerification.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCaptchaVerification.copyWith.fieldName(...)`
class _$CaptchaVerificationCWProxyImpl implements _$CaptchaVerificationCWProxy {
  const _$CaptchaVerificationCWProxyImpl(this._value);

  final CaptchaVerification _value;

  @override
  CaptchaVerification challengeId(String challengeId) =>
      this(challengeId: challengeId);

  @override
  CaptchaVerification response(String response) => this(response: response);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CaptchaVerification(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CaptchaVerification(...).copyWith(id: 12, name: "My name")
  /// ````
  CaptchaVerification call({
    Object? challengeId = const $CopyWithPlaceholder(),
    Object? response = const $CopyWithPlaceholder(),
  }) {
    return CaptchaVerification(
      challengeId: challengeId == const $CopyWithPlaceholder()
          ? _value.challengeId
          // ignore: cast_nullable_to_non_nullable
          : challengeId as String,
      response: response == const $CopyWithPlaceholder()
          ? _value.response
          // ignore: cast_nullable_to_non_nullable
          : response as String,
    );
  }
}

extension $CaptchaVerificationCopyWith on CaptchaVerification {
  /// Returns a callable class that can be used as follows: `instanceOfCaptchaVerification.copyWith(...)` or like so:`instanceOfCaptchaVerification.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CaptchaVerificationCWProxy get copyWith =>
      _$CaptchaVerificationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptchaVerification _$CaptchaVerificationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CaptchaVerification', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['challenge_id', 'response']);
      final val = CaptchaVerification(
        challengeId: $checkedConvert('challenge_id', (v) => v as String),
        response: $checkedConvert('response', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'challengeId': 'challenge_id'});

Map<String, dynamic> _$CaptchaVerificationToJson(
  CaptchaVerification instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'response': instance.response,
};
