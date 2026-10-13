//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/serving_conversion.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_serving_conversion_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeServingConversionOut {
  /// Returns a new [RecipeServingConversionOut] instance.
  RecipeServingConversionOut({
    required this.conversion,

    required this.recipeId,

    required this.versionId,
  });

  @JsonKey(name: r'conversion', required: true, includeIfNull: false)
  final ServingConversion conversion;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeServingConversionOut &&
          other.conversion == conversion &&
          other.recipeId == recipeId &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      conversion.hashCode + recipeId.hashCode + versionId.hashCode;

  factory RecipeServingConversionOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeServingConversionOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeServingConversionOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
