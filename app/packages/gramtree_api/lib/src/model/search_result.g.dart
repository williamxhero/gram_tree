// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchResultCWProxy {
  SearchResult items(List<IngredientOut> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchResult(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchResult call({List<IngredientOut> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearchResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearchResult.copyWith.fieldName(...)`
class _$SearchResultCWProxyImpl implements _$SearchResultCWProxy {
  const _$SearchResultCWProxyImpl(this._value);

  final SearchResult _value;

  @override
  SearchResult items(List<IngredientOut> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchResult(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchResult call({Object? items = const $CopyWithPlaceholder()}) {
    return SearchResult(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<IngredientOut>,
    );
  }
}

extension $SearchResultCopyWith on SearchResult {
  /// Returns a callable class that can be used as follows: `instanceOfSearchResult.copyWith(...)` or like so:`instanceOfSearchResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchResultCWProxy get copyWith => _$SearchResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SearchResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SearchResult(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => IngredientOut.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
