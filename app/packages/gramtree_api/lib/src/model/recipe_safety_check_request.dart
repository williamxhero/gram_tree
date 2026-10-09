//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_safety_check_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSafetyCheckRequest {
  /// Returns a new [RecipeSafetyCheckRequest] instance.
  RecipeSafetyCheckRequest({
    this.baseVersionId,

    this.changeNote = '',

    this.description,

    this.dishAliases,

    this.dishName = '',

    this.recipeId,

    required this.snapshot,
  });

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(
    defaultValue: '',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'dish_aliases', required: false, includeIfNull: false)
  final List<String>? dishAliases;

  @JsonKey(
    defaultValue: '',
    name: r'dish_name',
    required: false,
    includeIfNull: false,
  )
  final String? dishName;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSafetyCheckRequest &&
          other.baseVersionId == baseVersionId &&
          other.changeNote == changeNote &&
          other.description == description &&
          other.dishAliases == dishAliases &&
          other.dishName == dishName &&
          other.recipeId == recipeId &&
          other.snapshot == snapshot;

  @override
  int get hashCode =>
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      changeNote.hashCode +
      (description == null ? 0 : description.hashCode) +
      dishAliases.hashCode +
      dishName.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode) +
      snapshot.hashCode;

  factory RecipeSafetyCheckRequest.fromJson(Map<String, dynamic> json) =>
      _$RecipeSafetyCheckRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSafetyCheckRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
