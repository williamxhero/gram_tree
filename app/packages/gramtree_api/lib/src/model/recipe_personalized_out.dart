//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/personalized_ingredient_out.dart';
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:gramtree_api/src/model/personalization_request.dart';
import 'package:gramtree_api/src/model/recipe_personal_safety.dart';
import 'package:gramtree_api/src/model/personalized_step_out.dart';
import 'package:gramtree_api/src/model/recipe_safety_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_personalized_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipePersonalizedOut {
  /// Returns a new [RecipePersonalizedOut] instance.
  RecipePersonalizedOut({
    required this.adjustmentLimit,

    required this.authorizationVersion,

    required this.blocked,

    required this.cacheKey,

    required this.effectiveFlavors,

    this.executionToken,

    this.fallback,

    required this.foodSafety,

    required this.ingredients,

    required this.inputs,

    this.notices,

    required this.profileVersion,

    required this.recipeId,

    required this.safety,

    required this.snapshot,

    required this.snapshotUnchanged,

    required this.steps,

    required this.versionId,

    required this.view,
  });

  @JsonKey(name: r'adjustment_limit', required: true, includeIfNull: false)
  final num adjustmentLimit;

  @JsonKey(name: r'authorization_version', required: true, includeIfNull: false)
  final int authorizationVersion;

  @JsonKey(name: r'blocked', required: true, includeIfNull: false)
  final bool blocked;

  @JsonKey(name: r'cache_key', required: true, includeIfNull: false)
  final String cacheKey;

  @JsonKey(name: r'effective_flavors', required: true, includeIfNull: false)
  final Map<String, num> effectiveFlavors;

  @JsonKey(name: r'execution_token', required: false, includeIfNull: false)
  final String? executionToken;

  @JsonKey(name: r'fallback', required: false, includeIfNull: false)
  final String? fallback;

  @JsonKey(name: r'food_safety', required: true, includeIfNull: false)
  final RecipeSafetyResult foodSafety;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<PersonalizedIngredientOut> ingredients;

  @JsonKey(name: r'inputs', required: true, includeIfNull: false)
  final PersonalizationRequest inputs;

  @JsonKey(name: r'notices', required: false, includeIfNull: false)
  final List<String>? notices;

  @JsonKey(name: r'profile_version', required: true, includeIfNull: false)
  final int profileVersion;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'safety', required: true, includeIfNull: false)
  final RecipePersonalSafety safety;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @JsonKey(name: r'snapshot_unchanged', required: true, includeIfNull: false)
  final bool snapshotUnchanged;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<PersonalizedStepOut> steps;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @JsonKey(name: r'view', required: true, includeIfNull: false)
  final RecipePersonalizedOutViewEnum view;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipePersonalizedOut &&
          other.adjustmentLimit == adjustmentLimit &&
          other.authorizationVersion == authorizationVersion &&
          other.blocked == blocked &&
          other.cacheKey == cacheKey &&
          other.effectiveFlavors == effectiveFlavors &&
          other.executionToken == executionToken &&
          other.fallback == fallback &&
          other.foodSafety == foodSafety &&
          other.ingredients == ingredients &&
          other.inputs == inputs &&
          other.notices == notices &&
          other.profileVersion == profileVersion &&
          other.recipeId == recipeId &&
          other.safety == safety &&
          other.snapshot == snapshot &&
          other.snapshotUnchanged == snapshotUnchanged &&
          other.steps == steps &&
          other.versionId == versionId &&
          other.view == view;

  @override
  int get hashCode =>
      adjustmentLimit.hashCode +
      authorizationVersion.hashCode +
      blocked.hashCode +
      cacheKey.hashCode +
      effectiveFlavors.hashCode +
      (executionToken == null ? 0 : executionToken.hashCode) +
      (fallback == null ? 0 : fallback.hashCode) +
      foodSafety.hashCode +
      ingredients.hashCode +
      inputs.hashCode +
      notices.hashCode +
      profileVersion.hashCode +
      recipeId.hashCode +
      safety.hashCode +
      snapshot.hashCode +
      snapshotUnchanged.hashCode +
      steps.hashCode +
      versionId.hashCode +
      view.hashCode;

  factory RecipePersonalizedOut.fromJson(Map<String, dynamic> json) =>
      _$RecipePersonalizedOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipePersonalizedOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipePersonalizedOutViewEnum {
  @JsonValue(r'personalized')
  personalized(r'personalized'),
  @JsonValue(r'original')
  original(r'original');

  const RecipePersonalizedOutViewEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
