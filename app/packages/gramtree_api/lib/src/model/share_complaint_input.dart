//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'share_complaint_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ShareComplaintInput {
  /// Returns a new [ShareComplaintInput] instance.
  ShareComplaintInput({
    required this.contact,

    required this.message,

    this.shareId,
  });

  @JsonKey(name: r'contact', required: true, includeIfNull: false)
  final String contact;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'share_id', required: false, includeIfNull: false)
  final String? shareId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareComplaintInput &&
          other.contact == contact &&
          other.message == message &&
          other.shareId == shareId;

  @override
  int get hashCode =>
      contact.hashCode +
      message.hashCode +
      (shareId == null ? 0 : shareId.hashCode);

  factory ShareComplaintInput.fromJson(Map<String, dynamic> json) =>
      _$ShareComplaintInputFromJson(json);

  Map<String, dynamic> toJson() => _$ShareComplaintInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
