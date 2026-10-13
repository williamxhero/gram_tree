//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_login_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailLoginRequest {
  /// Returns a new [EmailLoginRequest] instance.
  EmailLoginRequest({required this.code, required this.email});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailLoginRequest && other.code == code && other.email == email;

  @override
  int get hashCode => code.hashCode + email.hashCode;

  factory EmailLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailLoginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
