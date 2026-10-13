//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'graded_comparison_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradedComparisonChange {
  /// Returns a new [GradedComparisonChange] instance.
  GradedComparisonChange({
    this.after,

    required this.basis,

    this.before,

    required this.field,

    required this.grade,

    required this.kind,

    this.relativeChange,

    required this.ruleId,

    required this.rulesVersion,

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

  @JsonKey(name: r'grade', required: true, includeIfNull: false)
  final GradedComparisonChangeGradeEnum grade;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final GradedComparisonChangeKindEnum kind;

  @JsonKey(name: r'relative_change', required: false, includeIfNull: false)
  final num? relativeChange;

  @JsonKey(name: r'rule_id', required: true, includeIfNull: false)
  final String ruleId;

  @JsonKey(name: r'rules_version', required: true, includeIfNull: false)
  final String rulesVersion;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final String? unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradedComparisonChange &&
          other.after == after &&
          other.basis == basis &&
          other.before == before &&
          other.field == field &&
          other.grade == grade &&
          other.kind == kind &&
          other.relativeChange == relativeChange &&
          other.ruleId == ruleId &&
          other.rulesVersion == rulesVersion &&
          other.unit == unit;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      basis.hashCode +
      (before == null ? 0 : before.hashCode) +
      field.hashCode +
      grade.hashCode +
      kind.hashCode +
      (relativeChange == null ? 0 : relativeChange.hashCode) +
      ruleId.hashCode +
      rulesVersion.hashCode +
      (unit == null ? 0 : unit.hashCode);

  factory GradedComparisonChange.fromJson(Map<String, dynamic> json) =>
      _$GradedComparisonChangeFromJson(json);

  Map<String, dynamic> toJson() => _$GradedComparisonChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GradedComparisonChangeGradeEnum {
  @JsonValue(r'excluded')
  excluded(r'excluded'),
  @JsonValue(r'minor')
  minor(r'minor'),
  @JsonValue(r'general')
  general(r'general'),
  @JsonValue(r'significant')
  significant(r'significant');

  const GradedComparisonChangeGradeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum GradedComparisonChangeKindEnum {
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

  const GradedComparisonChangeKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
