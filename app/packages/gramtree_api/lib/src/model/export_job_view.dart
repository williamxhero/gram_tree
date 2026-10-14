//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'export_job_view.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExportJobView {
  /// Returns a new [ExportJobView] instance.
  ExportJobView({
    this.completedAt,

    required this.createdAt,

    this.downloadUrl,

    this.errorCode,

    this.expiresAt,

    required this.id,

    required this.status,
  });

  @JsonKey(name: r'completed_at', required: false, includeIfNull: false)
  final DateTime? completedAt;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'download_url', required: false, includeIfNull: false)
  final String? downloadUrl;

  @JsonKey(name: r'error_code', required: false, includeIfNull: false)
  final String? errorCode;

  @JsonKey(name: r'expires_at', required: false, includeIfNull: false)
  final DateTime? expiresAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ExportJobViewStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportJobView &&
          other.completedAt == completedAt &&
          other.createdAt == createdAt &&
          other.downloadUrl == downloadUrl &&
          other.errorCode == errorCode &&
          other.expiresAt == expiresAt &&
          other.id == id &&
          other.status == status;

  @override
  int get hashCode =>
      (completedAt == null ? 0 : completedAt.hashCode) +
      createdAt.hashCode +
      (downloadUrl == null ? 0 : downloadUrl.hashCode) +
      (errorCode == null ? 0 : errorCode.hashCode) +
      (expiresAt == null ? 0 : expiresAt.hashCode) +
      id.hashCode +
      status.hashCode;

  factory ExportJobView.fromJson(Map<String, dynamic> json) =>
      _$ExportJobViewFromJson(json);

  Map<String, dynamic> toJson() => _$ExportJobViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ExportJobViewStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'processing')
  processing(r'processing'),
  @JsonValue(r'completed')
  completed(r'completed'),
  @JsonValue(r'failed')
  failed(r'failed'),
  @JsonValue(r'expired')
  expired(r'expired');

  const ExportJobViewStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
