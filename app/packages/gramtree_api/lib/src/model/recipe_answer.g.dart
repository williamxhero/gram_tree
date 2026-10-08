// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_answer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeAnswerCWProxy {
  RecipeAnswer basis(RecipeAnswerBasisEnum basis);

  RecipeAnswer basisText(String? basisText);

  RecipeAnswer capability(RecipeAnswerCapabilityEnum capability);

  RecipeAnswer conclusion(String conclusion);

  RecipeAnswer details(String? details);

  RecipeAnswer error(String? error);

  RecipeAnswer explanation(String? explanation);

  RecipeAnswer numericWarnings(List<String>? numericWarnings);

  RecipeAnswer question(String question);

  RecipeAnswer recipeId(String recipeId);

  RecipeAnswer safety(RecipeSafetyResult safety);

  RecipeAnswer source_(RecipeAnswerSource_Enum source_);

  RecipeAnswer state(RecipeAnswerStateEnum state);

  RecipeAnswer status(AIStatus status);

  RecipeAnswer versionId(String versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeAnswer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeAnswer(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeAnswer call({
    RecipeAnswerBasisEnum basis,
    String? basisText,
    RecipeAnswerCapabilityEnum capability,
    String conclusion,
    String? details,
    String? error,
    String? explanation,
    List<String>? numericWarnings,
    String question,
    String recipeId,
    RecipeSafetyResult safety,
    RecipeAnswerSource_Enum source_,
    RecipeAnswerStateEnum state,
    AIStatus status,
    String versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeAnswer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeAnswer.copyWith.fieldName(...)`
class _$RecipeAnswerCWProxyImpl implements _$RecipeAnswerCWProxy {
  const _$RecipeAnswerCWProxyImpl(this._value);

  final RecipeAnswer _value;

  @override
  RecipeAnswer basis(RecipeAnswerBasisEnum basis) => this(basis: basis);

  @override
  RecipeAnswer basisText(String? basisText) => this(basisText: basisText);

  @override
  RecipeAnswer capability(RecipeAnswerCapabilityEnum capability) =>
      this(capability: capability);

  @override
  RecipeAnswer conclusion(String conclusion) => this(conclusion: conclusion);

  @override
  RecipeAnswer details(String? details) => this(details: details);

  @override
  RecipeAnswer error(String? error) => this(error: error);

  @override
  RecipeAnswer explanation(String? explanation) =>
      this(explanation: explanation);

  @override
  RecipeAnswer numericWarnings(List<String>? numericWarnings) =>
      this(numericWarnings: numericWarnings);

  @override
  RecipeAnswer question(String question) => this(question: question);

  @override
  RecipeAnswer recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  RecipeAnswer safety(RecipeSafetyResult safety) => this(safety: safety);

  @override
  RecipeAnswer source_(RecipeAnswerSource_Enum source_) =>
      this(source_: source_);

  @override
  RecipeAnswer state(RecipeAnswerStateEnum state) => this(state: state);

  @override
  RecipeAnswer status(AIStatus status) => this(status: status);

  @override
  RecipeAnswer versionId(String versionId) => this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeAnswer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeAnswer(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeAnswer call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? basisText = const $CopyWithPlaceholder(),
    Object? capability = const $CopyWithPlaceholder(),
    Object? conclusion = const $CopyWithPlaceholder(),
    Object? details = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? explanation = const $CopyWithPlaceholder(),
    Object? numericWarnings = const $CopyWithPlaceholder(),
    Object? question = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? safety = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return RecipeAnswer(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as RecipeAnswerBasisEnum,
      basisText: basisText == const $CopyWithPlaceholder()
          ? _value.basisText
          // ignore: cast_nullable_to_non_nullable
          : basisText as String?,
      capability: capability == const $CopyWithPlaceholder()
          ? _value.capability
          // ignore: cast_nullable_to_non_nullable
          : capability as RecipeAnswerCapabilityEnum,
      conclusion: conclusion == const $CopyWithPlaceholder()
          ? _value.conclusion
          // ignore: cast_nullable_to_non_nullable
          : conclusion as String,
      details: details == const $CopyWithPlaceholder()
          ? _value.details
          // ignore: cast_nullable_to_non_nullable
          : details as String?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      explanation: explanation == const $CopyWithPlaceholder()
          ? _value.explanation
          // ignore: cast_nullable_to_non_nullable
          : explanation as String?,
      numericWarnings: numericWarnings == const $CopyWithPlaceholder()
          ? _value.numericWarnings
          // ignore: cast_nullable_to_non_nullable
          : numericWarnings as List<String>?,
      question: question == const $CopyWithPlaceholder()
          ? _value.question
          // ignore: cast_nullable_to_non_nullable
          : question as String,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      safety: safety == const $CopyWithPlaceholder()
          ? _value.safety
          // ignore: cast_nullable_to_non_nullable
          : safety as RecipeSafetyResult,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as RecipeAnswerSource_Enum,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as RecipeAnswerStateEnum,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AIStatus,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
    );
  }
}

extension $RecipeAnswerCopyWith on RecipeAnswer {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeAnswer.copyWith(...)` or like so:`instanceOfRecipeAnswer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeAnswerCWProxy get copyWith => _$RecipeAnswerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeAnswer _$RecipeAnswerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeAnswer',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'basis',
            'capability',
            'conclusion',
            'question',
            'recipe_id',
            'safety',
            'source',
            'state',
            'status',
            'version_id',
          ],
        );
        final val = RecipeAnswer(
          basis: $checkedConvert(
            'basis',
            (v) => $enumDecode(_$RecipeAnswerBasisEnumEnumMap, v),
          ),
          basisText: $checkedConvert(
            'basis_text',
            (v) => v as String? ?? '这是一般经验，还没有足够记录验证',
          ),
          capability: $checkedConvert(
            'capability',
            (v) => $enumDecode(_$RecipeAnswerCapabilityEnumEnumMap, v),
          ),
          conclusion: $checkedConvert('conclusion', (v) => v as String),
          details: $checkedConvert('details', (v) => v as String? ?? ''),
          error: $checkedConvert('error', (v) => v as String?),
          explanation: $checkedConvert(
            'explanation',
            (v) => v as String? ?? '',
          ),
          numericWarnings: $checkedConvert(
            'numeric_warnings',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          question: $checkedConvert('question', (v) => v as String),
          recipeId: $checkedConvert('recipe_id', (v) => v as String),
          safety: $checkedConvert(
            'safety',
            (v) => RecipeSafetyResult.fromJson(v as Map<String, dynamic>),
          ),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$RecipeAnswerSource_EnumEnumMap, v),
          ),
          state: $checkedConvert(
            'state',
            (v) => $enumDecode(_$RecipeAnswerStateEnumEnumMap, v),
          ),
          status: $checkedConvert(
            'status',
            (v) => AIStatus.fromJson(v as Map<String, dynamic>),
          ),
          versionId: $checkedConvert('version_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'basisText': 'basis_text',
        'numericWarnings': 'numeric_warnings',
        'recipeId': 'recipe_id',
        'source_': 'source',
        'versionId': 'version_id',
      },
    );

Map<String, dynamic> _$RecipeAnswerToJson(RecipeAnswer instance) =>
    <String, dynamic>{
      'basis': _$RecipeAnswerBasisEnumEnumMap[instance.basis]!,
      'basis_text': ?instance.basisText,
      'capability': _$RecipeAnswerCapabilityEnumEnumMap[instance.capability]!,
      'conclusion': instance.conclusion,
      'details': ?instance.details,
      'error': ?instance.error,
      'explanation': ?instance.explanation,
      'numeric_warnings': ?instance.numericWarnings,
      'question': instance.question,
      'recipe_id': instance.recipeId,
      'safety': instance.safety.toJson(),
      'source': _$RecipeAnswerSource_EnumEnumMap[instance.source_]!,
      'state': _$RecipeAnswerStateEnumEnumMap[instance.state]!,
      'status': instance.status.toJson(),
      'version_id': instance.versionId,
    };

const _$RecipeAnswerBasisEnumEnumMap = {
  RecipeAnswerBasisEnum.generalExperience: 'general_experience',
};

const _$RecipeAnswerCapabilityEnumEnumMap = {
  RecipeAnswerCapabilityEnum.explain: 'explain',
};

const _$RecipeAnswerSource_EnumEnumMap = {
  RecipeAnswerSource_Enum.aiEstimated: 'ai_estimated',
};

const _$RecipeAnswerStateEnumEnumMap = {
  RecipeAnswerStateEnum.answered: 'answered',
  RecipeAnswerStateEnum.uncertain: 'uncertain',
  RecipeAnswerStateEnum.cannotAnswer: 'cannot_answer',
  RecipeAnswerStateEnum.unavailable: 'unavailable',
};
