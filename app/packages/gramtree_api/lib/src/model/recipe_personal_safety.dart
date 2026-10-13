//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_personal_safety_alert.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_personal_safety.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipePersonalSafety {
  /// Returns a new [RecipePersonalSafety] instance.
  RecipePersonalSafety({
    this.alerts,

    this.incomplete = false,

    required this.status,

    this.unknownIngredients,
  });

  @JsonKey(name: r'alerts', required: false, includeIfNull: false)
  final List<RecipePersonalSafetyAlert>? alerts;

  @JsonKey(
    defaultValue: false,
    name: r'incomplete',
    required: false,
    includeIfNull: false,
  )
  final bool? incomplete;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecipePersonalSafetyStatusEnum status;

  @JsonKey(name: r'unknown_ingredients', required: false, includeIfNull: false)
  final List<String>? unknownIngredients;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipePersonalSafety &&
          other.alerts == alerts &&
          other.incomplete == incomplete &&
          other.status == status &&
          other.unknownIngredients == unknownIngredients;

  @override
  int get hashCode =>
      alerts.hashCode +
      incomplete.hashCode +
      status.hashCode +
      unknownIngredients.hashCode;

  factory RecipePersonalSafety.fromJson(Map<String, dynamic> json) =>
      _$RecipePersonalSafetyFromJson(json);

  Map<String, dynamic> toJson() => _$RecipePersonalSafetyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipePersonalSafetyStatusEnum {
  @JsonValue(r'available')
  available(r'available'),
  @JsonValue(r'not_authorized')
  notAuthorized(r'not_authorized');

  const RecipePersonalSafetyStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
