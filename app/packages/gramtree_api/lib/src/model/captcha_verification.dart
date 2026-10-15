//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'captcha_verification.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CaptchaVerification {
  /// Returns a new [CaptchaVerification] instance.
  CaptchaVerification({required this.challengeId, required this.response});

  @JsonKey(name: r'challenge_id', required: true, includeIfNull: false)
  final String challengeId;

  @JsonKey(name: r'response', required: true, includeIfNull: false)
  final String response;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptchaVerification &&
          other.challengeId == challengeId &&
          other.response == response;

  @override
  int get hashCode => challengeId.hashCode + response.hashCode;

  factory CaptchaVerification.fromJson(Map<String, dynamic> json) =>
      _$CaptchaVerificationFromJson(json);

  Map<String, dynamic> toJson() => _$CaptchaVerificationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
