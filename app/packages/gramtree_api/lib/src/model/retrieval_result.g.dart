// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retrieval_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RetrievalResultCWProxy {
  RetrievalResult intent(RecipeIntent intent);

  RetrievalResult localFallback(bool? localFallback);

  RetrievalResult questions(List<Question> questions);

  RetrievalResult recipes(List<SimilarRecipe> recipes);

  RetrievalResult requestId(String requestId);

  RetrievalResult status(AIStatus status);

  RetrievalResult text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RetrievalResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RetrievalResult(...).copyWith(id: 12, name: "My name")
  /// ````
  RetrievalResult call({
    RecipeIntent intent,
    bool? localFallback,
    List<Question> questions,
    List<SimilarRecipe> recipes,
    String requestId,
    AIStatus status,
    String text,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRetrievalResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRetrievalResult.copyWith.fieldName(...)`
class _$RetrievalResultCWProxyImpl implements _$RetrievalResultCWProxy {
  const _$RetrievalResultCWProxyImpl(this._value);

  final RetrievalResult _value;

  @override
  RetrievalResult intent(RecipeIntent intent) => this(intent: intent);

  @override
  RetrievalResult localFallback(bool? localFallback) =>
      this(localFallback: localFallback);

  @override
  RetrievalResult questions(List<Question> questions) =>
      this(questions: questions);

  @override
  RetrievalResult recipes(List<SimilarRecipe> recipes) =>
      this(recipes: recipes);

  @override
  RetrievalResult requestId(String requestId) => this(requestId: requestId);

  @override
  RetrievalResult status(AIStatus status) => this(status: status);

  @override
  RetrievalResult text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RetrievalResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RetrievalResult(...).copyWith(id: 12, name: "My name")
  /// ````
  RetrievalResult call({
    Object? intent = const $CopyWithPlaceholder(),
    Object? localFallback = const $CopyWithPlaceholder(),
    Object? questions = const $CopyWithPlaceholder(),
    Object? recipes = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return RetrievalResult(
      intent: intent == const $CopyWithPlaceholder()
          ? _value.intent
          // ignore: cast_nullable_to_non_nullable
          : intent as RecipeIntent,
      localFallback: localFallback == const $CopyWithPlaceholder()
          ? _value.localFallback
          // ignore: cast_nullable_to_non_nullable
          : localFallback as bool?,
      questions: questions == const $CopyWithPlaceholder()
          ? _value.questions
          // ignore: cast_nullable_to_non_nullable
          : questions as List<Question>,
      recipes: recipes == const $CopyWithPlaceholder()
          ? _value.recipes
          // ignore: cast_nullable_to_non_nullable
          : recipes as List<SimilarRecipe>,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AIStatus,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $RetrievalResultCopyWith on RetrievalResult {
  /// Returns a callable class that can be used as follows: `instanceOfRetrievalResult.copyWith(...)` or like so:`instanceOfRetrievalResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RetrievalResultCWProxy get copyWith => _$RetrievalResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RetrievalResult _$RetrievalResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RetrievalResult',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'intent',
            'questions',
            'recipes',
            'request_id',
            'status',
            'text',
          ],
        );
        final val = RetrievalResult(
          intent: $checkedConvert(
            'intent',
            (v) => RecipeIntent.fromJson(v as Map<String, dynamic>),
          ),
          localFallback: $checkedConvert(
            'local_fallback',
            (v) => v as bool? ?? false,
          ),
          questions: $checkedConvert(
            'questions',
            (v) => (v as List<dynamic>)
                .map((e) => Question.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          recipes: $checkedConvert(
            'recipes',
            (v) => (v as List<dynamic>)
                .map((e) => SimilarRecipe.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          requestId: $checkedConvert('request_id', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => AIStatus.fromJson(v as Map<String, dynamic>),
          ),
          text: $checkedConvert('text', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'localFallback': 'local_fallback',
        'requestId': 'request_id',
      },
    );

Map<String, dynamic> _$RetrievalResultToJson(RetrievalResult instance) =>
    <String, dynamic>{
      'intent': instance.intent.toJson(),
      'local_fallback': ?instance.localFallback,
      'questions': instance.questions.map((e) => e.toJson()).toList(),
      'recipes': instance.recipes.map((e) => e.toJson()).toList(),
      'request_id': instance.requestId,
      'status': instance.status.toJson(),
      'text': instance.text,
    };
