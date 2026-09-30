//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_ingredient_replacement.dart';
import 'package:gramtree_api/src/model/value_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_ingredient.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeIngredient {
  /// Returns a new [RecipeIngredient] instance.
  RecipeIngredient({
    required this.baseQuantity,

    required this.baseUnit,

    required this.displayName,

    this.functional = false,

    required this.group,

    required this.id,

    required this.ingredientId,

    this.optional = false,

    required this.preparation,

    required this.quantity,

    this.quantitySource,

    this.replacement,

    required this.scalingMode,

    required this.unit,
  });

  /// 换算后的基础数量
  @JsonKey(name: r'base_quantity', required: true, includeIfNull: false)
  final num baseQuantity;

  /// 换算后的基础单位
  @JsonKey(name: r'base_unit', required: true, includeIfNull: false)
  final RecipeIngredientBaseUnitEnum baseUnit;

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(
    defaultValue: false,
    name: r'functional',
    required: false,
    includeIfNull: false,
  )
  final bool? functional;

  /// 食材分组
  @JsonKey(name: r'group', required: true, includeIfNull: false)
  final String group;

  /// 菜谱内食材 ID
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  /// 标准食材 UUID；为空表示未收录
  @JsonKey(name: r'ingredient_id', required: true, includeIfNull: false)
  final String ingredientId;

  @JsonKey(
    defaultValue: false,
    name: r'optional',
    required: false,
    includeIfNull: false,
  )
  final bool? optional;

  /// 处理方式
  @JsonKey(name: r'preparation', required: true, includeIfNull: false)
  final String preparation;

  // minimum: 0.0
  // maximum: 10000000
  @JsonKey(name: r'quantity', required: true, includeIfNull: false)
  final num quantity;

  @JsonKey(name: r'quantity_source', required: false, includeIfNull: false)
  final ValueSource? quantitySource;

  @JsonKey(name: r'replacement', required: false, includeIfNull: false)
  final RecipeIngredientReplacement? replacement;

  @JsonKey(name: r'scaling_mode', required: true, includeIfNull: false)
  final RecipeIngredientScalingModeEnum scalingMode;

  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final String unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredient &&
          other.baseQuantity == baseQuantity &&
          other.baseUnit == baseUnit &&
          other.displayName == displayName &&
          other.functional == functional &&
          other.group == group &&
          other.id == id &&
          other.ingredientId == ingredientId &&
          other.optional == optional &&
          other.preparation == preparation &&
          other.quantity == quantity &&
          other.quantitySource == quantitySource &&
          other.replacement == replacement &&
          other.scalingMode == scalingMode &&
          other.unit == unit;

  @override
  int get hashCode =>
      baseQuantity.hashCode +
      baseUnit.hashCode +
      displayName.hashCode +
      functional.hashCode +
      group.hashCode +
      id.hashCode +
      ingredientId.hashCode +
      optional.hashCode +
      preparation.hashCode +
      quantity.hashCode +
      quantitySource.hashCode +
      replacement.hashCode +
      scalingMode.hashCode +
      unit.hashCode;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeIngredientToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// 换算后的基础单位
enum RecipeIngredientBaseUnitEnum {
  /// 换算后的基础单位
  @JsonValue(r'g')
  g(r'g'),

  /// 换算后的基础单位
  @JsonValue(r'ml')
  ml(r'ml'),

  /// 换算后的基础单位
  @JsonValue(r'count')
  count(r'count');

  const RecipeIngredientBaseUnitEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecipeIngredientScalingModeEnum {
  @JsonValue(r'proportional')
  proportional(r'proportional'),
  @JsonValue(r'unchanged')
  unchanged(r'unchanged'),
  @JsonValue(r'round')
  round(r'round');

  const RecipeIngredientScalingModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
