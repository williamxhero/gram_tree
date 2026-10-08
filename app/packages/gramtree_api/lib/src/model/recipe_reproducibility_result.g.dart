// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_reproducibility_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeReproducibilityResultCWProxy {
  RecipeReproducibilityResult concreteFieldCount(int concreteFieldCount);

  RecipeReproducibilityResult fieldCompleteness(num fieldCompleteness);

  RecipeReproducibilityResult problems(List<ReproducibilityProblem>? problems);

  RecipeReproducibilityResult remainingCount(int remainingCount);

  RecipeReproducibilityResult requiredFieldCount(int requiredFieldCount);

  RecipeReproducibilityResult rulesVersion(String rulesVersion);

  RecipeReproducibilityResult state(RecipeReproducibilityResultStateEnum state);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReproducibilityResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReproducibilityResult(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReproducibilityResult call({
    int concreteFieldCount,
    num fieldCompleteness,
    List<ReproducibilityProblem>? problems,
    int remainingCount,
    int requiredFieldCount,
    String rulesVersion,
    RecipeReproducibilityResultStateEnum state,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeReproducibilityResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeReproducibilityResult.copyWith.fieldName(...)`
class _$RecipeReproducibilityResultCWProxyImpl
    implements _$RecipeReproducibilityResultCWProxy {
  const _$RecipeReproducibilityResultCWProxyImpl(this._value);

  final RecipeReproducibilityResult _value;

  @override
  RecipeReproducibilityResult concreteFieldCount(int concreteFieldCount) =>
      this(concreteFieldCount: concreteFieldCount);

  @override
  RecipeReproducibilityResult fieldCompleteness(num fieldCompleteness) =>
      this(fieldCompleteness: fieldCompleteness);

  @override
  RecipeReproducibilityResult problems(
    List<ReproducibilityProblem>? problems,
  ) => this(problems: problems);

  @override
  RecipeReproducibilityResult remainingCount(int remainingCount) =>
      this(remainingCount: remainingCount);

  @override
  RecipeReproducibilityResult requiredFieldCount(int requiredFieldCount) =>
      this(requiredFieldCount: requiredFieldCount);

  @override
  RecipeReproducibilityResult rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  RecipeReproducibilityResult state(
    RecipeReproducibilityResultStateEnum state,
  ) => this(state: state);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeReproducibilityResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeReproducibilityResult(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeReproducibilityResult call({
    Object? concreteFieldCount = const $CopyWithPlaceholder(),
    Object? fieldCompleteness = const $CopyWithPlaceholder(),
    Object? problems = const $CopyWithPlaceholder(),
    Object? remainingCount = const $CopyWithPlaceholder(),
    Object? requiredFieldCount = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
  }) {
    return RecipeReproducibilityResult(
      concreteFieldCount: concreteFieldCount == const $CopyWithPlaceholder()
          ? _value.concreteFieldCount
          // ignore: cast_nullable_to_non_nullable
          : concreteFieldCount as int,
      fieldCompleteness: fieldCompleteness == const $CopyWithPlaceholder()
          ? _value.fieldCompleteness
          // ignore: cast_nullable_to_non_nullable
          : fieldCompleteness as num,
      problems: problems == const $CopyWithPlaceholder()
          ? _value.problems
          // ignore: cast_nullable_to_non_nullable
          : problems as List<ReproducibilityProblem>?,
      remainingCount: remainingCount == const $CopyWithPlaceholder()
          ? _value.remainingCount
          // ignore: cast_nullable_to_non_nullable
          : remainingCount as int,
      requiredFieldCount: requiredFieldCount == const $CopyWithPlaceholder()
          ? _value.requiredFieldCount
          // ignore: cast_nullable_to_non_nullable
          : requiredFieldCount as int,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as RecipeReproducibilityResultStateEnum,
    );
  }
}

extension $RecipeReproducibilityResultCopyWith on RecipeReproducibilityResult {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeReproducibilityResult.copyWith(...)` or like so:`instanceOfRecipeReproducibilityResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeReproducibilityResultCWProxy get copyWith =>
      _$RecipeReproducibilityResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeReproducibilityResult _$RecipeReproducibilityResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeReproducibilityResult',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'concrete_field_count',
        'field_completeness',
        'remaining_count',
        'required_field_count',
        'rules_version',
        'state',
      ],
    );
    final val = RecipeReproducibilityResult(
      concreteFieldCount: $checkedConvert(
        'concrete_field_count',
        (v) => (v as num).toInt(),
      ),
      fieldCompleteness: $checkedConvert('field_completeness', (v) => v as num),
      problems: $checkedConvert(
        'problems',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => ReproducibilityProblem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      remainingCount: $checkedConvert(
        'remaining_count',
        (v) => (v as num).toInt(),
      ),
      requiredFieldCount: $checkedConvert(
        'required_field_count',
        (v) => (v as num).toInt(),
      ),
      rulesVersion: $checkedConvert('rules_version', (v) => v as String),
      state: $checkedConvert(
        'state',
        (v) => $enumDecode(_$RecipeReproducibilityResultStateEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'concreteFieldCount': 'concrete_field_count',
    'fieldCompleteness': 'field_completeness',
    'remainingCount': 'remaining_count',
    'requiredFieldCount': 'required_field_count',
    'rulesVersion': 'rules_version',
  },
);

Map<String, dynamic> _$RecipeReproducibilityResultToJson(
  RecipeReproducibilityResult instance,
) => <String, dynamic>{
  'concrete_field_count': instance.concreteFieldCount,
  'field_completeness': instance.fieldCompleteness,
  'problems': ?instance.problems?.map((e) => e.toJson()).toList(),
  'remaining_count': instance.remainingCount,
  'required_field_count': instance.requiredFieldCount,
  'rules_version': instance.rulesVersion,
  'state': _$RecipeReproducibilityResultStateEnumEnumMap[instance.state]!,
};

const _$RecipeReproducibilityResultStateEnumEnumMap = {
  RecipeReproducibilityResultStateEnum.incomplete: 'incomplete',
  RecipeReproducibilityResultStateEnum.reproducible: 'reproducible',
};
