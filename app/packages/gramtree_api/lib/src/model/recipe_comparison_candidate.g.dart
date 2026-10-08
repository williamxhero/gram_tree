// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_comparison_candidate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeComparisonCandidateCWProxy {
  RecipeComparisonCandidate aiAssisted(bool aiAssisted);

  RecipeComparisonCandidate author(String author);

  RecipeComparisonCandidate changeNote(String changeNote);

  RecipeComparisonCandidate createdAt(String createdAt);

  RecipeComparisonCandidate id(String id);

  RecipeComparisonCandidate previousVersionId(String? previousVersionId);

  RecipeComparisonCandidate recipeId(String recipeId);

  RecipeComparisonCandidate versionNumber(int versionNumber);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeComparisonCandidate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeComparisonCandidate(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeComparisonCandidate call({
    bool aiAssisted,
    String author,
    String changeNote,
    String createdAt,
    String id,
    String? previousVersionId,
    String recipeId,
    int versionNumber,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeComparisonCandidate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeComparisonCandidate.copyWith.fieldName(...)`
class _$RecipeComparisonCandidateCWProxyImpl
    implements _$RecipeComparisonCandidateCWProxy {
  const _$RecipeComparisonCandidateCWProxyImpl(this._value);

  final RecipeComparisonCandidate _value;

  @override
  RecipeComparisonCandidate aiAssisted(bool aiAssisted) =>
      this(aiAssisted: aiAssisted);

  @override
  RecipeComparisonCandidate author(String author) => this(author: author);

  @override
  RecipeComparisonCandidate changeNote(String changeNote) =>
      this(changeNote: changeNote);

  @override
  RecipeComparisonCandidate createdAt(String createdAt) =>
      this(createdAt: createdAt);

  @override
  RecipeComparisonCandidate id(String id) => this(id: id);

  @override
  RecipeComparisonCandidate previousVersionId(String? previousVersionId) =>
      this(previousVersionId: previousVersionId);

  @override
  RecipeComparisonCandidate recipeId(String recipeId) =>
      this(recipeId: recipeId);

  @override
  RecipeComparisonCandidate versionNumber(int versionNumber) =>
      this(versionNumber: versionNumber);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeComparisonCandidate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeComparisonCandidate(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeComparisonCandidate call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? previousVersionId = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? versionNumber = const $CopyWithPlaceholder(),
  }) {
    return RecipeComparisonCandidate(
      aiAssisted: aiAssisted == const $CopyWithPlaceholder()
          ? _value.aiAssisted
          // ignore: cast_nullable_to_non_nullable
          : aiAssisted as bool,
      author: author == const $CopyWithPlaceholder()
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as String,
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      previousVersionId: previousVersionId == const $CopyWithPlaceholder()
          ? _value.previousVersionId
          // ignore: cast_nullable_to_non_nullable
          : previousVersionId as String?,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      versionNumber: versionNumber == const $CopyWithPlaceholder()
          ? _value.versionNumber
          // ignore: cast_nullable_to_non_nullable
          : versionNumber as int,
    );
  }
}

extension $RecipeComparisonCandidateCopyWith on RecipeComparisonCandidate {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeComparisonCandidate.copyWith(...)` or like so:`instanceOfRecipeComparisonCandidate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeComparisonCandidateCWProxy get copyWith =>
      _$RecipeComparisonCandidateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeComparisonCandidate _$RecipeComparisonCandidateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeComparisonCandidate',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ai_assisted',
        'author',
        'change_note',
        'created_at',
        'id',
        'recipe_id',
        'version_number',
      ],
    );
    final val = RecipeComparisonCandidate(
      aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool),
      author: $checkedConvert('author', (v) => v as String),
      changeNote: $checkedConvert('change_note', (v) => v as String),
      createdAt: $checkedConvert('created_at', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String),
      previousVersionId: $checkedConvert(
        'previous_version_id',
        (v) => v as String?,
      ),
      recipeId: $checkedConvert('recipe_id', (v) => v as String),
      versionNumber: $checkedConvert(
        'version_number',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'aiAssisted': 'ai_assisted',
    'changeNote': 'change_note',
    'createdAt': 'created_at',
    'previousVersionId': 'previous_version_id',
    'recipeId': 'recipe_id',
    'versionNumber': 'version_number',
  },
);

Map<String, dynamic> _$RecipeComparisonCandidateToJson(
  RecipeComparisonCandidate instance,
) => <String, dynamic>{
  'ai_assisted': instance.aiAssisted,
  'author': instance.author,
  'change_note': instance.changeNote,
  'created_at': instance.createdAt,
  'id': instance.id,
  'previous_version_id': ?instance.previousVersionId,
  'recipe_id': instance.recipeId,
  'version_number': instance.versionNumber,
};
