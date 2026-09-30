// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeListCWProxy {
  RecipeList items(List<RecipeListItem> items);

  RecipeList nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeList(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeList call({List<RecipeListItem> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeList.copyWith.fieldName(...)`
class _$RecipeListCWProxyImpl implements _$RecipeListCWProxy {
  const _$RecipeListCWProxyImpl(this._value);

  final RecipeList _value;

  @override
  RecipeList items(List<RecipeListItem> items) => this(items: items);

  @override
  RecipeList nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeList(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return RecipeList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RecipeListItem>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $RecipeListCopyWith on RecipeList {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeList.copyWith(...)` or like so:`instanceOfRecipeList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeListCWProxy get copyWith => _$RecipeListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeList _$RecipeListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecipeList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = RecipeList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => RecipeListItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$RecipeListToJson(RecipeList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': ?instance.nextCursor,
    };
