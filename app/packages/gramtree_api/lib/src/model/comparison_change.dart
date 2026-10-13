//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comparison_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComparisonChange {
  /// Returns a new [ComparisonChange] instance.
  ComparisonChange({
    this.after,

    required this.basis,

    this.before,

    required this.field,

    required this.kind,

    this.relativeChange,

    this.unit,
  });

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final Object? after;

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'before', required: false, includeIfNull: false)
  final Object? before;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final ComparisonChangeKindEnum kind;

  @JsonKey(name: r'relative_change', required: false, includeIfNull: false)
  final num? relativeChange;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final String? unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonChange &&
          other.after == after &&
          other.basis == basis &&
          other.before == before &&
          other.field == field &&
          other.kind == kind &&
          other.relativeChange == relativeChange &&
          other.unit == unit;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      basis.hashCode +
      (before == null ? 0 : before.hashCode) +
      field.hashCode +
      kind.hashCode +
      (relativeChange == null ? 0 : relativeChange.hashCode) +
      (unit == null ? 0 : unit.hashCode);

  factory ComparisonChange.fromJson(Map<String, dynamic> json) =>
      _$ComparisonChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ComparisonChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ComparisonChangeKindEnum {
  @JsonValue(r'added')
  added(r'added'),
  @JsonValue(r'removed')
  removed(r'removed'),
  @JsonValue(r'replacement')
  replacement(r'replacement'),
  @JsonValue(r'quantity')
  quantity(r'quantity'),
  @JsonValue(r'unit')
  unit(r'unit'),
  @JsonValue(r'field')
  field(r'field'),
  @JsonValue(r'text')
  text(r'text');

  const ComparisonChangeKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
