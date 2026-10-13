//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_personal_safety_alert.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipePersonalSafetyAlert {
  /// Returns a new [RecipePersonalSafetyAlert] instance.
  RecipePersonalSafetyAlert({
    required this.ingredient,

    required this.kind,

    required this.person,

    this.replacement = false,

    required this.target,
  });

  @JsonKey(name: r'ingredient', required: true, includeIfNull: false)
  final String ingredient;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final RecipePersonalSafetyAlertKindEnum kind;

  @JsonKey(name: r'person', required: true, includeIfNull: false)
  final String person;

  @JsonKey(
    defaultValue: false,
    name: r'replacement',
    required: false,
    includeIfNull: false,
  )
  final bool? replacement;

  @JsonKey(name: r'target', required: true, includeIfNull: false)
  final String target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipePersonalSafetyAlert &&
          other.ingredient == ingredient &&
          other.kind == kind &&
          other.person == person &&
          other.replacement == replacement &&
          other.target == target;

  @override
  int get hashCode =>
      ingredient.hashCode +
      kind.hashCode +
      person.hashCode +
      replacement.hashCode +
      target.hashCode;

  factory RecipePersonalSafetyAlert.fromJson(Map<String, dynamic> json) =>
      _$RecipePersonalSafetyAlertFromJson(json);

  Map<String, dynamic> toJson() => _$RecipePersonalSafetyAlertToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipePersonalSafetyAlertKindEnum {
  @JsonValue(r'allergy')
  allergy(r'allergy'),
  @JsonValue(r'avoidance')
  avoidance(r'avoidance');

  const RecipePersonalSafetyAlertKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
