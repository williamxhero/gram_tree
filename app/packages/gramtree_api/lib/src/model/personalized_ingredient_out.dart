//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personalized_ingredient_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalizedIngredientOut {
  /// Returns a new [PersonalizedIngredientOut] instance.
  PersonalizedIngredientOut({
    required this.changed,

    required this.displayName,

    required this.displayQuantity,

    required this.displayUnit,

    required this.factor,

    required this.id,

    required this.originalName,

    required this.originalQuantity,

    required this.originalUnit,

    required this.reason,

    required this.rule,
  });

  @JsonKey(name: r'changed', required: true, includeIfNull: false)
  final bool changed;

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(name: r'display_quantity', required: true, includeIfNull: false)
  final num displayQuantity;

  @JsonKey(name: r'display_unit', required: true, includeIfNull: false)
  final String displayUnit;

  @JsonKey(name: r'factor', required: true, includeIfNull: false)
  final num factor;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'original_name', required: true, includeIfNull: false)
  final String originalName;

  @JsonKey(name: r'original_quantity', required: true, includeIfNull: false)
  final num originalQuantity;

  @JsonKey(name: r'original_unit', required: true, includeIfNull: false)
  final String originalUnit;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'rule', required: true, includeIfNull: false)
  final String rule;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedIngredientOut &&
          other.changed == changed &&
          other.displayName == displayName &&
          other.displayQuantity == displayQuantity &&
          other.displayUnit == displayUnit &&
          other.factor == factor &&
          other.id == id &&
          other.originalName == originalName &&
          other.originalQuantity == originalQuantity &&
          other.originalUnit == originalUnit &&
          other.reason == reason &&
          other.rule == rule;

  @override
  int get hashCode =>
      changed.hashCode +
      displayName.hashCode +
      displayQuantity.hashCode +
      displayUnit.hashCode +
      factor.hashCode +
      id.hashCode +
      originalName.hashCode +
      originalQuantity.hashCode +
      originalUnit.hashCode +
      reason.hashCode +
      rule.hashCode;

  factory PersonalizedIngredientOut.fromJson(Map<String, dynamic> json) =>
      _$PersonalizedIngredientOutFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalizedIngredientOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
