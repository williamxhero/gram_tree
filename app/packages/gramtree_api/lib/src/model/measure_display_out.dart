//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'measure_display_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeasureDisplayOut {
  /// Returns a new [MeasureDisplayOut] instance.
  MeasureDisplayOut({
    required this.displayQuantity,

    required this.displayUnit,

    this.grams,

    required this.rule,

    required this.source_,

    required this.text,
  });

  @JsonKey(name: r'display_quantity', required: true, includeIfNull: false)
  final num displayQuantity;

  @JsonKey(name: r'display_unit', required: true, includeIfNull: false)
  final String displayUnit;

  @JsonKey(name: r'grams', required: false, includeIfNull: false)
  final num? grams;

  @JsonKey(name: r'rule', required: true, includeIfNull: false)
  final MeasureDisplayOutRuleEnum rule;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final SourcedValue source_;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureDisplayOut &&
          other.displayQuantity == displayQuantity &&
          other.displayUnit == displayUnit &&
          other.grams == grams &&
          other.rule == rule &&
          other.source_ == source_ &&
          other.text == text;

  @override
  int get hashCode =>
      displayQuantity.hashCode +
      displayUnit.hashCode +
      (grams == null ? 0 : grams.hashCode) +
      rule.hashCode +
      source_.hashCode +
      text.hashCode;

  factory MeasureDisplayOut.fromJson(Map<String, dynamic> json) =>
      _$MeasureDisplayOutFromJson(json);

  Map<String, dynamic> toJson() => _$MeasureDisplayOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MeasureDisplayOutRuleEnum {
  @JsonValue(r'base')
  base_(r'base'),
  @JsonValue(r'standard_measure')
  standardMeasure(r'standard_measure'),
  @JsonValue(r'personal_measure')
  personalMeasure(r'personal_measure'),
  @JsonValue(r'no_density')
  noDensity(r'no_density');

  const MeasureDisplayOutRuleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
