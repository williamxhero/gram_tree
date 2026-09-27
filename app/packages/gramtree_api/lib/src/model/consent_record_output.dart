//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'consent_record_output.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConsentRecordOutput {
  /// Returns a new [ConsentRecordOutput] instance.
  ConsentRecordOutput({
    required this.action,

    this.deviceId,

    required this.id,

    required this.kind,

    required this.occurredAt,

    required this.version,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final ConsentRecordOutputActionEnum action;

  @JsonKey(name: r'device_id', required: false, includeIfNull: false)
  final String? deviceId;

  /// 客户端生成的 UUID v4，重复上传按它去重
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final ConsentRecordOutputKindEnum kind;

  @JsonKey(name: r'occurred_at', required: true, includeIfNull: false)
  final String occurredAt;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentRecordOutput &&
          other.action == action &&
          other.deviceId == deviceId &&
          other.id == id &&
          other.kind == kind &&
          other.occurredAt == occurredAt &&
          other.version == version;

  @override
  int get hashCode =>
      action.hashCode +
      (deviceId == null ? 0 : deviceId.hashCode) +
      id.hashCode +
      kind.hashCode +
      occurredAt.hashCode +
      version.hashCode;

  factory ConsentRecordOutput.fromJson(Map<String, dynamic> json) =>
      _$ConsentRecordOutputFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentRecordOutputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ConsentRecordOutputActionEnum {
  @JsonValue(r'agree')
  agree(r'agree'),
  @JsonValue(r'withdraw')
  withdraw(r'withdraw');

  const ConsentRecordOutputActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ConsentRecordOutputKindEnum {
  @JsonValue(r'terms')
  terms(r'terms'),
  @JsonValue(r'privacy')
  privacy(r'privacy'),
  @JsonValue(r'sensitive_personal_info')
  sensitivePersonalInfo(r'sensitive_personal_info'),
  @JsonValue(r'product_analytics')
  productAnalytics(r'product_analytics');

  const ConsentRecordOutputKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
