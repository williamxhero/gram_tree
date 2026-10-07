//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_create.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated_draft.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GeneratedDraft {
  /// Returns a new [GeneratedDraft] instance.
  GeneratedDraft({
    required this.cuisine,

    required this.rationale,

    required this.recipe,
  });

  @JsonKey(name: r'cuisine', required: true, includeIfNull: false)
  final String cuisine;

  @JsonKey(name: r'rationale', required: true, includeIfNull: false)
  final String rationale;

  @JsonKey(name: r'recipe', required: true, includeIfNull: false)
  final RecipeCreate recipe;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedDraft &&
          other.cuisine == cuisine &&
          other.rationale == rationale &&
          other.recipe == recipe;

  @override
  int get hashCode => cuisine.hashCode + rationale.hashCode + recipe.hashCode;

  factory GeneratedDraft.fromJson(Map<String, dynamic> json) =>
      _$GeneratedDraftFromJson(json);

  Map<String, dynamic> toJson() => _$GeneratedDraftToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
