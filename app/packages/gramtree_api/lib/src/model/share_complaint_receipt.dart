//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'share_complaint_receipt.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ShareComplaintReceipt {
  /// Returns a new [ShareComplaintReceipt] instance.
  ShareComplaintReceipt({this.accepted = true});

  @JsonKey(
    defaultValue: true,
    name: r'accepted',
    required: false,
    includeIfNull: false,
  )
  final bool? accepted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareComplaintReceipt && other.accepted == accepted;

  @override
  int get hashCode => accepted.hashCode;

  factory ShareComplaintReceipt.fromJson(Map<String, dynamic> json) =>
      _$ShareComplaintReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$ShareComplaintReceiptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
