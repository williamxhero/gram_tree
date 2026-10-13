//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:gramtree_api/src/model/dish_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeCreate {
  /// Returns a new [RecipeCreate] instance.
  RecipeCreate({
    this.aiAssisted = false,

    this.changeNote = '',

    this.dish,

    this.dishAliases,

    this.dishName,

    this.explanationFingerprint,

    this.imageIds,

    required this.snapshot,
  });

  @JsonKey(
    defaultValue: false,
    name: r'ai_assisted',
    required: false,
    includeIfNull: false,
  )
  final bool? aiAssisted;

  @JsonKey(
    defaultValue: '',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  @JsonKey(name: r'dish', required: false, includeIfNull: false)
  final DishInput? dish;

  @JsonKey(name: r'dish_aliases', required: false, includeIfNull: false)
  final List<String>? dishAliases;

  @JsonKey(name: r'dish_name', required: false, includeIfNull: false)
  final String? dishName;

  @JsonKey(
    name: r'explanation_fingerprint',
    required: false,
    includeIfNull: false,
  )
  final String? explanationFingerprint;

  @JsonKey(name: r'image_ids', required: false, includeIfNull: false)
  final List<String>? imageIds;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeCreate &&
          other.aiAssisted == aiAssisted &&
          other.changeNote == changeNote &&
          other.dish == dish &&
          other.dishAliases == dishAliases &&
          other.dishName == dishName &&
          other.explanationFingerprint == explanationFingerprint &&
          other.imageIds == imageIds &&
          other.snapshot == snapshot;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      changeNote.hashCode +
      dish.hashCode +
      dishAliases.hashCode +
      (dishName == null ? 0 : dishName.hashCode) +
      (explanationFingerprint == null ? 0 : explanationFingerprint.hashCode) +
      imageIds.hashCode +
      snapshot.hashCode;

  factory RecipeCreate.fromJson(Map<String, dynamic> json) =>
      _$RecipeCreateFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
