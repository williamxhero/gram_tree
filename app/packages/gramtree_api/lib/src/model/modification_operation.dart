//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_operation.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationOperation {
  /// Returns a new [ModificationOperation] instance.
  ModificationOperation({
    required this.after,

    required this.before,

    required this.confidence,

    this.dependsOn,

    required this.field,

    this.id,

    required this.intent,

    required this.operationId,

    required this.reason,

    required this.risk,

    required this.scope,

    required this.type,
  });

  @JsonKey(name: r'after', required: true, includeIfNull: true)
  final Object? after;

  @JsonKey(name: r'before', required: true, includeIfNull: true)
  final Object? before;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final num confidence;

  @JsonKey(name: r'depends_on', required: false, includeIfNull: false)
  final List<String>? dependsOn;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'id', required: false, includeIfNull: false)
  final String? id;

  @JsonKey(name: r'intent', required: true, includeIfNull: false)
  final String intent;

  @JsonKey(name: r'operation_id', required: true, includeIfNull: false)
  final String operationId;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'risk', required: true, includeIfNull: false)
  final String risk;

  @JsonKey(name: r'scope', required: true, includeIfNull: false)
  final List<String> scope;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ModificationOperationTypeEnum type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationOperation &&
          other.after == after &&
          other.before == before &&
          other.confidence == confidence &&
          other.dependsOn == dependsOn &&
          other.field == field &&
          other.id == id &&
          other.intent == intent &&
          other.operationId == operationId &&
          other.reason == reason &&
          other.risk == risk &&
          other.scope == scope &&
          other.type == type;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      (before == null ? 0 : before.hashCode) +
      confidence.hashCode +
      dependsOn.hashCode +
      field.hashCode +
      (id == null ? 0 : id.hashCode) +
      intent.hashCode +
      operationId.hashCode +
      reason.hashCode +
      risk.hashCode +
      scope.hashCode +
      type.hashCode;

  factory ModificationOperation.fromJson(Map<String, dynamic> json) =>
      _$ModificationOperationFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationOperationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ModificationOperationTypeEnum {
  @JsonValue(r'change_step_field')
  changeStepField(r'change_step_field'),
  @JsonValue(r'change_step_duration')
  changeStepDuration(r'change_step_duration'),
  @JsonValue(r'change_step_heat')
  changeStepHeat(r'change_step_heat'),
  @JsonValue(r'change_preparation')
  changePreparation(r'change_preparation'),
  @JsonValue(r'change_display_name')
  changeDisplayName(r'change_display_name'),
  @JsonValue(r'change_recipe_info')
  changeRecipeInfo(r'change_recipe_info'),
  @JsonValue(r'change_step_ingredients')
  changeStepIngredients(r'change_step_ingredients'),
  @JsonValue(r'change_step_dependencies')
  changeStepDependencies(r'change_step_dependencies'),
  @JsonValue(r'replace_ingredient')
  replaceIngredient(r'replace_ingredient'),
  @JsonValue(r'change_quantity')
  changeQuantity(r'change_quantity'),
  @JsonValue(r'change_group_or_optional')
  changeGroupOrOptional(r'change_group_or_optional'),
  @JsonValue(r'change_functional')
  changeFunctional(r'change_functional'),
  @JsonValue(r'change_scaling')
  changeScaling(r'change_scaling'),
  @JsonValue(r'change_replacement')
  changeReplacement(r'change_replacement'),
  @JsonValue(r'add_ingredient')
  addIngredient(r'add_ingredient'),
  @JsonValue(r'remove_ingredient')
  removeIngredient(r'remove_ingredient'),
  @JsonValue(r'add_step')
  addStep(r'add_step'),
  @JsonValue(r'remove_step')
  removeStep(r'remove_step'),
  @JsonValue(r'reorder_ingredients')
  reorderIngredients(r'reorder_ingredients'),
  @JsonValue(r'reorder_steps')
  reorderSteps(r'reorder_steps');

  const ModificationOperationTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
