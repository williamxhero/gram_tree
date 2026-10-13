//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_change_status_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteChangeStatusOut {
  /// Returns a new [TasteChangeStatusOut] instance.
  TasteChangeStatusOut({required this.autoChanges, required this.autoReverted});

  @JsonKey(name: r'auto_changes', required: true, includeIfNull: false)
  final int autoChanges;

  @JsonKey(name: r'auto_reverted', required: true, includeIfNull: false)
  final int autoReverted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteChangeStatusOut &&
          other.autoChanges == autoChanges &&
          other.autoReverted == autoReverted;

  @override
  int get hashCode => autoChanges.hashCode + autoReverted.hashCode;

  factory TasteChangeStatusOut.fromJson(Map<String, dynamic> json) =>
      _$TasteChangeStatusOutFromJson(json);

  Map<String, dynamic> toJson() => _$TasteChangeStatusOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
