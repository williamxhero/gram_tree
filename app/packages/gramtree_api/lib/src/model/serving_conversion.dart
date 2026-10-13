//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/serving_conversion_step.dart';
import 'package:gramtree_api/src/model/serving_conversion_ingredient.dart';
import 'package:gramtree_api/src/model/serving_conversion_warning.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'serving_conversion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServingConversion {
  /// Returns a new [ServingConversion] instance.
  ServingConversion({
    required this.activeTimeSeconds,

    required this.ingredients,

    required this.maxServings,

    required this.minServings,

    required this.originalServings,

    required this.steps,

    required this.targetServings,

    required this.totalTimeSeconds,

    required this.warnings,
  });

  @JsonKey(name: r'active_time_seconds', required: true, includeIfNull: false)
  final int activeTimeSeconds;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<ServingConversionIngredient> ingredients;

  @JsonKey(name: r'max_servings', required: true, includeIfNull: false)
  final int maxServings;

  @JsonKey(name: r'min_servings', required: true, includeIfNull: false)
  final int minServings;

  @JsonKey(name: r'original_servings', required: true, includeIfNull: false)
  final int originalServings;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<ServingConversionStep> steps;

  @JsonKey(name: r'target_servings', required: true, includeIfNull: false)
  final int targetServings;

  @JsonKey(name: r'total_time_seconds', required: true, includeIfNull: false)
  final int totalTimeSeconds;

  @JsonKey(name: r'warnings', required: true, includeIfNull: false)
  final List<ServingConversionWarning> warnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServingConversion &&
          other.activeTimeSeconds == activeTimeSeconds &&
          other.ingredients == ingredients &&
          other.maxServings == maxServings &&
          other.minServings == minServings &&
          other.originalServings == originalServings &&
          other.steps == steps &&
          other.targetServings == targetServings &&
          other.totalTimeSeconds == totalTimeSeconds &&
          other.warnings == warnings;

  @override
  int get hashCode =>
      activeTimeSeconds.hashCode +
      ingredients.hashCode +
      maxServings.hashCode +
      minServings.hashCode +
      originalServings.hashCode +
      steps.hashCode +
      targetServings.hashCode +
      totalTimeSeconds.hashCode +
      warnings.hashCode;

  factory ServingConversion.fromJson(Map<String, dynamic> json) =>
      _$ServingConversionFromJson(json);

  Map<String, dynamic> toJson() => _$ServingConversionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
