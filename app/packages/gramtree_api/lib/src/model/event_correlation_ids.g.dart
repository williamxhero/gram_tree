// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_correlation_ids.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EventCorrelationIdsCWProxy {
  EventCorrelationIds cookingRecordId(String? cookingRecordId);

  EventCorrelationIds planId(String? planId);

  EventCorrelationIds recipeVersionId(String? recipeVersionId);

  EventCorrelationIds recommendationExposureId(
    String? recommendationExposureId,
  );

  EventCorrelationIds suggestionId(String? suggestionId);

  EventCorrelationIds tasteProfileChangeId(String? tasteProfileChangeId);

  EventCorrelationIds uiCompositionId(String? uiCompositionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventCorrelationIds(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventCorrelationIds(...).copyWith(id: 12, name: "My name")
  /// ````
  EventCorrelationIds call({
    String? cookingRecordId,
    String? planId,
    String? recipeVersionId,
    String? recommendationExposureId,
    String? suggestionId,
    String? tasteProfileChangeId,
    String? uiCompositionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEventCorrelationIds.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEventCorrelationIds.copyWith.fieldName(...)`
class _$EventCorrelationIdsCWProxyImpl implements _$EventCorrelationIdsCWProxy {
  const _$EventCorrelationIdsCWProxyImpl(this._value);

  final EventCorrelationIds _value;

  @override
  EventCorrelationIds cookingRecordId(String? cookingRecordId) =>
      this(cookingRecordId: cookingRecordId);

  @override
  EventCorrelationIds planId(String? planId) => this(planId: planId);

  @override
  EventCorrelationIds recipeVersionId(String? recipeVersionId) =>
      this(recipeVersionId: recipeVersionId);

  @override
  EventCorrelationIds recommendationExposureId(
    String? recommendationExposureId,
  ) => this(recommendationExposureId: recommendationExposureId);

  @override
  EventCorrelationIds suggestionId(String? suggestionId) =>
      this(suggestionId: suggestionId);

  @override
  EventCorrelationIds tasteProfileChangeId(String? tasteProfileChangeId) =>
      this(tasteProfileChangeId: tasteProfileChangeId);

  @override
  EventCorrelationIds uiCompositionId(String? uiCompositionId) =>
      this(uiCompositionId: uiCompositionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventCorrelationIds(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventCorrelationIds(...).copyWith(id: 12, name: "My name")
  /// ````
  EventCorrelationIds call({
    Object? cookingRecordId = const $CopyWithPlaceholder(),
    Object? planId = const $CopyWithPlaceholder(),
    Object? recipeVersionId = const $CopyWithPlaceholder(),
    Object? recommendationExposureId = const $CopyWithPlaceholder(),
    Object? suggestionId = const $CopyWithPlaceholder(),
    Object? tasteProfileChangeId = const $CopyWithPlaceholder(),
    Object? uiCompositionId = const $CopyWithPlaceholder(),
  }) {
    return EventCorrelationIds(
      cookingRecordId: cookingRecordId == const $CopyWithPlaceholder()
          ? _value.cookingRecordId
          // ignore: cast_nullable_to_non_nullable
          : cookingRecordId as String?,
      planId: planId == const $CopyWithPlaceholder()
          ? _value.planId
          // ignore: cast_nullable_to_non_nullable
          : planId as String?,
      recipeVersionId: recipeVersionId == const $CopyWithPlaceholder()
          ? _value.recipeVersionId
          // ignore: cast_nullable_to_non_nullable
          : recipeVersionId as String?,
      recommendationExposureId:
          recommendationExposureId == const $CopyWithPlaceholder()
          ? _value.recommendationExposureId
          // ignore: cast_nullable_to_non_nullable
          : recommendationExposureId as String?,
      suggestionId: suggestionId == const $CopyWithPlaceholder()
          ? _value.suggestionId
          // ignore: cast_nullable_to_non_nullable
          : suggestionId as String?,
      tasteProfileChangeId: tasteProfileChangeId == const $CopyWithPlaceholder()
          ? _value.tasteProfileChangeId
          // ignore: cast_nullable_to_non_nullable
          : tasteProfileChangeId as String?,
      uiCompositionId: uiCompositionId == const $CopyWithPlaceholder()
          ? _value.uiCompositionId
          // ignore: cast_nullable_to_non_nullable
          : uiCompositionId as String?,
    );
  }
}

extension $EventCorrelationIdsCopyWith on EventCorrelationIds {
  /// Returns a callable class that can be used as follows: `instanceOfEventCorrelationIds.copyWith(...)` or like so:`instanceOfEventCorrelationIds.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EventCorrelationIdsCWProxy get copyWith =>
      _$EventCorrelationIdsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventCorrelationIds _$EventCorrelationIdsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EventCorrelationIds',
      json,
      ($checkedConvert) {
        final val = EventCorrelationIds(
          cookingRecordId: $checkedConvert(
            'cooking_record_id',
            (v) => v as String?,
          ),
          planId: $checkedConvert('plan_id', (v) => v as String?),
          recipeVersionId: $checkedConvert(
            'recipe_version_id',
            (v) => v as String?,
          ),
          recommendationExposureId: $checkedConvert(
            'recommendation_exposure_id',
            (v) => v as String?,
          ),
          suggestionId: $checkedConvert('suggestion_id', (v) => v as String?),
          tasteProfileChangeId: $checkedConvert(
            'taste_profile_change_id',
            (v) => v as String?,
          ),
          uiCompositionId: $checkedConvert(
            'ui_composition_id',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'cookingRecordId': 'cooking_record_id',
        'planId': 'plan_id',
        'recipeVersionId': 'recipe_version_id',
        'recommendationExposureId': 'recommendation_exposure_id',
        'suggestionId': 'suggestion_id',
        'tasteProfileChangeId': 'taste_profile_change_id',
        'uiCompositionId': 'ui_composition_id',
      },
    );

Map<String, dynamic> _$EventCorrelationIdsToJson(
  EventCorrelationIds instance,
) => <String, dynamic>{
  'cooking_record_id': ?instance.cookingRecordId,
  'plan_id': ?instance.planId,
  'recipe_version_id': ?instance.recipeVersionId,
  'recommendation_exposure_id': ?instance.recommendationExposureId,
  'suggestion_id': ?instance.suggestionId,
  'taste_profile_change_id': ?instance.tasteProfileChangeId,
  'ui_composition_id': ?instance.uiCompositionId,
};
