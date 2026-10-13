//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_displayed_ingredient.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeDisplayedIngredient {
  /// Returns a new [RecipeDisplayedIngredient] instance.
  RecipeDisplayedIngredient({
    required this.conversionRule,

    this.convertedQuantity,

    this.convertedUnit,

    required this.displayName,

    required this.displayQuantity,

    required this.displayUnit,

    this.grams,

    required this.id,

    required this.originalQuantity,

    required this.originalUnit,

    required this.rule,

    required this.source_,

    required this.text,
  });

  @JsonKey(name: r'conversion_rule', required: true, includeIfNull: false)
  final RecipeDisplayedIngredientConversionRuleEnum conversionRule;

  @JsonKey(name: r'converted_quantity', required: false, includeIfNull: false)
  final num? convertedQuantity;

  @JsonKey(name: r'converted_unit', required: false, includeIfNull: false)
  final String? convertedUnit;

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(name: r'display_quantity', required: true, includeIfNull: false)
  final num displayQuantity;

  @JsonKey(name: r'display_unit', required: true, includeIfNull: false)
  final String displayUnit;

  @JsonKey(name: r'grams', required: false, includeIfNull: false)
  final num? grams;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'original_quantity', required: true, includeIfNull: false)
  final num originalQuantity;

  @JsonKey(name: r'original_unit', required: true, includeIfNull: false)
  final String originalUnit;

  @JsonKey(name: r'rule', required: true, includeIfNull: false)
  final RecipeDisplayedIngredientRuleEnum rule;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final SourcedValue source_;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDisplayedIngredient &&
          other.conversionRule == conversionRule &&
          other.convertedQuantity == convertedQuantity &&
          other.convertedUnit == convertedUnit &&
          other.displayName == displayName &&
          other.displayQuantity == displayQuantity &&
          other.displayUnit == displayUnit &&
          other.grams == grams &&
          other.id == id &&
          other.originalQuantity == originalQuantity &&
          other.originalUnit == originalUnit &&
          other.rule == rule &&
          other.source_ == source_ &&
          other.text == text;

  @override
  int get hashCode =>
      conversionRule.hashCode +
      (convertedQuantity == null ? 0 : convertedQuantity.hashCode) +
      (convertedUnit == null ? 0 : convertedUnit.hashCode) +
      displayName.hashCode +
      displayQuantity.hashCode +
      displayUnit.hashCode +
      (grams == null ? 0 : grams.hashCode) +
      id.hashCode +
      originalQuantity.hashCode +
      originalUnit.hashCode +
      rule.hashCode +
      source_.hashCode +
      text.hashCode;

  factory RecipeDisplayedIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeDisplayedIngredientFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDisplayedIngredientToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeDisplayedIngredientConversionRuleEnum {
  @JsonValue(r'base')
  base_(r'base'),
  @JsonValue(r'proportional')
  proportional(r'proportional'),
  @JsonValue(r'unchanged')
  unchanged(r'unchanged'),
  @JsonValue(r'round')
  round(r'round'),
  @JsonValue(r'mold_ratio')
  moldRatio(r'mold_ratio');

  const RecipeDisplayedIngredientConversionRuleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecipeDisplayedIngredientRuleEnum {
  @JsonValue(r'base')
  base_(r'base'),
  @JsonValue(r'standard_measure')
  standardMeasure(r'standard_measure'),
  @JsonValue(r'personal_measure')
  personalMeasure(r'personal_measure'),
  @JsonValue(r'no_density')
  noDensity(r'no_density');

  const RecipeDisplayedIngredientRuleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
