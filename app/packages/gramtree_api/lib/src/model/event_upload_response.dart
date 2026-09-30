//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/event_upload_result_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_upload_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventUploadResponse {
  /// Returns a new [EventUploadResponse] instance.
  EventUploadResponse({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<EventUploadResultItem> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventUploadResponse && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory EventUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$EventUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EventUploadResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
