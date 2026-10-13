//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_question.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeQuestion {
  /// Returns a new [RecipeQuestion] instance.
  RecipeQuestion({required this.question});

  @JsonKey(name: r'question', required: true, includeIfNull: false)
  final String question;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeQuestion && other.question == question;

  @override
  int get hashCode => question.hashCode;

  factory RecipeQuestion.fromJson(Map<String, dynamic> json) =>
      _$RecipeQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeQuestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
