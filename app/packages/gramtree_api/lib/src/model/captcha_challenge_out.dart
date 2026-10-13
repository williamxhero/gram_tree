//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'captcha_challenge_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CaptchaChallengeOut {
  /// Returns a new [CaptchaChallengeOut] instance.
  CaptchaChallengeOut({
    required this.challengeId,

    required this.imageDataUri,

    required this.prompt,
  });

  @JsonKey(name: r'challenge_id', required: true, includeIfNull: false)
  final String challengeId;

  @JsonKey(name: r'image_data_uri', required: true, includeIfNull: false)
  final String imageDataUri;

  @JsonKey(name: r'prompt', required: true, includeIfNull: false)
  final String prompt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptchaChallengeOut &&
          other.challengeId == challengeId &&
          other.imageDataUri == imageDataUri &&
          other.prompt == prompt;

  @override
  int get hashCode =>
      challengeId.hashCode + imageDataUri.hashCode + prompt.hashCode;

  factory CaptchaChallengeOut.fromJson(Map<String, dynamic> json) =>
      _$CaptchaChallengeOutFromJson(json);

  Map<String, dynamic> toJson() => _$CaptchaChallengeOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
