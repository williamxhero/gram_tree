//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'apple_reauth_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppleReauthRequest {
  /// Returns a new [AppleReauthRequest] instance.
  AppleReauthRequest({required this.identityToken});

  @JsonKey(name: r'identity_token', required: true, includeIfNull: false)
  final String identityToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppleReauthRequest && other.identityToken == identityToken;

  @override
  int get hashCode => identityToken.hashCode;

  factory AppleReauthRequest.fromJson(Map<String, dynamic> json) =>
      _$AppleReauthRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppleReauthRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
