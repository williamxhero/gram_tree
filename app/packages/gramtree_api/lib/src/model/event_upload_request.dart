//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/event_upload_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_upload_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventUploadRequest {
  /// Returns a new [EventUploadRequest] instance.
  EventUploadRequest({required this.events});

  @JsonKey(name: r'events', required: true, includeIfNull: false)
  final List<EventUploadItem> events;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventUploadRequest && other.events == events;

  @override
  int get hashCode => events.hashCode;

  factory EventUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$EventUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EventUploadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
