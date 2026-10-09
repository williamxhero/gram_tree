//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/write_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_batch_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteBatchResponse {
  /// Returns a new [WriteBatchResponse] instance.
  WriteBatchResponse({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<WriteResult> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WriteBatchResponse && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory WriteBatchResponse.fromJson(Map<String, dynamic> json) =>
      _$WriteBatchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WriteBatchResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
