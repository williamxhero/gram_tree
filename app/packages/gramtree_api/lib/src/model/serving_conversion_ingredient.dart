//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'serving_conversion_ingredient.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServingConversionIngredient {
  /// Returns a new [ServingConversionIngredient] instance.
  ServingConversionIngredient({
    this.deviationRatio,

    this.deviationWarning = false,

    required this.displayName,

    required this.displayQuantity,

    required this.id,

    required this.originalQuantity,

    required this.rule,

    required this.unit,
  });

  @JsonKey(name: r'deviation_ratio', required: false, includeIfNull: false)
  final num? deviationRatio;

  @JsonKey(
    defaultValue: false,
    name: r'deviation_warning',
    required: false,
    includeIfNull: false,
  )
  final bool? deviationWarning;

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(name: r'display_quantity', required: true, includeIfNull: false)
  final num displayQuantity;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'original_quantity', required: true, includeIfNull: false)
  final num originalQuantity;

  @JsonKey(name: r'rule', required: true, includeIfNull: false)
  final ServingConversionIngredientRuleEnum rule;

  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final String unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServingConversionIngredient &&
          other.deviationRatio == deviationRatio &&
          other.deviationWarning == deviationWarning &&
          other.displayName == displayName &&
          other.displayQuantity == displayQuantity &&
          other.id == id &&
          other.originalQuantity == originalQuantity &&
          other.rule == rule &&
          other.unit == unit;

  @override
  int get hashCode =>
      (deviationRatio == null ? 0 : deviationRatio.hashCode) +
      deviationWarning.hashCode +
      displayName.hashCode +
      displayQuantity.hashCode +
      id.hashCode +
      originalQuantity.hashCode +
      rule.hashCode +
      unit.hashCode;

  factory ServingConversionIngredient.fromJson(Map<String, dynamic> json) =>
      _$ServingConversionIngredientFromJson(json);

  Map<String, dynamic> toJson() => _$ServingConversionIngredientToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ServingConversionIngredientRuleEnum {
  @JsonValue(r'proportional')
  proportional(r'proportional'),
  @JsonValue(r'unchanged')
  unchanged(r'unchanged'),
  @JsonValue(r'round')
  round(r'round');

  const ServingConversionIngredientRuleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
