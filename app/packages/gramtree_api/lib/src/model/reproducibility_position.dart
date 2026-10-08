//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reproducibility_position.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReproducibilityPosition {
  /// Returns a new [ReproducibilityPosition] instance.
  ReproducibilityPosition({
    required this.collection,

    this.end,

    required this.field,

    this.itemId,

    this.start,
  });

  @JsonKey(name: r'collection', required: true, includeIfNull: false)
  final ReproducibilityPositionCollectionEnum collection;

  @JsonKey(name: r'end', required: false, includeIfNull: false)
  final int? end;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'item_id', required: false, includeIfNull: false)
  final String? itemId;

  @JsonKey(name: r'start', required: false, includeIfNull: false)
  final int? start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReproducibilityPosition &&
          other.collection == collection &&
          other.end == end &&
          other.field == field &&
          other.itemId == itemId &&
          other.start == start;

  @override
  int get hashCode =>
      collection.hashCode +
      (end == null ? 0 : end.hashCode) +
      field.hashCode +
      (itemId == null ? 0 : itemId.hashCode) +
      (start == null ? 0 : start.hashCode);

  factory ReproducibilityPosition.fromJson(Map<String, dynamic> json) =>
      _$ReproducibilityPositionFromJson(json);

  Map<String, dynamic> toJson() => _$ReproducibilityPositionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReproducibilityPositionCollectionEnum {
  @JsonValue(r'ingredients')
  ingredients(r'ingredients'),
  @JsonValue(r'steps')
  steps(r'steps'),
  @JsonValue(r'snapshot')
  snapshot(r'snapshot');

  const ReproducibilityPositionCollectionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
