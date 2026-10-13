//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_step.dart';
import 'package:gramtree_api/src/model/step_comparison_change.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'step_comparison_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StepComparisonRow {
  /// Returns a new [StepComparisonRow] instance.
  StepComparisonRow({
    this.after,

    this.afterIndex,

    required this.alignment,

    required this.basis,

    this.before,

    this.beforeIndex,

    this.changes,

    required this.confidence,
  });

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final RecipeStep? after;

  @JsonKey(name: r'after_index', required: false, includeIfNull: false)
  final int? afterIndex;

  @JsonKey(name: r'alignment', required: true, includeIfNull: false)
  final StepComparisonRowAlignmentEnum alignment;

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'before', required: false, includeIfNull: false)
  final RecipeStep? before;

  @JsonKey(name: r'before_index', required: false, includeIfNull: false)
  final int? beforeIndex;

  @JsonKey(name: r'changes', required: false, includeIfNull: false)
  final List<StepComparisonChange>? changes;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final num confidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepComparisonRow &&
          other.after == after &&
          other.afterIndex == afterIndex &&
          other.alignment == alignment &&
          other.basis == basis &&
          other.before == before &&
          other.beforeIndex == beforeIndex &&
          other.changes == changes &&
          other.confidence == confidence;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      (afterIndex == null ? 0 : afterIndex.hashCode) +
      alignment.hashCode +
      basis.hashCode +
      (before == null ? 0 : before.hashCode) +
      (beforeIndex == null ? 0 : beforeIndex.hashCode) +
      changes.hashCode +
      confidence.hashCode;

  factory StepComparisonRow.fromJson(Map<String, dynamic> json) =>
      _$StepComparisonRowFromJson(json);

  Map<String, dynamic> toJson() => _$StepComparisonRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum StepComparisonRowAlignmentEnum {
  @JsonValue(r'deterministic')
  deterministic(r'deterministic'),
  @JsonValue(r'uncertain')
  uncertain(r'uncertain'),
  @JsonValue(r'unpaired')
  unpaired(r'unpaired');

  const StepComparisonRowAlignmentEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
