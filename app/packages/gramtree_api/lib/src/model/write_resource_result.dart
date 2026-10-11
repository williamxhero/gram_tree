//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_resource_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteResourceResult {
  /// Returns a new [WriteResourceResult] instance.
  WriteResourceResult({
    required this.resourceId,

    required this.resourceType,

    this.values,
  });

  @JsonKey(name: r'resource_id', required: true, includeIfNull: false)
  final String resourceId;

  @JsonKey(name: r'resource_type', required: true, includeIfNull: false)
  final String resourceType;

  @JsonKey(name: r'values', required: false, includeIfNull: false)
  final Object? values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WriteResourceResult &&
          other.resourceId == resourceId &&
          other.resourceType == resourceType &&
          other.values == values;

  @override
  int get hashCode =>
      resourceId.hashCode + resourceType.hashCode + values.hashCode;

  factory WriteResourceResult.fromJson(Map<String, dynamic> json) =>
      _$WriteResourceResultFromJson(json);

  Map<String, dynamic> toJson() => _$WriteResourceResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
