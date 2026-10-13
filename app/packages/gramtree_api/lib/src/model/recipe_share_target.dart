//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_share_target.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeShareTarget {
  /// Returns a new [RecipeShareTarget] instance.
  RecipeShareTarget({
    required this.appPath,

    required this.recipeId,

    required this.shareId,
  });

  @JsonKey(name: r'app_path', required: true, includeIfNull: false)
  final String appPath;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'share_id', required: true, includeIfNull: false)
  final String shareId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeShareTarget &&
          other.appPath == appPath &&
          other.recipeId == recipeId &&
          other.shareId == shareId;

  @override
  int get hashCode => appPath.hashCode + recipeId.hashCode + shareId.hashCode;

  factory RecipeShareTarget.fromJson(Map<String, dynamic> json) =>
      _$RecipeShareTargetFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeShareTargetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
