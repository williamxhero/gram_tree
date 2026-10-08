// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_quantification_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeQuantificationOutCWProxy {
  RecipeQuantificationOut baseVersionId(String baseVersionId);

  RecipeQuantificationOut detail(RecipeQuantificationOutDetailEnum detail);

  RecipeQuantificationOut id(String id);

  RecipeQuantificationOut problems(List<ReproducibilityProblem> problems);

  RecipeQuantificationOut suggestions(
    List<QuantificationSuggestion> suggestions,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeQuantificationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeQuantificationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeQuantificationOut call({
    String baseVersionId,
    RecipeQuantificationOutDetailEnum detail,
    String id,
    List<ReproducibilityProblem> problems,
    List<QuantificationSuggestion> suggestions,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeQuantificationOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeQuantificationOut.copyWith.fieldName(...)`
class _$RecipeQuantificationOutCWProxyImpl
    implements _$RecipeQuantificationOutCWProxy {
  const _$RecipeQuantificationOutCWProxyImpl(this._value);

  final RecipeQuantificationOut _value;

  @override
  RecipeQuantificationOut baseVersionId(String baseVersionId) =>
      this(baseVersionId: baseVersionId);

  @override
  RecipeQuantificationOut detail(RecipeQuantificationOutDetailEnum detail) =>
      this(detail: detail);

  @override
  RecipeQuantificationOut id(String id) => this(id: id);

  @override
  RecipeQuantificationOut problems(List<ReproducibilityProblem> problems) =>
      this(problems: problems);

  @override
  RecipeQuantificationOut suggestions(
    List<QuantificationSuggestion> suggestions,
  ) => this(suggestions: suggestions);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeQuantificationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeQuantificationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeQuantificationOut call({
    Object? baseVersionId = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? problems = const $CopyWithPlaceholder(),
    Object? suggestions = const $CopyWithPlaceholder(),
  }) {
    return RecipeQuantificationOut(
      baseVersionId: baseVersionId == const $CopyWithPlaceholder()
          ? _value.baseVersionId
          // ignore: cast_nullable_to_non_nullable
          : baseVersionId as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as RecipeQuantificationOutDetailEnum,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      problems: problems == const $CopyWithPlaceholder()
          ? _value.problems
          // ignore: cast_nullable_to_non_nullable
          : problems as List<ReproducibilityProblem>,
      suggestions: suggestions == const $CopyWithPlaceholder()
          ? _value.suggestions
          // ignore: cast_nullable_to_non_nullable
          : suggestions as List<QuantificationSuggestion>,
    );
  }
}

extension $RecipeQuantificationOutCopyWith on RecipeQuantificationOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeQuantificationOut.copyWith(...)` or like so:`instanceOfRecipeQuantificationOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeQuantificationOutCWProxy get copyWith =>
      _$RecipeQuantificationOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeQuantificationOut _$RecipeQuantificationOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeQuantificationOut', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'base_version_id',
      'detail',
      'id',
      'problems',
      'suggestions',
    ],
  );
  final val = RecipeQuantificationOut(
    baseVersionId: $checkedConvert('base_version_id', (v) => v as String),
    detail: $checkedConvert(
      'detail',
      (v) => $enumDecode(_$RecipeQuantificationOutDetailEnumEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
    problems: $checkedConvert(
      'problems',
      (v) => (v as List<dynamic>)
          .map(
            (e) => ReproducibilityProblem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    suggestions: $checkedConvert(
      'suggestions',
      (v) => (v as List<dynamic>)
          .map(
            (e) => QuantificationSuggestion.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'baseVersionId': 'base_version_id'});

Map<String, dynamic> _$RecipeQuantificationOutToJson(
  RecipeQuantificationOut instance,
) => <String, dynamic>{
  'base_version_id': instance.baseVersionId,
  'detail': _$RecipeQuantificationOutDetailEnumEnumMap[instance.detail]!,
  'id': instance.id,
  'problems': instance.problems.map((e) => e.toJson()).toList(),
  'suggestions': instance.suggestions.map((e) => e.toJson()).toList(),
};

const _$RecipeQuantificationOutDetailEnumEnumMap = {
  RecipeQuantificationOutDetailEnum.brief: 'brief',
  RecipeQuantificationOutDetailEnum.standard: 'standard',
  RecipeQuantificationOutDetailEnum.detailed: 'detailed',
};
