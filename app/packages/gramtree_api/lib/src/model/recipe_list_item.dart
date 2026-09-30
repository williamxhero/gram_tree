//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/dish_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_list_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeListItem {
  /// Returns a new [RecipeListItem] instance.
  RecipeListItem({
    required this.activeTimeSeconds,

    this.difficulty,

    required this.dish,

    required this.id,

    required this.servings,

    required this.totalTimeSeconds,

    required this.updatedAt,

    required this.versionNumber,

    required this.visibility,
  });

  @JsonKey(name: r'active_time_seconds', required: true, includeIfNull: false)
  final int activeTimeSeconds;

  @JsonKey(name: r'difficulty', required: false, includeIfNull: false)
  final String? difficulty;

  @JsonKey(name: r'dish', required: true, includeIfNull: false)
  final DishOut dish;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'total_time_seconds', required: true, includeIfNull: false)
  final int totalTimeSeconds;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final String updatedAt;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @JsonKey(name: r'visibility', required: true, includeIfNull: false)
  final RecipeListItemVisibilityEnum visibility;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeListItem &&
          other.activeTimeSeconds == activeTimeSeconds &&
          other.difficulty == difficulty &&
          other.dish == dish &&
          other.id == id &&
          other.servings == servings &&
          other.totalTimeSeconds == totalTimeSeconds &&
          other.updatedAt == updatedAt &&
          other.versionNumber == versionNumber &&
          other.visibility == visibility;

  @override
  int get hashCode =>
      activeTimeSeconds.hashCode +
      difficulty.hashCode +
      dish.hashCode +
      id.hashCode +
      servings.hashCode +
      totalTimeSeconds.hashCode +
      updatedAt.hashCode +
      versionNumber.hashCode +
      visibility.hashCode;

  factory RecipeListItem.fromJson(Map<String, dynamic> json) =>
      _$RecipeListItemFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeListItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeListItemVisibilityEnum {
  @JsonValue(r'private')
  private(r'private');

  const RecipeListItemVisibilityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
