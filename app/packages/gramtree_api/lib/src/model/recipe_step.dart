//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/value_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_step.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeStep {
  /// Returns a new [RecipeStep] instance.
  RecipeStep({
    required this.action,

    required this.cookware,

    this.dependsOn,

    required this.doneness,

    this.durationSeconds = 0,

    this.durationSource,

    required this.heat,

    this.heatSource,

    required this.id,

    this.ingredientIds,

    required this.instruction,

    required this.notes,

    required this.temperatureCelsius,

    this.temperatureSource,

    this.unattended = false,

    required this.why,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'cookware', required: true, includeIfNull: false)
  final String cookware;

  @JsonKey(name: r'depends_on', required: false, includeIfNull: false)
  final List<String>? dependsOn;

  @JsonKey(name: r'doneness', required: true, includeIfNull: false)
  final String doneness;

  // minimum: 0
  // maximum: 86400
  @JsonKey(
    defaultValue: 0,
    name: r'duration_seconds',
    required: false,
    includeIfNull: false,
  )
  final int? durationSeconds;

  @JsonKey(name: r'duration_source', required: false, includeIfNull: false)
  final ValueSource? durationSource;

  @JsonKey(name: r'heat', required: true, includeIfNull: false)
  final String heat;

  @JsonKey(name: r'heat_source', required: false, includeIfNull: false)
  final ValueSource? heatSource;

  /// 步骤 ID
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'ingredient_ids', required: false, includeIfNull: false)
  final List<String>? ingredientIds;

  @JsonKey(name: r'instruction', required: true, includeIfNull: false)
  final String instruction;

  @JsonKey(name: r'notes', required: true, includeIfNull: false)
  final String notes;

  @JsonKey(name: r'temperature_celsius', required: true, includeIfNull: false)
  final num temperatureCelsius;

  @JsonKey(name: r'temperature_source', required: false, includeIfNull: false)
  final ValueSource? temperatureSource;

  @JsonKey(
    defaultValue: false,
    name: r'unattended',
    required: false,
    includeIfNull: false,
  )
  final bool? unattended;

  @JsonKey(name: r'why', required: true, includeIfNull: false)
  final String why;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeStep &&
          other.action == action &&
          other.cookware == cookware &&
          other.dependsOn == dependsOn &&
          other.doneness == doneness &&
          other.durationSeconds == durationSeconds &&
          other.durationSource == durationSource &&
          other.heat == heat &&
          other.heatSource == heatSource &&
          other.id == id &&
          other.ingredientIds == ingredientIds &&
          other.instruction == instruction &&
          other.notes == notes &&
          other.temperatureCelsius == temperatureCelsius &&
          other.temperatureSource == temperatureSource &&
          other.unattended == unattended &&
          other.why == why;

  @override
  int get hashCode =>
      action.hashCode +
      cookware.hashCode +
      dependsOn.hashCode +
      doneness.hashCode +
      durationSeconds.hashCode +
      durationSource.hashCode +
      heat.hashCode +
      heatSource.hashCode +
      id.hashCode +
      ingredientIds.hashCode +
      instruction.hashCode +
      notes.hashCode +
      temperatureCelsius.hashCode +
      temperatureSource.hashCode +
      unattended.hashCode +
      why.hashCode;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeStepToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
