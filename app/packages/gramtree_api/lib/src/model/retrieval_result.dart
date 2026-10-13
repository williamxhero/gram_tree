//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ai_status.dart';
import 'package:gramtree_api/src/model/recipe_intent.dart';
import 'package:gramtree_api/src/model/question.dart';
import 'package:gramtree_api/src/model/similar_recipe.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'retrieval_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RetrievalResult {
  /// Returns a new [RetrievalResult] instance.
  RetrievalResult({
    required this.intent,

    this.localFallback = false,

    required this.questions,

    required this.recipes,

    required this.requestId,

    required this.status,

    required this.text,
  });

  @JsonKey(name: r'intent', required: true, includeIfNull: false)
  final RecipeIntent intent;

  @JsonKey(
    defaultValue: false,
    name: r'local_fallback',
    required: false,
    includeIfNull: false,
  )
  final bool? localFallback;

  @JsonKey(name: r'questions', required: true, includeIfNull: false)
  final List<Question> questions;

  @JsonKey(name: r'recipes', required: true, includeIfNull: false)
  final List<SimilarRecipe> recipes;

  @JsonKey(name: r'request_id', required: true, includeIfNull: false)
  final String requestId;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AIStatus status;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetrievalResult &&
          other.intent == intent &&
          other.localFallback == localFallback &&
          other.questions == questions &&
          other.recipes == recipes &&
          other.requestId == requestId &&
          other.status == status &&
          other.text == text;

  @override
  int get hashCode =>
      intent.hashCode +
      localFallback.hashCode +
      questions.hashCode +
      recipes.hashCode +
      requestId.hashCode +
      status.hashCode +
      text.hashCode;

  factory RetrievalResult.fromJson(Map<String, dynamic> json) =>
      _$RetrievalResultFromJson(json);

  Map<String, dynamic> toJson() => _$RetrievalResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
