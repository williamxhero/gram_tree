//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_author.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeAuthor {
  /// Returns a new [RecipeAuthor] instance.
  RecipeAuthor({required this.id, required this.nickname});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'nickname', required: true, includeIfNull: false)
  final String nickname;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeAuthor && other.id == id && other.nickname == nickname;

  @override
  int get hashCode => id.hashCode + nickname.hashCode;

  factory RecipeAuthor.fromJson(Map<String, dynamic> json) =>
      _$RecipeAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
