//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/cooking_completion.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_record_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingRecordCreate {
  /// Returns a new [CookingRecordCreate] instance.
  CookingRecordCreate({
    this.adjustments,

    required this.clientId,

    this.coDinerIds,

    this.completion,

    this.dishName,

    this.meal,

    this.occurredAt,

    this.recipeId,

    this.recipeVersionId,

    this.snapshot,

    required this.source_,

    this.sourceContext,

    required this.verification,
  });

  @JsonKey(name: r'adjustments', required: false, includeIfNull: false)
  final List<Object>? adjustments;

  @JsonKey(name: r'client_id', required: true, includeIfNull: false)
  final String clientId;

  @JsonKey(name: r'co_diner_ids', required: false, includeIfNull: false)
  final List<String>? coDinerIds;

  @JsonKey(name: r'completion', required: false, includeIfNull: false)
  final CookingCompletion? completion;

  @JsonKey(name: r'dish_name', required: false, includeIfNull: false)
  final String? dishName;

  @JsonKey(name: r'meal', required: false, includeIfNull: false)
  final CookingRecordCreateMealEnum? meal;

  @JsonKey(name: r'occurred_at', required: false, includeIfNull: false)
  final DateTime? occurredAt;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @JsonKey(name: r'recipe_version_id', required: false, includeIfNull: false)
  final String? recipeVersionId;

  @JsonKey(name: r'snapshot', required: false, includeIfNull: false)
  final Object? snapshot;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final CookingRecordCreateSource_Enum source_;

  @JsonKey(name: r'source_context', required: false, includeIfNull: false)
  final Object? sourceContext;

  @JsonKey(name: r'verification', required: true, includeIfNull: false)
  final CookingRecordCreateVerificationEnum verification;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingRecordCreate &&
          other.adjustments == adjustments &&
          other.clientId == clientId &&
          other.coDinerIds == coDinerIds &&
          other.completion == completion &&
          other.dishName == dishName &&
          other.meal == meal &&
          other.occurredAt == occurredAt &&
          other.recipeId == recipeId &&
          other.recipeVersionId == recipeVersionId &&
          other.snapshot == snapshot &&
          other.source_ == source_ &&
          other.sourceContext == sourceContext &&
          other.verification == verification;

  @override
  int get hashCode =>
      adjustments.hashCode +
      clientId.hashCode +
      coDinerIds.hashCode +
      completion.hashCode +
      (dishName == null ? 0 : dishName.hashCode) +
      (meal == null ? 0 : meal.hashCode) +
      (occurredAt == null ? 0 : occurredAt.hashCode) +
      (recipeId == null ? 0 : recipeId.hashCode) +
      (recipeVersionId == null ? 0 : recipeVersionId.hashCode) +
      (snapshot == null ? 0 : snapshot.hashCode) +
      source_.hashCode +
      sourceContext.hashCode +
      verification.hashCode;

  factory CookingRecordCreate.fromJson(Map<String, dynamic> json) =>
      _$CookingRecordCreateFromJson(json);

  Map<String, dynamic> toJson() => _$CookingRecordCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CookingRecordCreateMealEnum {
  @JsonValue(r'breakfast')
  breakfast(r'breakfast'),
  @JsonValue(r'lunch')
  lunch(r'lunch'),
  @JsonValue(r'dinner')
  dinner(r'dinner'),
  @JsonValue(r'snack')
  snack(r'snack');

  const CookingRecordCreateMealEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CookingRecordCreateSource_Enum {
  @JsonValue(r'cooking_session')
  cookingSession(r'cooking_session'),
  @JsonValue(r'recommendation')
  recommendation(r'recommendation'),
  @JsonValue(r'calendar')
  calendar(r'calendar'),
  @JsonValue(r'external_cooking')
  externalCooking(r'external_cooking'),
  @JsonValue(r'dining')
  dining(r'dining');

  const CookingRecordCreateSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CookingRecordCreateVerificationEnum {
  @JsonValue(r'cooking_mode')
  cookingMode(r'cooking_mode'),
  @JsonValue(r'unverified')
  unverified(r'unverified');

  const CookingRecordCreateVerificationEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
