//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dietary_unclassified_dish.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DietaryUnclassifiedDish {
  /// Returns a new [DietaryUnclassifiedDish] instance.
  DietaryUnclassifiedDish({
    required this.name,

    required this.occurredAt,

    required this.recordId,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: true)
  final String? name;

  @JsonKey(name: r'occurred_at', required: true, includeIfNull: false)
  final String occurredAt;

  @JsonKey(name: r'record_id', required: true, includeIfNull: false)
  final String recordId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryUnclassifiedDish &&
          other.name == name &&
          other.occurredAt == occurredAt &&
          other.recordId == recordId;

  @override
  int get hashCode =>
      (name == null ? 0 : name.hashCode) +
      occurredAt.hashCode +
      recordId.hashCode;

  factory DietaryUnclassifiedDish.fromJson(Map<String, dynamic> json) =>
      _$DietaryUnclassifiedDishFromJson(json);

  Map<String, dynamic> toJson() => _$DietaryUnclassifiedDishToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
