//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/consent_record_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'consent_upload.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConsentUpload {
  /// Returns a new [ConsentUpload] instance.
  ConsentUpload({required this.records});

  @JsonKey(name: r'records', required: true, includeIfNull: false)
  final List<ConsentRecordInput> records;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentUpload && other.records == records;

  @override
  int get hashCode => records.hashCode;

  factory ConsentUpload.fromJson(Map<String, dynamic> json) =>
      _$ConsentUploadFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentUploadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
