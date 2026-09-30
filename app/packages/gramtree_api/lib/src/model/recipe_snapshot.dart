//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_ingredient.dart';
import 'package:gramtree_api/src/model/recipe_step.dart';
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

    required this.difficulty,

    required this.dishType,

    required this.formatVersion,

    this.ingredients,

    required this.servings,

    this.steps,

    this.tags,

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

  @JsonKey(name: r'difficulty', required: true, includeIfNull: false)
  final String difficulty;

  @JsonKey(name: r'dish_type', required: true, includeIfNull: false)
  final String dishType;

  /// 快照格式版本
  @JsonKey(name: r'format_version', required: true, includeIfNull: false)
  final RecipeSnapshotFormatVersionEnum formatVersion;

  @JsonKey(name: r'ingredients', required: false, includeIfNull: false)
  final List<RecipeIngredient>? ingredients;

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'steps', required: false, includeIfNull: false)
  final List<RecipeStep>? steps;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

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
          other.difficulty == difficulty &&
          other.dishType == dishType &&
          other.formatVersion == formatVersion &&
          other.ingredients == ingredients &&
          other.servings == servings &&
          other.steps == steps &&
          other.tags == tags &&
          other.totalTimeSeconds == totalTimeSeconds;

  @override
  int get hashCode =>
      activeTimeSeconds.hashCode +
      difficulty.hashCode +
      dishType.hashCode +
      formatVersion.hashCode +
      ingredients.hashCode +
      servings.hashCode +
      steps.hashCode +
      tags.hashCode +
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
