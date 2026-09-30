//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unrecorded_ingredient_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UnrecordedIngredientItem {
  /// Returns a new [UnrecordedIngredientItem] instance.
  UnrecordedIngredientItem({
    required this.firstSeenAt,

    required this.lastSeenAt,

    required this.name,

    required this.occurrenceCount,
  });

  @JsonKey(name: r'first_seen_at', required: true, includeIfNull: false)
  final DateTime firstSeenAt;

  @JsonKey(name: r'last_seen_at', required: true, includeIfNull: false)
  final DateTime lastSeenAt;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'occurrence_count', required: true, includeIfNull: false)
  final int occurrenceCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnrecordedIngredientItem &&
          other.firstSeenAt == firstSeenAt &&
          other.lastSeenAt == lastSeenAt &&
          other.name == name &&
          other.occurrenceCount == occurrenceCount;

  @override
  int get hashCode =>
      firstSeenAt.hashCode +
      lastSeenAt.hashCode +
      name.hashCode +
      occurrenceCount.hashCode;

  factory UnrecordedIngredientItem.fromJson(Map<String, dynamic> json) =>
      _$UnrecordedIngredientItemFromJson(json);

  Map<String, dynamic> toJson() => _$UnrecordedIngredientItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
