//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_correlation_ids.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventCorrelationIds {
  /// Returns a new [EventCorrelationIds] instance.
  EventCorrelationIds({
    this.cookingRecordId,

    this.planId,

    this.recipeVersionId,

    this.recommendationExposureId,

    this.suggestionId,

    this.tasteProfileChangeId,

    this.uiCompositionId,
  });

  @JsonKey(name: r'cooking_record_id', required: false, includeIfNull: false)
  final String? cookingRecordId;

  @JsonKey(name: r'plan_id', required: false, includeIfNull: false)
  final String? planId;

  @JsonKey(name: r'recipe_version_id', required: false, includeIfNull: false)
  final String? recipeVersionId;

  @JsonKey(
    name: r'recommendation_exposure_id',
    required: false,
    includeIfNull: false,
  )
  final String? recommendationExposureId;

  @JsonKey(name: r'suggestion_id', required: false, includeIfNull: false)
  final String? suggestionId;

  @JsonKey(
    name: r'taste_profile_change_id',
    required: false,
    includeIfNull: false,
  )
  final String? tasteProfileChangeId;

  @JsonKey(name: r'ui_composition_id', required: false, includeIfNull: false)
  final String? uiCompositionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCorrelationIds &&
          other.cookingRecordId == cookingRecordId &&
          other.planId == planId &&
          other.recipeVersionId == recipeVersionId &&
          other.recommendationExposureId == recommendationExposureId &&
          other.suggestionId == suggestionId &&
          other.tasteProfileChangeId == tasteProfileChangeId &&
          other.uiCompositionId == uiCompositionId;

  @override
  int get hashCode =>
      (cookingRecordId == null ? 0 : cookingRecordId.hashCode) +
      (planId == null ? 0 : planId.hashCode) +
      (recipeVersionId == null ? 0 : recipeVersionId.hashCode) +
      (recommendationExposureId == null
          ? 0
          : recommendationExposureId.hashCode) +
      (suggestionId == null ? 0 : suggestionId.hashCode) +
      (tasteProfileChangeId == null ? 0 : tasteProfileChangeId.hashCode) +
      (uiCompositionId == null ? 0 : uiCompositionId.hashCode);

  factory EventCorrelationIds.fromJson(Map<String, dynamic> json) =>
      _$EventCorrelationIdsFromJson(json);

  Map<String, dynamic> toJson() => _$EventCorrelationIdsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
