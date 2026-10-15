//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'captcha_verification_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CaptchaVerificationOut {
  /// Returns a new [CaptchaVerificationOut] instance.
  CaptchaVerificationOut({
    required this.accepted,

    required this.accessRestored,
  });

  @JsonKey(name: r'accepted', required: true, includeIfNull: false)
  final bool accepted;

  @JsonKey(name: r'access_restored', required: true, includeIfNull: false)
  final bool accessRestored;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptchaVerificationOut &&
          other.accepted == accepted &&
          other.accessRestored == accessRestored;

  @override
  int get hashCode => accepted.hashCode + accessRestored.hashCode;

  factory CaptchaVerificationOut.fromJson(Map<String, dynamic> json) =>
      _$CaptchaVerificationOutFromJson(json);

  Map<String, dynamic> toJson() => _$CaptchaVerificationOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
