//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publication_notification_ack.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicationNotificationAck {
  /// Returns a new [PublicationNotificationAck] instance.
  PublicationNotificationAck({this.licenseSeen = false, this.notificationIds});

  @JsonKey(
    defaultValue: false,
    name: r'license_seen',
    required: false,
    includeIfNull: false,
  )
  final bool? licenseSeen;

  @JsonKey(name: r'notification_ids', required: false, includeIfNull: false)
  final List<String>? notificationIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicationNotificationAck &&
          other.licenseSeen == licenseSeen &&
          other.notificationIds == notificationIds;

  @override
  int get hashCode => licenseSeen.hashCode + notificationIds.hashCode;

  factory PublicationNotificationAck.fromJson(Map<String, dynamic> json) =>
      _$PublicationNotificationAckFromJson(json);

  Map<String, dynamic> toJson() => _$PublicationNotificationAckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
