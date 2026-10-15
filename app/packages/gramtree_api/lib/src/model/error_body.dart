//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'error_body.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorBody {
  /// Returns a new [ErrorBody] instance.
  ErrorBody({
    required this.code,

    this.detail,

    required this.message,

    this.requestId,

    this.serverTime,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'request_id', required: false, includeIfNull: false)
  final String? requestId;

  @JsonKey(name: r'server_time', required: false, includeIfNull: false)
  final String? serverTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorBody &&
          other.code == code &&
          other.detail == detail &&
          other.message == message &&
          other.requestId == requestId &&
          other.serverTime == serverTime;

  @override
  int get hashCode =>
      code.hashCode +
      (detail == null ? 0 : detail.hashCode) +
      message.hashCode +
      (requestId == null ? 0 : requestId.hashCode) +
      (serverTime == null ? 0 : serverTime.hashCode);

  factory ErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ErrorBodyFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorBodyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
