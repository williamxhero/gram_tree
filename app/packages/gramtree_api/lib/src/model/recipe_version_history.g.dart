// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_version_history.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeVersionHistoryCWProxy {
  RecipeVersionHistory items(List<RecipeVersionSummary> items);

  RecipeVersionHistory nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionHistory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionHistory(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionHistory call({
    List<RecipeVersionSummary> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeVersionHistory.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeVersionHistory.copyWith.fieldName(...)`
class _$RecipeVersionHistoryCWProxyImpl
    implements _$RecipeVersionHistoryCWProxy {
  const _$RecipeVersionHistoryCWProxyImpl(this._value);

  final RecipeVersionHistory _value;

  @override
  RecipeVersionHistory items(List<RecipeVersionSummary> items) =>
      this(items: items);

  @override
  RecipeVersionHistory nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionHistory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionHistory(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionHistory call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return RecipeVersionHistory(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RecipeVersionSummary>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $RecipeVersionHistoryCopyWith on RecipeVersionHistory {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeVersionHistory.copyWith(...)` or like so:`instanceOfRecipeVersionHistory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeVersionHistoryCWProxy get copyWith =>
      _$RecipeVersionHistoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeVersionHistory _$RecipeVersionHistoryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeVersionHistory', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = RecipeVersionHistory(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => RecipeVersionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$RecipeVersionHistoryToJson(
  RecipeVersionHistory instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
