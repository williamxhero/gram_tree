// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_full_comparison.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeFullComparisonCWProxy {
  RecipeFullComparison basis(List<String> basis);

  RecipeFullComparison conclusion(
    RecipeFullComparisonConclusionEnum conclusion,
  );

  RecipeFullComparison fromVersion(ComparisonVersion fromVersion);

  RecipeFullComparison ingredients(
    List<GradedIngredientComparisonRow> ingredients,
  );

  RecipeFullComparison methodChanges(
    List<GradedComparisonChange> methodChanges,
  );

  RecipeFullComparison normalizedServings(int normalizedServings);

  RecipeFullComparison rulesVersion(String rulesVersion);

  RecipeFullComparison scope(RecipeFullComparisonScopeEnum scope);

  RecipeFullComparison snapshotFields(
    List<GradedComparisonChange> snapshotFields,
  );

  RecipeFullComparison steps(List<StepComparisonRow> steps);

  RecipeFullComparison toVersion(ComparisonVersion toVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeFullComparison(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeFullComparison(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeFullComparison call({
    List<String> basis,
    RecipeFullComparisonConclusionEnum conclusion,
    ComparisonVersion fromVersion,
    List<GradedIngredientComparisonRow> ingredients,
    List<GradedComparisonChange> methodChanges,
    int normalizedServings,
    String rulesVersion,
    RecipeFullComparisonScopeEnum scope,
    List<GradedComparisonChange> snapshotFields,
    List<StepComparisonRow> steps,
    ComparisonVersion toVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeFullComparison.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeFullComparison.copyWith.fieldName(...)`
class _$RecipeFullComparisonCWProxyImpl
    implements _$RecipeFullComparisonCWProxy {
  const _$RecipeFullComparisonCWProxyImpl(this._value);

  final RecipeFullComparison _value;

  @override
  RecipeFullComparison basis(List<String> basis) => this(basis: basis);

  @override
  RecipeFullComparison conclusion(
    RecipeFullComparisonConclusionEnum conclusion,
  ) => this(conclusion: conclusion);

  @override
  RecipeFullComparison fromVersion(ComparisonVersion fromVersion) =>
      this(fromVersion: fromVersion);

  @override
  RecipeFullComparison ingredients(
    List<GradedIngredientComparisonRow> ingredients,
  ) => this(ingredients: ingredients);

  @override
  RecipeFullComparison methodChanges(
    List<GradedComparisonChange> methodChanges,
  ) => this(methodChanges: methodChanges);

  @override
  RecipeFullComparison normalizedServings(int normalizedServings) =>
      this(normalizedServings: normalizedServings);

  @override
  RecipeFullComparison rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  RecipeFullComparison scope(RecipeFullComparisonScopeEnum scope) =>
      this(scope: scope);

  @override
  RecipeFullComparison snapshotFields(
    List<GradedComparisonChange> snapshotFields,
  ) => this(snapshotFields: snapshotFields);

  @override
  RecipeFullComparison steps(List<StepComparisonRow> steps) =>
      this(steps: steps);

  @override
  RecipeFullComparison toVersion(ComparisonVersion toVersion) =>
      this(toVersion: toVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeFullComparison(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeFullComparison(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeFullComparison call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? conclusion = const $CopyWithPlaceholder(),
    Object? fromVersion = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? methodChanges = const $CopyWithPlaceholder(),
    Object? normalizedServings = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? scope = const $CopyWithPlaceholder(),
    Object? snapshotFields = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? toVersion = const $CopyWithPlaceholder(),
  }) {
    return RecipeFullComparison(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as List<String>,
      conclusion: conclusion == const $CopyWithPlaceholder()
          ? _value.conclusion
          // ignore: cast_nullable_to_non_nullable
          : conclusion as RecipeFullComparisonConclusionEnum,
      fromVersion: fromVersion == const $CopyWithPlaceholder()
          ? _value.fromVersion
          // ignore: cast_nullable_to_non_nullable
          : fromVersion as ComparisonVersion,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<GradedIngredientComparisonRow>,
      methodChanges: methodChanges == const $CopyWithPlaceholder()
          ? _value.methodChanges
          // ignore: cast_nullable_to_non_nullable
          : methodChanges as List<GradedComparisonChange>,
      normalizedServings: normalizedServings == const $CopyWithPlaceholder()
          ? _value.normalizedServings
          // ignore: cast_nullable_to_non_nullable
          : normalizedServings as int,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String,
      scope: scope == const $CopyWithPlaceholder()
          ? _value.scope
          // ignore: cast_nullable_to_non_nullable
          : scope as RecipeFullComparisonScopeEnum,
      snapshotFields: snapshotFields == const $CopyWithPlaceholder()
          ? _value.snapshotFields
          // ignore: cast_nullable_to_non_nullable
          : snapshotFields as List<GradedComparisonChange>,
      steps: steps == const $CopyWithPlaceholder()
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<StepComparisonRow>,
      toVersion: toVersion == const $CopyWithPlaceholder()
          ? _value.toVersion
          // ignore: cast_nullable_to_non_nullable
          : toVersion as ComparisonVersion,
    );
  }
}

extension $RecipeFullComparisonCopyWith on RecipeFullComparison {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeFullComparison.copyWith(...)` or like so:`instanceOfRecipeFullComparison.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeFullComparisonCWProxy get copyWith =>
      _$RecipeFullComparisonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeFullComparison _$RecipeFullComparisonFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeFullComparison',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'basis',
        'conclusion',
        'from_version',
        'ingredients',
        'method_changes',
        'normalized_servings',
        'rules_version',
        'scope',
        'snapshot_fields',
        'steps',
        'to_version',
      ],
    );
    final val = RecipeFullComparison(
      basis: $checkedConvert(
        'basis',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      conclusion: $checkedConvert(
        'conclusion',
        (v) => $enumDecode(_$RecipeFullComparisonConclusionEnumEnumMap, v),
      ),
      fromVersion: $checkedConvert(
        'from_version',
        (v) => ComparisonVersion.fromJson(v as Map<String, dynamic>),
      ),
      ingredients: $checkedConvert(
        'ingredients',
        (v) => (v as List<dynamic>)
            .map(
              (e) => GradedIngredientComparisonRow.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      methodChanges: $checkedConvert(
        'method_changes',
        (v) => (v as List<dynamic>)
            .map(
              (e) => GradedComparisonChange.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      normalizedServings: $checkedConvert(
        'normalized_servings',
        (v) => (v as num).toInt(),
      ),
      rulesVersion: $checkedConvert('rules_version', (v) => v as String),
      scope: $checkedConvert(
        'scope',
        (v) => $enumDecode(_$RecipeFullComparisonScopeEnumEnumMap, v),
      ),
      snapshotFields: $checkedConvert(
        'snapshot_fields',
        (v) => (v as List<dynamic>)
            .map(
              (e) => GradedComparisonChange.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      steps: $checkedConvert(
        'steps',
        (v) => (v as List<dynamic>)
            .map((e) => StepComparisonRow.fromJson(e as Map<String, dynamic>))
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
    'methodChanges': 'method_changes',
    'normalizedServings': 'normalized_servings',
    'rulesVersion': 'rules_version',
    'snapshotFields': 'snapshot_fields',
    'toVersion': 'to_version',
  },
);

Map<String, dynamic> _$RecipeFullComparisonToJson(
  RecipeFullComparison instance,
) => <String, dynamic>{
  'basis': instance.basis,
  'conclusion':
      _$RecipeFullComparisonConclusionEnumEnumMap[instance.conclusion]!,
  'from_version': instance.fromVersion.toJson(),
  'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
  'method_changes': instance.methodChanges.map((e) => e.toJson()).toList(),
  'normalized_servings': instance.normalizedServings,
  'rules_version': instance.rulesVersion,
  'scope': _$RecipeFullComparisonScopeEnumEnumMap[instance.scope]!,
  'snapshot_fields': instance.snapshotFields.map((e) => e.toJson()).toList(),
  'steps': instance.steps.map((e) => e.toJson()).toList(),
  'to_version': instance.toVersion.toJson(),
};

const _$RecipeFullComparisonConclusionEnumEnumMap = {
  RecipeFullComparisonConclusionEnum.noChange: 'no_change',
  RecipeFullComparisonConclusionEnum.minorOnly: 'minor_only',
  RecipeFullComparisonConclusionEnum.general: 'general',
  RecipeFullComparisonConclusionEnum.significant: 'significant',
};

const _$RecipeFullComparisonScopeEnumEnumMap = {
  RecipeFullComparisonScopeEnum.full: 'full',
};
