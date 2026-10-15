// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captcha_challenge_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CaptchaChallengeOutCWProxy {
  CaptchaChallengeOut challengeId(String challengeId);

  CaptchaChallengeOut imageDataUri(String imageDataUri);

  CaptchaChallengeOut prompt(String prompt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CaptchaChallengeOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CaptchaChallengeOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CaptchaChallengeOut call({
    String challengeId,
    String imageDataUri,
    String prompt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCaptchaChallengeOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCaptchaChallengeOut.copyWith.fieldName(...)`
class _$CaptchaChallengeOutCWProxyImpl implements _$CaptchaChallengeOutCWProxy {
  const _$CaptchaChallengeOutCWProxyImpl(this._value);

  final CaptchaChallengeOut _value;

  @override
  CaptchaChallengeOut challengeId(String challengeId) =>
      this(challengeId: challengeId);

  @override
  CaptchaChallengeOut imageDataUri(String imageDataUri) =>
      this(imageDataUri: imageDataUri);

  @override
  CaptchaChallengeOut prompt(String prompt) => this(prompt: prompt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CaptchaChallengeOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CaptchaChallengeOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CaptchaChallengeOut call({
    Object? challengeId = const $CopyWithPlaceholder(),
    Object? imageDataUri = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
  }) {
    return CaptchaChallengeOut(
      challengeId: challengeId == const $CopyWithPlaceholder()
          ? _value.challengeId
          // ignore: cast_nullable_to_non_nullable
          : challengeId as String,
      imageDataUri: imageDataUri == const $CopyWithPlaceholder()
          ? _value.imageDataUri
          // ignore: cast_nullable_to_non_nullable
          : imageDataUri as String,
      prompt: prompt == const $CopyWithPlaceholder()
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String,
    );
  }
}

extension $CaptchaChallengeOutCopyWith on CaptchaChallengeOut {
  /// Returns a callable class that can be used as follows: `instanceOfCaptchaChallengeOut.copyWith(...)` or like so:`instanceOfCaptchaChallengeOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CaptchaChallengeOutCWProxy get copyWith =>
      _$CaptchaChallengeOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptchaChallengeOut _$CaptchaChallengeOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CaptchaChallengeOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['challenge_id', 'image_data_uri', 'prompt'],
        );
        final val = CaptchaChallengeOut(
          challengeId: $checkedConvert('challenge_id', (v) => v as String),
          imageDataUri: $checkedConvert('image_data_uri', (v) => v as String),
          prompt: $checkedConvert('prompt', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'challengeId': 'challenge_id',
        'imageDataUri': 'image_data_uri',
      },
    );

Map<String, dynamic> _$CaptchaChallengeOutToJson(
  CaptchaChallengeOut instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'image_data_uri': instance.imageDataUri,
  'prompt': instance.prompt,
};
