//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/write_envelope.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_batch.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteBatch {
  /// Returns a new [WriteBatch] instance.
  WriteBatch({required this.writes});

  @JsonKey(name: r'writes', required: true, includeIfNull: false)
  final List<WriteEnvelope> writes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WriteBatch && other.writes == writes;

  @override
  int get hashCode => writes.hashCode;

  factory WriteBatch.fromJson(Map<String, dynamic> json) =>
      _$WriteBatchFromJson(json);

  Map<String, dynamic> toJson() => _$WriteBatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
