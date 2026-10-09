// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient_comparison.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeIngredientComparisonCWProxy {
  RecipeIngredientComparison fromVersion(ComparisonVersion fromVersion);

  RecipeIngredientComparison ingredients(
    List<IngredientComparisonRow> ingredients,
  );

  RecipeIngredientComparison normalizedServings(int normalizedServings);

  RecipeIngredientComparison scope(RecipeIngredientComparisonScopeEnum scope);

  RecipeIngredientComparison snapshotFields(
    List<ComparisonChange>? snapshotFields,
  );

  RecipeIngredientComparison toVersion(ComparisonVersion toVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientComparison(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientComparison(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientComparison call({
    ComparisonVersion fromVersion,
    List<IngredientComparisonRow> ingredients,
    int normalizedServings,
    RecipeIngredientComparisonScopeEnum scope,
    List<ComparisonChange>? snapshotFields,
    ComparisonVersion toVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeIngredientComparison.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeIngredientComparison.copyWith.fieldName(...)`
class _$RecipeIngredientComparisonCWProxyImpl
    implements _$RecipeIngredientComparisonCWProxy {
  const _$RecipeIngredientComparisonCWProxyImpl(this._value);

  final RecipeIngredientComparison _value;

  @override
  RecipeIngredientComparison fromVersion(ComparisonVersion fromVersion) =>
      this(fromVersion: fromVersion);

  @override
  RecipeIngredientComparison ingredients(
    List<IngredientComparisonRow> ingredients,
  ) => this(ingredients: ingredients);

  @override
  RecipeIngredientComparison normalizedServings(int normalizedServings) =>
      this(normalizedServings: normalizedServings);

  @override
  RecipeIngredientComparison scope(RecipeIngredientComparisonScopeEnum scope) =>
      this(scope: scope);

  @override
  RecipeIngredientComparison snapshotFields(
    List<ComparisonChange>? snapshotFields,
  ) => this(snapshotFields: snapshotFields);

  @override
  RecipeIngredientComparison toVersion(ComparisonVersion toVersion) =>
      this(toVersion: toVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeIngredientComparison(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeIngredientComparison(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeIngredientComparison call({
    Object? fromVersion = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? normalizedServings = const $CopyWithPlaceholder(),
    Object? scope = const $CopyWithPlaceholder(),
    Object? snapshotFields = const $CopyWithPlaceholder(),
    Object? toVersion = const $CopyWithPlaceholder(),
  }) {
    return RecipeIngredientComparison(
      fromVersion: fromVersion == const $CopyWithPlaceholder()
          ? _value.fromVersion
          // ignore: cast_nullable_to_non_nullable
          : fromVersion as ComparisonVersion,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<IngredientComparisonRow>,
      normalizedServings: normalizedServings == const $CopyWithPlaceholder()
          ? _value.normalizedServings
          // ignore: cast_nullable_to_non_nullable
          : normalizedServings as int,
      scope: scope == const $CopyWithPlaceholder()
          ? _value.scope
          // ignore: cast_nullable_to_non_nullable
          : scope as RecipeIngredientComparisonScopeEnum,
      snapshotFields: snapshotFields == const $CopyWithPlaceholder()
          ? _value.snapshotFields
          // ignore: cast_nullable_to_non_nullable
          : snapshotFields as List<ComparisonChange>?,
      toVersion: toVersion == const $CopyWithPlaceholder()
          ? _value.toVersion
          // ignore: cast_nullable_to_non_nullable
          : toVersion as ComparisonVersion,
    );
  }
}

extension $RecipeIngredientComparisonCopyWith on RecipeIngredientComparison {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeIngredientComparison.copyWith(...)` or like so:`instanceOfRecipeIngredientComparison.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeIngredientComparisonCWProxy get copyWith =>
      _$RecipeIngredientComparisonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredientComparison _$RecipeIngredientComparisonFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeIngredientComparison',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'from_version',
        'ingredients',
        'normalized_servings',
        'scope',
        'to_version',
      ],
    );
    final val = RecipeIngredientComparison(
      fromVersion: $checkedConvert(
        'from_version',
        (v) => ComparisonVersion.fromJson(v as Map<String, dynamic>),
      ),
      ingredients: $checkedConvert(
        'ingredients',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  IngredientComparisonRow.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      normalizedServings: $checkedConvert(
        'normalized_servings',
        (v) => (v as num).toInt(),
      ),
      scope: $checkedConvert(
        'scope',
        (v) => $enumDecode(_$RecipeIngredientComparisonScopeEnumEnumMap, v),
      ),
      snapshotFields: $checkedConvert(
        'snapshot_fields',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ComparisonChange.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      toVersion: $checkedConvert(
        'to_version',
        (v) => ComparisonVersion.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'fromVersion': 'from_version',
    'normalizedServings': 'normalized_servings',
    'snapshotFields': 'snapshot_fields',
    'toVersion': 'to_version',
  },
);

Map<String, dynamic> _$RecipeIngredientComparisonToJson(
  RecipeIngredientComparison instance,
) => <String, dynamic>{
  'from_version': instance.fromVersion.toJson(),
  'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
  'normalized_servings': instance.normalizedServings,
  'scope': _$RecipeIngredientComparisonScopeEnumEnumMap[instance.scope]!,
  'snapshot_fields': ?instance.snapshotFields?.map((e) => e.toJson()).toList(),
  'to_version': instance.toVersion.toJson(),
};

const _$RecipeIngredientComparisonScopeEnumEnumMap = {
  RecipeIngredientComparisonScopeEnum.ingredients: 'ingredients',
};
