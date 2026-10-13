// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_comparison_candidates.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeComparisonCandidatesCWProxy {
  RecipeComparisonCandidates items(List<RecipeComparisonCandidate> items);

  RecipeComparisonCandidates nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeComparisonCandidates(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeComparisonCandidates(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeComparisonCandidates call({
    List<RecipeComparisonCandidate> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeComparisonCandidates.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeComparisonCandidates.copyWith.fieldName(...)`
class _$RecipeComparisonCandidatesCWProxyImpl
    implements _$RecipeComparisonCandidatesCWProxy {
  const _$RecipeComparisonCandidatesCWProxyImpl(this._value);

  final RecipeComparisonCandidates _value;

  @override
  RecipeComparisonCandidates items(List<RecipeComparisonCandidate> items) =>
      this(items: items);

  @override
  RecipeComparisonCandidates nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeComparisonCandidates(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeComparisonCandidates(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeComparisonCandidates call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return RecipeComparisonCandidates(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RecipeComparisonCandidate>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $RecipeComparisonCandidatesCopyWith on RecipeComparisonCandidates {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeComparisonCandidates.copyWith(...)` or like so:`instanceOfRecipeComparisonCandidates.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeComparisonCandidatesCWProxy get copyWith =>
      _$RecipeComparisonCandidatesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeComparisonCandidates _$RecipeComparisonCandidatesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeComparisonCandidates', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = RecipeComparisonCandidates(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                RecipeComparisonCandidate.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$RecipeComparisonCandidatesToJson(
  RecipeComparisonCandidates instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
