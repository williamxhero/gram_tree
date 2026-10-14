//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publication_condition.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicationCondition {
  /// Returns a new [PublicationCondition] instance.
  PublicationCondition({
    required this.action,

    required this.code,

    required this.label,

    this.remainingCount,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'remaining_count', required: false, includeIfNull: false)
  final int? remainingCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicationCondition &&
          other.action == action &&
          other.code == code &&
          other.label == label &&
          other.remainingCount == remainingCount;

  @override
  int get hashCode =>
      action.hashCode +
      code.hashCode +
      label.hashCode +
      (remainingCount == null ? 0 : remainingCount.hashCode);

  factory PublicationCondition.fromJson(Map<String, dynamic> json) =>
      _$PublicationConditionFromJson(json);

  Map<String, dynamic> toJson() => _$PublicationConditionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
