//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'merge_relation.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MergeRelation {
  /// Returns a new [MergeRelation] instance.
  MergeRelation({required this.fromId, required this.toId});

  /// 被合并掉的旧标准 ID
  @JsonKey(name: r'from_id', required: true, includeIfNull: false)
  final String fromId;

  /// 合并后的标准 ID
  @JsonKey(name: r'to_id', required: true, includeIfNull: false)
  final String toId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeRelation && other.fromId == fromId && other.toId == toId;

  @override
  int get hashCode => fromId.hashCode + toId.hashCode;

  factory MergeRelation.fromJson(Map<String, dynamic> json) =>
      _$MergeRelationFromJson(json);

  Map<String, dynamic> toJson() => _$MergeRelationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
