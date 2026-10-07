// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_snapshot.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeSnapshotCWProxy {
  RecipeSnapshot activeTimeSeconds(int? activeTimeSeconds);

  RecipeSnapshot baseMold(MoldSpec? baseMold);

  RecipeSnapshot cuisine(String? cuisine);

  RecipeSnapshot description(String? description);

  RecipeSnapshot designRationale(String? designRationale);

  RecipeSnapshot difficulty(String? difficulty);

  RecipeSnapshot dishType(String? dishType);

  RecipeSnapshot formatVersion(RecipeSnapshotFormatVersionEnum formatVersion);

  RecipeSnapshot ingredients(List<RecipeIngredient>? ingredients);

  RecipeSnapshot servings(int servings);

  RecipeSnapshot servingsSource(ValueSource? servingsSource);

  RecipeSnapshot steps(List<RecipeStep>? steps);

  RecipeSnapshot tags(List<String>? tags);

  RecipeSnapshot textSource(ValueSource? textSource);

  RecipeSnapshot totalTimeSeconds(int? totalTimeSeconds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSnapshot(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSnapshot(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSnapshot call({
    int? activeTimeSeconds,
    MoldSpec? baseMold,
    String? cuisine,
    String? description,
    String? designRationale,
    String? difficulty,
    String? dishType,
    RecipeSnapshotFormatVersionEnum formatVersion,
    List<RecipeIngredient>? ingredients,
    int servings,
    ValueSource? servingsSource,
    List<RecipeStep>? steps,
    List<String>? tags,
    ValueSource? textSource,
    int? totalTimeSeconds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeSnapshot.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeSnapshot.copyWith.fieldName(...)`
class _$RecipeSnapshotCWProxyImpl implements _$RecipeSnapshotCWProxy {
  const _$RecipeSnapshotCWProxyImpl(this._value);

  final RecipeSnapshot _value;

  @override
  RecipeSnapshot activeTimeSeconds(int? activeTimeSeconds) =>
      this(activeTimeSeconds: activeTimeSeconds);

  @override
  RecipeSnapshot baseMold(MoldSpec? baseMold) => this(baseMold: baseMold);

  @override
  RecipeSnapshot cuisine(String? cuisine) => this(cuisine: cuisine);

  @override
  RecipeSnapshot description(String? description) =>
      this(description: description);

  @override
  RecipeSnapshot designRationale(String? designRationale) =>
      this(designRationale: designRationale);

  @override
  RecipeSnapshot difficulty(String? difficulty) => this(difficulty: difficulty);

  @override
  RecipeSnapshot dishType(String? dishType) => this(dishType: dishType);

  @override
  RecipeSnapshot formatVersion(RecipeSnapshotFormatVersionEnum formatVersion) =>
      this(formatVersion: formatVersion);

  @override
  RecipeSnapshot ingredients(List<RecipeIngredient>? ingredients) =>
      this(ingredients: ingredients);

  @override
  RecipeSnapshot servings(int servings) => this(servings: servings);

  @override
  RecipeSnapshot servingsSource(ValueSource? servingsSource) =>
      this(servingsSource: servingsSource);

  @override
  RecipeSnapshot steps(List<RecipeStep>? steps) => this(steps: steps);

  @override
  RecipeSnapshot tags(List<String>? tags) => this(tags: tags);

  @override
  RecipeSnapshot textSource(ValueSource? textSource) =>
      this(textSource: textSource);

  @override
  RecipeSnapshot totalTimeSeconds(int? totalTimeSeconds) =>
      this(totalTimeSeconds: totalTimeSeconds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSnapshot(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSnapshot(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSnapshot call({
    Object? activeTimeSeconds = const $CopyWithPlaceholder(),
    Object? baseMold = const $CopyWithPlaceholder(),
    Object? cuisine = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? designRationale = const $CopyWithPlaceholder(),
    Object? difficulty = const $CopyWithPlaceholder(),
    Object? dishType = const $CopyWithPlaceholder(),
    Object? formatVersion = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? servings = const $CopyWithPlaceholder(),
    Object? servingsSource = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? textSource = const $CopyWithPlaceholder(),
    Object? totalTimeSeconds = const $CopyWithPlaceholder(),
  }) {
    return RecipeSnapshot(
      activeTimeSeconds: activeTimeSeconds == const $CopyWithPlaceholder()
          ? _value.activeTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : activeTimeSeconds as int?,
      baseMold: baseMold == const $CopyWithPlaceholder()
          ? _value.baseMold
          // ignore: cast_nullable_to_non_nullable
          : baseMold as MoldSpec?,
      cuisine: cuisine == const $CopyWithPlaceholder()
          ? _value.cuisine
          // ignore: cast_nullable_to_non_nullable
          : cuisine as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      designRationale: designRationale == const $CopyWithPlaceholder()
          ? _value.designRationale
          // ignore: cast_nullable_to_non_nullable
          : designRationale as String?,
      difficulty: difficulty == const $CopyWithPlaceholder()
          ? _value.difficulty
          // ignore: cast_nullable_to_non_nullable
          : difficulty as String?,
      dishType: dishType == const $CopyWithPlaceholder()
          ? _value.dishType
          // ignore: cast_nullable_to_non_nullable
          : dishType as String?,
      formatVersion: formatVersion == const $CopyWithPlaceholder()
          ? _value.formatVersion
          // ignore: cast_nullable_to_non_nullable
          : formatVersion as RecipeSnapshotFormatVersionEnum,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<RecipeIngredient>?,
      servings: servings == const $CopyWithPlaceholder()
          ? _value.servings
          // ignore: cast_nullable_to_non_nullable
          : servings as int,
      servingsSource: servingsSource == const $CopyWithPlaceholder()
          ? _value.servingsSource
          // ignore: cast_nullable_to_non_nullable
          : servingsSource as ValueSource?,
      steps: steps == const $CopyWithPlaceholder()
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<RecipeStep>?,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>?,
      textSource: textSource == const $CopyWithPlaceholder()
          ? _value.textSource
          // ignore: cast_nullable_to_non_nullable
          : textSource as ValueSource?,
      totalTimeSeconds: totalTimeSeconds == const $CopyWithPlaceholder()
          ? _value.totalTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : totalTimeSeconds as int?,
    );
  }
}

extension $RecipeSnapshotCopyWith on RecipeSnapshot {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeSnapshot.copyWith(...)` or like so:`instanceOfRecipeSnapshot.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeSnapshotCWProxy get copyWith => _$RecipeSnapshotCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSnapshot _$RecipeSnapshotFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeSnapshot',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['format_version', 'servings']);
    final val = RecipeSnapshot(
      activeTimeSeconds: $checkedConvert(
        'active_time_seconds',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      baseMold: $checkedConvert(
        'base_mold',
        (v) => v == null ? null : MoldSpec.fromJson(v as Map<String, dynamic>),
      ),
      cuisine: $checkedConvert('cuisine', (v) => v as String?),
      description: $checkedConvert('description', (v) => v as String?),
      designRationale: $checkedConvert('design_rationale', (v) => v as String?),
      difficulty: $checkedConvert('difficulty', (v) => v as String?),
      dishType: $checkedConvert('dish_type', (v) => v as String?),
      formatVersion: $checkedConvert(
        'format_version',
        (v) => $enumDecode(_$RecipeSnapshotFormatVersionEnumEnumMap, v),
      ),
      ingredients: $checkedConvert(
        'ingredients',
        (v) => (v as List<dynamic>?)
            ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      servings: $checkedConvert('servings', (v) => (v as num).toInt()),
      servingsSource: $checkedConvert(
        'servings_source',
        (v) =>
            v == null ? null : ValueSource.fromJson(v as Map<String, dynamic>),
      ),
      steps: $checkedConvert(
        'steps',
        (v) => (v as List<dynamic>?)
            ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      tags: $checkedConvert(
        'tags',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      textSource: $checkedConvert(
        'text_source',
        (v) =>
            v == null ? null : ValueSource.fromJson(v as Map<String, dynamic>),
      ),
      totalTimeSeconds: $checkedConvert(
        'total_time_seconds',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'activeTimeSeconds': 'active_time_seconds',
    'baseMold': 'base_mold',
    'designRationale': 'design_rationale',
    'dishType': 'dish_type',
    'formatVersion': 'format_version',
    'servingsSource': 'servings_source',
    'textSource': 'text_source',
    'totalTimeSeconds': 'total_time_seconds',
  },
);

Map<String, dynamic> _$RecipeSnapshotToJson(RecipeSnapshot instance) =>
    <String, dynamic>{
      'active_time_seconds': ?instance.activeTimeSeconds,
      'base_mold': ?instance.baseMold?.toJson(),
      'cuisine': ?instance.cuisine,
      'description': ?instance.description,
      'design_rationale': ?instance.designRationale,
      'difficulty': ?instance.difficulty,
      'dish_type': ?instance.dishType,
      'format_version':
          _$RecipeSnapshotFormatVersionEnumEnumMap[instance.formatVersion]!,
      'ingredients': ?instance.ingredients?.map((e) => e.toJson()).toList(),
      'servings': instance.servings,
      'servings_source': ?instance.servingsSource?.toJson(),
      'steps': ?instance.steps?.map((e) => e.toJson()).toList(),
      'tags': ?instance.tags,
      'text_source': ?instance.textSource?.toJson(),
      'total_time_seconds': ?instance.totalTimeSeconds,
    };

const _$RecipeSnapshotFormatVersionEnumEnumMap = {
  RecipeSnapshotFormatVersionEnum.number1: 1,
};
