//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/export_job_view.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'export_job_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExportJobList {
  /// Returns a new [ExportJobList] instance.
  ExportJobList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ExportJobView> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExportJobList && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory ExportJobList.fromJson(Map<String, dynamic> json) =>
      _$ExportJobListFromJson(json);

  Map<String, dynamic> toJson() => _$ExportJobListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
