//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_status.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AIStatus {
  /// Returns a new [AIStatus] instance.
  AIStatus({required this.available, this.reason, required this.remaining});

  @JsonKey(name: r'available', required: true, includeIfNull: false)
  final bool available;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @JsonKey(name: r'remaining', required: true, includeIfNull: false)
  final int remaining;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIStatus &&
          other.available == available &&
          other.reason == reason &&
          other.remaining == remaining;

  @override
  int get hashCode =>
      available.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      remaining.hashCode;

  factory AIStatus.fromJson(Map<String, dynamic> json) =>
      _$AIStatusFromJson(json);

  Map<String, dynamic> toJson() => _$AIStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
