// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_question.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeQuestionCWProxy {
  RecipeQuestion question(String question);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeQuestion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeQuestion(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeQuestion call({String question});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeQuestion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeQuestion.copyWith.fieldName(...)`
class _$RecipeQuestionCWProxyImpl implements _$RecipeQuestionCWProxy {
  const _$RecipeQuestionCWProxyImpl(this._value);

  final RecipeQuestion _value;

  @override
  RecipeQuestion question(String question) => this(question: question);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeQuestion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeQuestion(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeQuestion call({Object? question = const $CopyWithPlaceholder()}) {
    return RecipeQuestion(
      question: question == const $CopyWithPlaceholder()
          ? _value.question
          // ignore: cast_nullable_to_non_nullable
          : question as String,
    );
  }
}

extension $RecipeQuestionCopyWith on RecipeQuestion {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeQuestion.copyWith(...)` or like so:`instanceOfRecipeQuestion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeQuestionCWProxy get copyWith => _$RecipeQuestionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeQuestion _$RecipeQuestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecipeQuestion', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['question']);
      final val = RecipeQuestion(
        question: $checkedConvert('question', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RecipeQuestionToJson(RecipeQuestion instance) =>
    <String, dynamic>{'question': instance.question};
