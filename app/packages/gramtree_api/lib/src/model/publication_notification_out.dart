//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publication_notification_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicationNotificationOut {
  /// Returns a new [PublicationNotificationOut] instance.
  PublicationNotificationOut({
    required this.id,

    required this.message,

    required this.recipeId,

    required this.title,

    required this.versionId,

    required this.versionNumber,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicationNotificationOut &&
          other.id == id &&
          other.message == message &&
          other.recipeId == recipeId &&
          other.title == title &&
          other.versionId == versionId &&
          other.versionNumber == versionNumber;

  @override
  int get hashCode =>
      id.hashCode +
      message.hashCode +
      recipeId.hashCode +
      title.hashCode +
      versionId.hashCode +
      versionNumber.hashCode;

  factory PublicationNotificationOut.fromJson(Map<String, dynamic> json) =>
      _$PublicationNotificationOutFromJson(json);

  Map<String, dynamic> toJson() => _$PublicationNotificationOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
