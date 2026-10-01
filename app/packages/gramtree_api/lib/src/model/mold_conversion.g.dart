// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mold_conversion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MoldConversionCWProxy {
  MoldConversion areaRatio(num areaRatio);

  MoldConversion ingredients(List<MoldConversionIngredient> ingredients);

  MoldConversion originalMold(MoldSpec originalMold);

  MoldConversion steps(List<MoldConversionStep> steps);

  MoldConversion targetMold(MoldSpec targetMold);

  MoldConversion warnings(List<MoldConversionWarning> warnings);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversion(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversion call({
    num areaRatio,
    List<MoldConversionIngredient> ingredients,
    MoldSpec originalMold,
    List<MoldConversionStep> steps,
    MoldSpec targetMold,
    List<MoldConversionWarning> warnings,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMoldConversion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMoldConversion.copyWith.fieldName(...)`
class _$MoldConversionCWProxyImpl implements _$MoldConversionCWProxy {
  const _$MoldConversionCWProxyImpl(this._value);

  final MoldConversion _value;

  @override
  MoldConversion areaRatio(num areaRatio) => this(areaRatio: areaRatio);

  @override
  MoldConversion ingredients(List<MoldConversionIngredient> ingredients) =>
      this(ingredients: ingredients);

  @override
  MoldConversion originalMold(MoldSpec originalMold) =>
      this(originalMold: originalMold);

  @override
  MoldConversion steps(List<MoldConversionStep> steps) => this(steps: steps);

  @override
  MoldConversion targetMold(MoldSpec targetMold) =>
      this(targetMold: targetMold);

  @override
  MoldConversion warnings(List<MoldConversionWarning> warnings) =>
      this(warnings: warnings);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversion(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversion call({
    Object? areaRatio = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? originalMold = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? targetMold = const $CopyWithPlaceholder(),
    Object? warnings = const $CopyWithPlaceholder(),
  }) {
    return MoldConversion(
      areaRatio: areaRatio == const $CopyWithPlaceholder()
          ? _value.areaRatio
          // ignore: cast_nullable_to_non_nullable
          : areaRatio as num,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<MoldConversionIngredient>,
      originalMold: originalMold == const $CopyWithPlaceholder()
          ? _value.originalMold
          // ignore: cast_nullable_to_non_nullable
          : originalMold as MoldSpec,
      steps: steps == const $CopyWithPlaceholder()
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<MoldConversionStep>,
      targetMold: targetMold == const $CopyWithPlaceholder()
          ? _value.targetMold
          // ignore: cast_nullable_to_non_nullable
          : targetMold as MoldSpec,
      warnings: warnings == const $CopyWithPlaceholder()
          ? _value.warnings
          // ignore: cast_nullable_to_non_nullable
          : warnings as List<MoldConversionWarning>,
    );
  }
}

extension $MoldConversionCopyWith on MoldConversion {
  /// Returns a callable class that can be used as follows: `instanceOfMoldConversion.copyWith(...)` or like so:`instanceOfMoldConversion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MoldConversionCWProxy get copyWith => _$MoldConversionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoldConversion _$MoldConversionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MoldConversion',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'area_ratio',
        'ingredients',
        'original_mold',
        'steps',
        'target_mold',
        'warnings',
      ],
    );
    final val = MoldConversion(
      areaRatio: $checkedConvert('area_ratio', (v) => v as num),
      ingredients: $checkedConvert(
        'ingredients',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  MoldConversionIngredient.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      originalMold: $checkedConvert(
        'original_mold',
        (v) => MoldSpec.fromJson(v as Map<String, dynamic>),
      ),
      steps: $checkedConvert(
        'steps',
        (v) => (v as List<dynamic>)
            .map((e) => MoldConversionStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      targetMold: $checkedConvert(
        'target_mold',
        (v) => MoldSpec.fromJson(v as Map<String, dynamic>),
      ),
      warnings: $checkedConvert(
        'warnings',
        (v) => (v as List<dynamic>)
            .map(
              (e) => MoldConversionWarning.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'areaRatio': 'area_ratio',
    'originalMold': 'original_mold',
    'targetMold': 'target_mold',
  },
);

Map<String, dynamic> _$MoldConversionToJson(MoldConversion instance) =>
    <String, dynamic>{
      'area_ratio': instance.areaRatio,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
      'original_mold': instance.originalMold.toJson(),
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'target_mold': instance.targetMold.toJson(),
      'warnings': instance.warnings.map((e) => e.toJson()).toList(),
    };
