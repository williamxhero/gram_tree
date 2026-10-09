//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'step_comparison_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StepComparisonChange {
  /// Returns a new [StepComparisonChange] instance.
  StepComparisonChange({
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
  final StepComparisonChangeGradeEnum grade;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final StepComparisonChangeKindEnum kind;

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
      other is StepComparisonChange &&
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

  factory StepComparisonChange.fromJson(Map<String, dynamic> json) =>
      _$StepComparisonChangeFromJson(json);

  Map<String, dynamic> toJson() => _$StepComparisonChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum StepComparisonChangeGradeEnum {
  @JsonValue(r'excluded')
  excluded(r'excluded'),
  @JsonValue(r'minor')
  minor(r'minor'),
  @JsonValue(r'general')
  general(r'general'),
  @JsonValue(r'significant')
  significant(r'significant');

  const StepComparisonChangeGradeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum StepComparisonChangeKindEnum {
  @JsonValue(r'added')
  added(r'added'),
  @JsonValue(r'removed')
  removed(r'removed'),
  @JsonValue(r'field')
  field(r'field'),
  @JsonValue(r'text')
  text(r'text'),
  @JsonValue(r'order')
  order(r'order');

  const StepComparisonChangeKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
