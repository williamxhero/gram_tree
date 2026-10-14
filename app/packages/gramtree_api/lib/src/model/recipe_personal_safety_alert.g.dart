// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_personal_safety_alert.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipePersonalSafetyAlertCWProxy {
  RecipePersonalSafetyAlert ingredient(String ingredient);

  RecipePersonalSafetyAlert kind(RecipePersonalSafetyAlertKindEnum kind);

  RecipePersonalSafetyAlert person(String person);

  RecipePersonalSafetyAlert replacement(bool? replacement);

  RecipePersonalSafetyAlert target(String target);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipePersonalSafetyAlert(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipePersonalSafetyAlert(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipePersonalSafetyAlert call({
    String ingredient,
    RecipePersonalSafetyAlertKindEnum kind,
    String person,
    bool? replacement,
    String target,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipePersonalSafetyAlert.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipePersonalSafetyAlert.copyWith.fieldName(...)`
class _$RecipePersonalSafetyAlertCWProxyImpl
    implements _$RecipePersonalSafetyAlertCWProxy {
  const _$RecipePersonalSafetyAlertCWProxyImpl(this._value);

  final RecipePersonalSafetyAlert _value;

  @override
  RecipePersonalSafetyAlert ingredient(String ingredient) =>
      this(ingredient: ingredient);

  @override
  RecipePersonalSafetyAlert kind(RecipePersonalSafetyAlertKindEnum kind) =>
      this(kind: kind);

  @override
  RecipePersonalSafetyAlert person(String person) => this(person: person);

  @override
  RecipePersonalSafetyAlert replacement(bool? replacement) =>
      this(replacement: replacement);

  @override
  RecipePersonalSafetyAlert target(String target) => this(target: target);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipePersonalSafetyAlert(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipePersonalSafetyAlert(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipePersonalSafetyAlert call({
    Object? ingredient = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? person = const $CopyWithPlaceholder(),
    Object? replacement = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
  }) {
    return RecipePersonalSafetyAlert(
      ingredient: ingredient == const $CopyWithPlaceholder()
          ? _value.ingredient
          // ignore: cast_nullable_to_non_nullable
          : ingredient as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as RecipePersonalSafetyAlertKindEnum,
      person: person == const $CopyWithPlaceholder()
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as String,
      replacement: replacement == const $CopyWithPlaceholder()
          ? _value.replacement
          // ignore: cast_nullable_to_non_nullable
          : replacement as bool?,
      target: target == const $CopyWithPlaceholder()
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as String,
    );
  }
}

extension $RecipePersonalSafetyAlertCopyWith on RecipePersonalSafetyAlert {
  /// Returns a callable class that can be used as follows: `instanceOfRecipePersonalSafetyAlert.copyWith(...)` or like so:`instanceOfRecipePersonalSafetyAlert.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipePersonalSafetyAlertCWProxy get copyWith =>
      _$RecipePersonalSafetyAlertCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipePersonalSafetyAlert _$RecipePersonalSafetyAlertFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipePersonalSafetyAlert', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['ingredient', 'kind', 'person', 'target'],
  );
  final val = RecipePersonalSafetyAlert(
    ingredient: $checkedConvert('ingredient', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$RecipePersonalSafetyAlertKindEnumEnumMap, v),
    ),
    person: $checkedConvert('person', (v) => v as String),
    replacement: $checkedConvert('replacement', (v) => v as bool? ?? false),
    target: $checkedConvert('target', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RecipePersonalSafetyAlertToJson(
  RecipePersonalSafetyAlert instance,
) => <String, dynamic>{
  'ingredient': instance.ingredient,
  'kind': _$RecipePersonalSafetyAlertKindEnumEnumMap[instance.kind]!,
  'person': instance.person,
  'replacement': ?instance.replacement,
  'target': instance.target,
};

const _$RecipePersonalSafetyAlertKindEnumEnumMap = {
  RecipePersonalSafetyAlertKindEnum.allergy: 'allergy',
  RecipePersonalSafetyAlertKindEnum.avoidance: 'avoidance',
};
