//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/rejection_reason.dart';
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
  EventUploadResultItem({required this.id, this.reason, required this.status});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final RejectionReason? reason;

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final EventUploadResultItemStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventUploadResultItem &&
          other.id == id &&
          other.reason == reason &&
          other.status == status;

  @override
  int get hashCode =>
      id.hashCode + (reason == null ? 0 : reason.hashCode) + status.hashCode;

  factory EventUploadResultItem.fromJson(Map<String, dynamic> json) =>
      _$EventUploadResultItemFromJson(json);

  Map<String, dynamic> toJson() => _$EventUploadResultItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
enum EventUploadResultItemStatusEnum {
  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @JsonValue(r'accepted')
  accepted(r'accepted'),

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @JsonValue(r'duplicate')
  duplicate(r'duplicate'),

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const EventUploadResultItemStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
