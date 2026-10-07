//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_ingredient.dart';
import 'package:gramtree_api/src/model/recipe_step.dart';
import 'package:gramtree_api/src/model/mold_spec.dart';
import 'package:gramtree_api/src/model/value_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_snapshot.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSnapshot {
  /// Returns a new [RecipeSnapshot] instance.
  RecipeSnapshot({
    this.activeTimeSeconds = 0,

    this.baseMold,

    this.cuisine,

    this.description,

    this.designRationale,

    this.difficulty,

    this.dishType,

    required this.formatVersion,

    this.ingredients,

    required this.servings,

    this.servingsSource,

    this.steps,

    this.tags,

    this.textSource,

    this.totalTimeSeconds = 0,
  });

  // minimum: 0
  // maximum: 604800
  @JsonKey(
    defaultValue: 0,
    name: r'active_time_seconds',
    required: false,
    includeIfNull: false,
  )
  final int? activeTimeSeconds;

  /// 烘焙菜谱的基准模具
  @JsonKey(name: r'base_mold', required: false, includeIfNull: false)
  final MoldSpec? baseMold;

  @JsonKey(name: r'cuisine', required: false, includeIfNull: false)
  final String? cuisine;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'design_rationale', required: false, includeIfNull: false)
  final String? designRationale;

  @JsonKey(name: r'difficulty', required: false, includeIfNull: false)
  final String? difficulty;

  @JsonKey(name: r'dish_type', required: false, includeIfNull: false)
  final String? dishType;

  /// 快照格式版本
  @JsonKey(name: r'format_version', required: true, includeIfNull: false)
  final RecipeSnapshotFormatVersionEnum formatVersion;

  @JsonKey(name: r'ingredients', required: false, includeIfNull: false)
  final List<RecipeIngredient>? ingredients;

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'servings_source', required: false, includeIfNull: false)
  final ValueSource? servingsSource;

  @JsonKey(name: r'steps', required: false, includeIfNull: false)
  final List<RecipeStep>? steps;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @JsonKey(name: r'text_source', required: false, includeIfNull: false)
  final ValueSource? textSource;

  // minimum: 0
  // maximum: 604800
  @JsonKey(
    defaultValue: 0,
    name: r'total_time_seconds',
    required: false,
    includeIfNull: false,
  )
  final int? totalTimeSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSnapshot &&
          other.activeTimeSeconds == activeTimeSeconds &&
          other.baseMold == baseMold &&
          other.cuisine == cuisine &&
          other.description == description &&
          other.designRationale == designRationale &&
          other.difficulty == difficulty &&
          other.dishType == dishType &&
          other.formatVersion == formatVersion &&
          other.ingredients == ingredients &&
          other.servings == servings &&
          other.servingsSource == servingsSource &&
          other.steps == steps &&
          other.tags == tags &&
          other.textSource == textSource &&
          other.totalTimeSeconds == totalTimeSeconds;

  @override
  int get hashCode =>
      activeTimeSeconds.hashCode +
      baseMold.hashCode +
      (cuisine == null ? 0 : cuisine.hashCode) +
      (description == null ? 0 : description.hashCode) +
      (designRationale == null ? 0 : designRationale.hashCode) +
      (difficulty == null ? 0 : difficulty.hashCode) +
      (dishType == null ? 0 : dishType.hashCode) +
      formatVersion.hashCode +
      ingredients.hashCode +
      servings.hashCode +
      servingsSource.hashCode +
      steps.hashCode +
      tags.hashCode +
      textSource.hashCode +
      totalTimeSeconds.hashCode;

  factory RecipeSnapshot.fromJson(Map<String, dynamic> json) =>
      _$RecipeSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSnapshotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// 快照格式版本
enum RecipeSnapshotFormatVersionEnum {
  /// 快照格式版本
  @JsonValue(1)
  number1('1');

  const RecipeSnapshotFormatVersionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
