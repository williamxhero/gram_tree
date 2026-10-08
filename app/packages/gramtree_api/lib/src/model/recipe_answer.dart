//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ai_status.dart';
import 'package:gramtree_api/src/model/recipe_safety_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_answer.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeAnswer {
  /// Returns a new [RecipeAnswer] instance.
  RecipeAnswer({
    required this.basis,

    this.basisText = '这是一般经验，还没有足够记录验证',

    required this.capability,

    required this.conclusion,

    this.details = '',

    this.error,

    this.explanation = '',

    this.numericWarnings,

    required this.question,

    required this.recipeId,

    required this.safety,

    required this.source_,

    required this.state,

    required this.status,

    required this.versionId,
  });

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final RecipeAnswerBasisEnum basis;

  @JsonKey(
    defaultValue: '这是一般经验，还没有足够记录验证',
    name: r'basis_text',
    required: false,
    includeIfNull: false,
  )
  final String? basisText;

  @JsonKey(name: r'capability', required: true, includeIfNull: false)
  final RecipeAnswerCapabilityEnum capability;

  @JsonKey(name: r'conclusion', required: true, includeIfNull: false)
  final String conclusion;

  @JsonKey(
    defaultValue: '',
    name: r'details',
    required: false,
    includeIfNull: false,
  )
  final String? details;

  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @JsonKey(
    defaultValue: '',
    name: r'explanation',
    required: false,
    includeIfNull: false,
  )
  final String? explanation;

  @JsonKey(name: r'numeric_warnings', required: false, includeIfNull: false)
  final List<String>? numericWarnings;

  @JsonKey(name: r'question', required: true, includeIfNull: false)
  final String question;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'safety', required: true, includeIfNull: false)
  final RecipeSafetyResult safety;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final RecipeAnswerSource_Enum source_;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final RecipeAnswerStateEnum state;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AIStatus status;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeAnswer &&
          other.basis == basis &&
          other.basisText == basisText &&
          other.capability == capability &&
          other.conclusion == conclusion &&
          other.details == details &&
          other.error == error &&
          other.explanation == explanation &&
          other.numericWarnings == numericWarnings &&
          other.question == question &&
          other.recipeId == recipeId &&
          other.safety == safety &&
          other.source_ == source_ &&
          other.state == state &&
          other.status == status &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      basis.hashCode +
      basisText.hashCode +
      capability.hashCode +
      conclusion.hashCode +
      details.hashCode +
      (error == null ? 0 : error.hashCode) +
      explanation.hashCode +
      numericWarnings.hashCode +
      question.hashCode +
      recipeId.hashCode +
      safety.hashCode +
      source_.hashCode +
      state.hashCode +
      status.hashCode +
      versionId.hashCode;

  factory RecipeAnswer.fromJson(Map<String, dynamic> json) =>
      _$RecipeAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeAnswerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeAnswerBasisEnum {
  @JsonValue(r'general_experience')
  generalExperience(r'general_experience');

  const RecipeAnswerBasisEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecipeAnswerCapabilityEnum {
  @JsonValue(r'explain')
  explain(r'explain');

  const RecipeAnswerCapabilityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecipeAnswerSource_Enum {
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated');

  const RecipeAnswerSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecipeAnswerStateEnum {
  @JsonValue(r'answered')
  answered(r'answered'),
  @JsonValue(r'uncertain')
  uncertain(r'uncertain'),
  @JsonValue(r'cannot_answer')
  cannotAnswer(r'cannot_answer'),
  @JsonValue(r'unavailable')
  unavailable(r'unavailable');

  const RecipeAnswerStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
