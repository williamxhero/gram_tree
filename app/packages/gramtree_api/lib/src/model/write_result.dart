//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/write_resource_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteResult {
  /// Returns a new [WriteResult] instance.
  WriteResult({
    this.conflict,

    this.reasonCode,

    this.result,

    required this.status,

    required this.writeId,
  });

  @JsonKey(name: r'conflict', required: false, includeIfNull: false)
  final Object? conflict;

  @JsonKey(name: r'reason_code', required: false, includeIfNull: false)
  final String? reasonCode;

  @JsonKey(name: r'result', required: false, includeIfNull: false)
  final WriteResourceResult? result;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final WriteResultStatusEnum status;

  @JsonKey(name: r'write_id', required: true, includeIfNull: false)
  final String writeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WriteResult &&
          other.conflict == conflict &&
          other.reasonCode == reasonCode &&
          other.result == result &&
          other.status == status &&
          other.writeId == writeId;

  @override
  int get hashCode =>
      (conflict == null ? 0 : conflict.hashCode) +
      (reasonCode == null ? 0 : reasonCode.hashCode) +
      (result == null ? 0 : result.hashCode) +
      status.hashCode +
      writeId.hashCode;

  factory WriteResult.fromJson(Map<String, dynamic> json) =>
      _$WriteResultFromJson(json);

  Map<String, dynamic> toJson() => _$WriteResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WriteResultStatusEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'already_processed')
  alreadyProcessed(r'already_processed'),
  @JsonValue(r'deferred')
  deferred_(r'deferred'),
  @JsonValue(r'conflict')
  conflict(r'conflict'),
  @JsonValue(r'failed')
  failed(r'failed');

  const WriteResultStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
