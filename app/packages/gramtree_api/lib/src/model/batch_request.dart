//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchRequest {
  /// Returns a new [BatchRequest] instance.
  BatchRequest({required this.ids});

  /// 要读取的标准 ID，最多 100 个
  @JsonKey(name: r'ids', required: true, includeIfNull: false)
  final List<String> ids;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BatchRequest && other.ids == ids;

  @override
  int get hashCode => ids.hashCode;

  factory BatchRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
