//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_draft_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementDraftOut {
  /// Returns a new [ImprovementDraftOut] instance.
  ImprovementDraftOut({
    required this.aiAssisted,

    required this.dishName,

    required this.id,

    required this.snapshot,

    required this.sourceRecipeId,

    required this.sourceVersionId,
  });

  @JsonKey(name: r'ai_assisted', required: true, includeIfNull: false)
  final bool aiAssisted;

  @JsonKey(name: r'dish_name', required: true, includeIfNull: false)
  final String dishName;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @JsonKey(name: r'source_recipe_id', required: true, includeIfNull: false)
  final String sourceRecipeId;

  @JsonKey(name: r'source_version_id', required: true, includeIfNull: false)
  final String sourceVersionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementDraftOut &&
          other.aiAssisted == aiAssisted &&
          other.dishName == dishName &&
          other.id == id &&
          other.snapshot == snapshot &&
          other.sourceRecipeId == sourceRecipeId &&
          other.sourceVersionId == sourceVersionId;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      dishName.hashCode +
      id.hashCode +
      snapshot.hashCode +
      sourceRecipeId.hashCode +
      sourceVersionId.hashCode;

  factory ImprovementDraftOut.fromJson(Map<String, dynamic> json) =>
      _$ImprovementDraftOutFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementDraftOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
