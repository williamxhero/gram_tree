//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comparison_version.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComparisonVersion {
  /// Returns a new [ComparisonVersion] instance.
  ComparisonVersion({
    required this.author,

    required this.dishName,

    required this.recipeId,

    required this.servings,

    required this.versionId,

    required this.versionNumber,
  });

  @JsonKey(name: r'author', required: true, includeIfNull: false)
  final String author;

  @JsonKey(name: r'dish_name', required: true, includeIfNull: false)
  final String dishName;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @JsonKey(name: r'version_number', required: true, includeIfNull: false)
  final int versionNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonVersion &&
          other.author == author &&
          other.dishName == dishName &&
          other.recipeId == recipeId &&
          other.servings == servings &&
          other.versionId == versionId &&
          other.versionNumber == versionNumber;

  @override
  int get hashCode =>
      author.hashCode +
      dishName.hashCode +
      recipeId.hashCode +
      servings.hashCode +
      versionId.hashCode +
      versionNumber.hashCode;

  factory ComparisonVersion.fromJson(Map<String, dynamic> json) =>
      _$ComparisonVersionFromJson(json);

  Map<String, dynamic> toJson() => _$ComparisonVersionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
