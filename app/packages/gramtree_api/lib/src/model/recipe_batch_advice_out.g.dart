// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_batch_advice_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeBatchAdviceOutCWProxy {
  RecipeBatchAdviceOut advice(BatchAdvice? advice);

  RecipeBatchAdviceOut eligible(bool eligible);

  RecipeBatchAdviceOut error(String? error);

  RecipeBatchAdviceOut originalServings(int originalServings);

  RecipeBatchAdviceOut recipeId(String recipeId);

  RecipeBatchAdviceOut status(AIStatus status);

  RecipeBatchAdviceOut targetServings(int targetServings);

  RecipeBatchAdviceOut versionId(String versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeBatchAdviceOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeBatchAdviceOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeBatchAdviceOut call({
    BatchAdvice? advice,
    bool eligible,
    String? error,
    int originalServings,
    String recipeId,
    AIStatus status,
    int targetServings,
    String versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeBatchAdviceOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeBatchAdviceOut.copyWith.fieldName(...)`
class _$RecipeBatchAdviceOutCWProxyImpl
    implements _$RecipeBatchAdviceOutCWProxy {
  const _$RecipeBatchAdviceOutCWProxyImpl(this._value);

  final RecipeBatchAdviceOut _value;

  @override
  RecipeBatchAdviceOut advice(BatchAdvice? advice) => this(advice: advice);

  @override
  RecipeBatchAdviceOut eligible(bool eligible) => this(eligible: eligible);

  @override
  RecipeBatchAdviceOut error(String? error) => this(error: error);

  @override
  RecipeBatchAdviceOut originalServings(int originalServings) =>
      this(originalServings: originalServings);

  @override
  RecipeBatchAdviceOut recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  RecipeBatchAdviceOut status(AIStatus status) => this(status: status);

  @override
  RecipeBatchAdviceOut targetServings(int targetServings) =>
      this(targetServings: targetServings);

  @override
  RecipeBatchAdviceOut versionId(String versionId) =>
      this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeBatchAdviceOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeBatchAdviceOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeBatchAdviceOut call({
    Object? advice = const $CopyWithPlaceholder(),
    Object? eligible = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? originalServings = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? targetServings = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return RecipeBatchAdviceOut(
      advice: advice == const $CopyWithPlaceholder()
          ? _value.advice
          // ignore: cast_nullable_to_non_nullable
          : advice as BatchAdvice?,
      eligible: eligible == const $CopyWithPlaceholder()
          ? _value.eligible
          // ignore: cast_nullable_to_non_nullable
          : eligible as bool,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      originalServings: originalServings == const $CopyWithPlaceholder()
          ? _value.originalServings
          // ignore: cast_nullable_to_non_nullable
          : originalServings as int,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AIStatus,
      targetServings: targetServings == const $CopyWithPlaceholder()
          ? _value.targetServings
          // ignore: cast_nullable_to_non_nullable
          : targetServings as int,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
    );
  }
}

extension $RecipeBatchAdviceOutCopyWith on RecipeBatchAdviceOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeBatchAdviceOut.copyWith(...)` or like so:`instanceOfRecipeBatchAdviceOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeBatchAdviceOutCWProxy get copyWith =>
      _$RecipeBatchAdviceOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeBatchAdviceOut _$RecipeBatchAdviceOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeBatchAdviceOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'eligible',
        'original_servings',
        'recipe_id',
        'status',
        'target_servings',
        'version_id',
      ],
    );
    final val = RecipeBatchAdviceOut(
      advice: $checkedConvert(
        'advice',
        (v) =>
            v == null ? null : BatchAdvice.fromJson(v as Map<String, dynamic>),
      ),
      eligible: $checkedConvert('eligible', (v) => v as bool),
      error: $checkedConvert('error', (v) => v as String?),
      originalServings: $checkedConvert(
        'original_servings',
        (v) => (v as num).toInt(),
      ),
      recipeId: $checkedConvert('recipe_id', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => AIStatus.fromJson(v as Map<String, dynamic>),
      ),
      targetServings: $checkedConvert(
        'target_servings',
        (v) => (v as num).toInt(),
      ),
      versionId: $checkedConvert('version_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'originalServings': 'original_servings',
    'recipeId': 'recipe_id',
    'targetServings': 'target_servings',
    'versionId': 'version_id',
  },
);

Map<String, dynamic> _$RecipeBatchAdviceOutToJson(
  RecipeBatchAdviceOut instance,
) => <String, dynamic>{
  'advice': ?instance.advice?.toJson(),
  'eligible': instance.eligible,
  'error': ?instance.error,
  'original_servings': instance.originalServings,
  'recipe_id': instance.recipeId,
  'status': instance.status.toJson(),
  'target_servings': instance.targetServings,
  'version_id': instance.versionId,
};
