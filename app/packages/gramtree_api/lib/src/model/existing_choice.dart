//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'existing_choice.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExistingChoice {
  /// Returns a new [ExistingChoice] instance.
  ExistingChoice({required this.recipeId});

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExistingChoice && other.recipeId == recipeId;

  @override
  int get hashCode => recipeId.hashCode;

  factory ExistingChoice.fromJson(Map<String, dynamic> json) =>
      _$ExistingChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$ExistingChoiceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
