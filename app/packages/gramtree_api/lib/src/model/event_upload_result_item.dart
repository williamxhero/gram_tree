//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_upload_result_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventUploadResultItem {
  /// Returns a new [EventUploadResultItem] instance.
  EventUploadResultItem({required this.id, required this.status});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动
  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final EventUploadResultItemStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventUploadResultItem &&
          other.id == id &&
          other.status == status;

  @override
  int get hashCode => id.hashCode + status.hashCode;

  factory EventUploadResultItem.fromJson(Map<String, dynamic> json) =>
      _$EventUploadResultItemFromJson(json);

  Map<String, dynamic> toJson() => _$EventUploadResultItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动
enum EventUploadResultItemStatusEnum {
  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动
  @JsonValue(r'accepted')
  accepted(r'accepted'),

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动
  @JsonValue(r'duplicate')
  duplicate(r'duplicate');

  const EventUploadResultItemStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
