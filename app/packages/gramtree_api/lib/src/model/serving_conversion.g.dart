// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serving_conversion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServingConversionCWProxy {
  ServingConversion activeTimeSeconds(int activeTimeSeconds);

  ServingConversion ingredients(List<ServingConversionIngredient> ingredients);

  ServingConversion maxServings(int maxServings);

  ServingConversion minServings(int minServings);

  ServingConversion originalServings(int originalServings);

  ServingConversion steps(List<ServingConversionStep> steps);

  ServingConversion targetServings(int targetServings);

  ServingConversion totalTimeSeconds(int totalTimeSeconds);

  ServingConversion warnings(List<ServingConversionWarning> warnings);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversion(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversion call({
    int activeTimeSeconds,
    List<ServingConversionIngredient> ingredients,
    int maxServings,
    int minServings,
    int originalServings,
    List<ServingConversionStep> steps,
    int targetServings,
    int totalTimeSeconds,
    List<ServingConversionWarning> warnings,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfServingConversion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfServingConversion.copyWith.fieldName(...)`
class _$ServingConversionCWProxyImpl implements _$ServingConversionCWProxy {
  const _$ServingConversionCWProxyImpl(this._value);

  final ServingConversion _value;

  @override
  ServingConversion activeTimeSeconds(int activeTimeSeconds) =>
      this(activeTimeSeconds: activeTimeSeconds);

  @override
  ServingConversion ingredients(
    List<ServingConversionIngredient> ingredients,
  ) => this(ingredients: ingredients);

  @override
  ServingConversion maxServings(int maxServings) =>
      this(maxServings: maxServings);

  @override
  ServingConversion minServings(int minServings) =>
      this(minServings: minServings);

  @override
  ServingConversion originalServings(int originalServings) =>
      this(originalServings: originalServings);

  @override
  ServingConversion steps(List<ServingConversionStep> steps) =>
      this(steps: steps);

  @override
  ServingConversion targetServings(int targetServings) =>
      this(targetServings: targetServings);

  @override
  ServingConversion totalTimeSeconds(int totalTimeSeconds) =>
      this(totalTimeSeconds: totalTimeSeconds);

  @override
  ServingConversion warnings(List<ServingConversionWarning> warnings) =>
      this(warnings: warnings);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversion(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversion call({
    Object? activeTimeSeconds = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? maxServings = const $CopyWithPlaceholder(),
    Object? minServings = const $CopyWithPlaceholder(),
    Object? originalServings = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? targetServings = const $CopyWithPlaceholder(),
    Object? totalTimeSeconds = const $CopyWithPlaceholder(),
    Object? warnings = const $CopyWithPlaceholder(),
  }) {
    return ServingConversion(
      activeTimeSeconds: activeTimeSeconds == const $CopyWithPlaceholder()
          ? _value.activeTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : activeTimeSeconds as int,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<ServingConversionIngredient>,
      maxServings: maxServings == const $CopyWithPlaceholder()
          ? _value.maxServings
          // ignore: cast_nullable_to_non_nullable
          : maxServings as int,
      minServings: minServings == const $CopyWithPlaceholder()
          ? _value.minServings
          // ignore: cast_nullable_to_non_nullable
          : minServings as int,
      originalServings: originalServings == const $CopyWithPlaceholder()
          ? _value.originalServings
          // ignore: cast_nullable_to_non_nullable
          : originalServings as int,
      steps: steps == const $CopyWithPlaceholder()
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<ServingConversionStep>,
      targetServings: targetServings == const $CopyWithPlaceholder()
          ? _value.targetServings
          // ignore: cast_nullable_to_non_nullable
          : targetServings as int,
      totalTimeSeconds: totalTimeSeconds == const $CopyWithPlaceholder()
          ? _value.totalTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : totalTimeSeconds as int,
      warnings: warnings == const $CopyWithPlaceholder()
          ? _value.warnings
          // ignore: cast_nullable_to_non_nullable
          : warnings as List<ServingConversionWarning>,
    );
  }
}

extension $ServingConversionCopyWith on ServingConversion {
  /// Returns a callable class that can be used as follows: `instanceOfServingConversion.copyWith(...)` or like so:`instanceOfServingConversion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServingConversionCWProxy get copyWith =>
      _$ServingConversionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServingConversion _$ServingConversionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ServingConversion',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'active_time_seconds',
        'ingredients',
        'max_servings',
        'min_servings',
        'original_servings',
        'steps',
        'target_servings',
        'total_time_seconds',
        'warnings',
      ],
    );
    final val = ServingConversion(
      activeTimeSeconds: $checkedConvert(
        'active_time_seconds',
        (v) => (v as num).toInt(),
      ),
      ingredients: $checkedConvert(
        'ingredients',
        (v) => (v as List<dynamic>)
            .map(
              (e) => ServingConversionIngredient.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      maxServings: $checkedConvert('max_servings', (v) => (v as num).toInt()),
      minServings: $checkedConvert('min_servings', (v) => (v as num).toInt()),
      originalServings: $checkedConvert(
        'original_servings',
        (v) => (v as num).toInt(),
      ),
      steps: $checkedConvert(
        'steps',
        (v) => (v as List<dynamic>)
            .map(
              (e) => ServingConversionStep.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      targetServings: $checkedConvert(
        'target_servings',
        (v) => (v as num).toInt(),
      ),
      totalTimeSeconds: $checkedConvert(
        'total_time_seconds',
        (v) => (v as num).toInt(),
      ),
      warnings: $checkedConvert(
        'warnings',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  ServingConversionWarning.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'activeTimeSeconds': 'active_time_seconds',
    'maxServings': 'max_servings',
    'minServings': 'min_servings',
    'originalServings': 'original_servings',
    'targetServings': 'target_servings',
    'totalTimeSeconds': 'total_time_seconds',
  },
);

Map<String, dynamic> _$ServingConversionToJson(ServingConversion instance) =>
    <String, dynamic>{
      'active_time_seconds': instance.activeTimeSeconds,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
      'max_servings': instance.maxServings,
      'min_servings': instance.minServings,
      'original_servings': instance.originalServings,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'target_servings': instance.targetServings,
      'total_time_seconds': instance.totalTimeSeconds,
      'warnings': instance.warnings.map((e) => e.toJson()).toList(),
    };
