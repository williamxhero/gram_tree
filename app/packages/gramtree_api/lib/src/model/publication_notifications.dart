//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/publication_notification_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publication_notifications.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicationNotifications {
  /// Returns a new [PublicationNotifications] instance.
  PublicationNotifications({this.items, this.licenseNotice});

  @JsonKey(name: r'items', required: false, includeIfNull: false)
  final List<PublicationNotificationOut>? items;

  @JsonKey(name: r'license_notice', required: false, includeIfNull: false)
  final String? licenseNotice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicationNotifications &&
          other.items == items &&
          other.licenseNotice == licenseNotice;

  @override
  int get hashCode =>
      items.hashCode + (licenseNotice == null ? 0 : licenseNotice.hashCode);

  factory PublicationNotifications.fromJson(Map<String, dynamic> json) =>
      _$PublicationNotificationsFromJson(json);

  Map<String, dynamic> toJson() => _$PublicationNotificationsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
