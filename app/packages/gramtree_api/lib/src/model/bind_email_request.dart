//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bind_email_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BindEmailRequest {
  /// Returns a new [BindEmailRequest] instance.
  BindEmailRequest({required this.code, required this.email});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindEmailRequest && other.code == code && other.email == email;

  @override
  int get hashCode => code.hashCode + email.hashCode;

  factory BindEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$BindEmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BindEmailRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
