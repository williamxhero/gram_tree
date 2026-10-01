// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_displayed_ingredient.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeDisplayedIngredientCWProxy {
  RecipeDisplayedIngredient displayName(String displayName);

  RecipeDisplayedIngredient displayQuantity(num displayQuantity);

  RecipeDisplayedIngredient displayUnit(String displayUnit);

  RecipeDisplayedIngredient grams(num? grams);

  RecipeDisplayedIngredient id(String id);

  RecipeDisplayedIngredient originalQuantity(num originalQuantity);

  RecipeDisplayedIngredient originalUnit(String originalUnit);

  RecipeDisplayedIngredient rule(RecipeDisplayedIngredientRuleEnum rule);

  RecipeDisplayedIngredient text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeDisplayedIngredient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeDisplayedIngredient(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeDisplayedIngredient call({
    String displayName,
    num displayQuantity,
    String displayUnit,
    num? grams,
    String id,
    num originalQuantity,
    String originalUnit,
    RecipeDisplayedIngredientRuleEnum rule,
    String text,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeDisplayedIngredient.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeDisplayedIngredient.copyWith.fieldName(...)`
class _$RecipeDisplayedIngredientCWProxyImpl
    implements _$RecipeDisplayedIngredientCWProxy {
  const _$RecipeDisplayedIngredientCWProxyImpl(this._value);

  final RecipeDisplayedIngredient _value;

  @override
  RecipeDisplayedIngredient displayName(String displayName) =>
      this(displayName: displayName);

  @override
  RecipeDisplayedIngredient displayQuantity(num displayQuantity) =>
      this(displayQuantity: displayQuantity);

  @override
  RecipeDisplayedIngredient displayUnit(String displayUnit) =>
      this(displayUnit: displayUnit);

  @override
  RecipeDisplayedIngredient grams(num? grams) => this(grams: grams);

  @override
  RecipeDisplayedIngredient id(String id) => this(id: id);

  @override
  RecipeDisplayedIngredient originalQuantity(num originalQuantity) =>
      this(originalQuantity: originalQuantity);

  @override
  RecipeDisplayedIngredient originalUnit(String originalUnit) =>
      this(originalUnit: originalUnit);

  @override
  RecipeDisplayedIngredient rule(RecipeDisplayedIngredientRuleEnum rule) =>
      this(rule: rule);

  @override
  RecipeDisplayedIngredient text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeDisplayedIngredient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeDisplayedIngredient(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeDisplayedIngredient call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? displayQuantity = const $CopyWithPlaceholder(),
    Object? displayUnit = const $CopyWithPlaceholder(),
    Object? grams = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? originalQuantity = const $CopyWithPlaceholder(),
    Object? originalUnit = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return RecipeDisplayedIngredient(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      displayQuantity: displayQuantity == const $CopyWithPlaceholder()
          ? _value.displayQuantity
          // ignore: cast_nullable_to_non_nullable
          : displayQuantity as num,
      displayUnit: displayUnit == const $CopyWithPlaceholder()
          ? _value.displayUnit
          // ignore: cast_nullable_to_non_nullable
          : displayUnit as String,
      grams: grams == const $CopyWithPlaceholder()
          ? _value.grams
          // ignore: cast_nullable_to_non_nullable
          : grams as num?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      originalQuantity: originalQuantity == const $CopyWithPlaceholder()
          ? _value.originalQuantity
          // ignore: cast_nullable_to_non_nullable
          : originalQuantity as num,
      originalUnit: originalUnit == const $CopyWithPlaceholder()
          ? _value.originalUnit
          // ignore: cast_nullable_to_non_nullable
          : originalUnit as String,
      rule: rule == const $CopyWithPlaceholder()
          ? _value.rule
          // ignore: cast_nullable_to_non_nullable
          : rule as RecipeDisplayedIngredientRuleEnum,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $RecipeDisplayedIngredientCopyWith on RecipeDisplayedIngredient {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeDisplayedIngredient.copyWith(...)` or like so:`instanceOfRecipeDisplayedIngredient.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeDisplayedIngredientCWProxy get copyWith =>
      _$RecipeDisplayedIngredientCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeDisplayedIngredient _$RecipeDisplayedIngredientFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeDisplayedIngredient',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'display_name',
        'display_quantity',
        'display_unit',
        'id',
        'original_quantity',
        'original_unit',
        'rule',
        'text',
      ],
    );
    final val = RecipeDisplayedIngredient(
      displayName: $checkedConvert('display_name', (v) => v as String),
      displayQuantity: $checkedConvert('display_quantity', (v) => v as num),
      displayUnit: $checkedConvert('display_unit', (v) => v as String),
      grams: $checkedConvert('grams', (v) => v as num?),
      id: $checkedConvert('id', (v) => v as String),
      originalQuantity: $checkedConvert('original_quantity', (v) => v as num),
      originalUnit: $checkedConvert('original_unit', (v) => v as String),
      rule: $checkedConvert(
        'rule',
        (v) => $enumDecode(_$RecipeDisplayedIngredientRuleEnumEnumMap, v),
      ),
      text: $checkedConvert('text', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'displayQuantity': 'display_quantity',
    'displayUnit': 'display_unit',
    'originalQuantity': 'original_quantity',
    'originalUnit': 'original_unit',
  },
);

Map<String, dynamic> _$RecipeDisplayedIngredientToJson(
  RecipeDisplayedIngredient instance,
) => <String, dynamic>{
  'display_name': instance.displayName,
  'display_quantity': instance.displayQuantity,
  'display_unit': instance.displayUnit,
  'grams': ?instance.grams,
  'id': instance.id,
  'original_quantity': instance.originalQuantity,
  'original_unit': instance.originalUnit,
  'rule': _$RecipeDisplayedIngredientRuleEnumEnumMap[instance.rule]!,
  'text': instance.text,
};

const _$RecipeDisplayedIngredientRuleEnumEnumMap = {
  RecipeDisplayedIngredientRuleEnum.base_: 'base',
  RecipeDisplayedIngredientRuleEnum.standardMeasure: 'standard_measure',
  RecipeDisplayedIngredientRuleEnum.personalMeasure: 'personal_measure',
  RecipeDisplayedIngredientRuleEnum.noDensity: 'no_density',
};
