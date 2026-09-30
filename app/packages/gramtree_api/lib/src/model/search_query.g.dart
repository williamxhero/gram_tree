// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_query.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchQueryCWProxy {
  SearchQuery query(String query);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchQuery(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchQuery(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchQuery call({String query});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearchQuery.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearchQuery.copyWith.fieldName(...)`
class _$SearchQueryCWProxyImpl implements _$SearchQueryCWProxy {
  const _$SearchQueryCWProxyImpl(this._value);

  final SearchQuery _value;

  @override
  SearchQuery query(String query) => this(query: query);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchQuery(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchQuery(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchQuery call({Object? query = const $CopyWithPlaceholder()}) {
    return SearchQuery(
      query: query == const $CopyWithPlaceholder()
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
    );
  }
}

extension $SearchQueryCopyWith on SearchQuery {
  /// Returns a callable class that can be used as follows: `instanceOfSearchQuery.copyWith(...)` or like so:`instanceOfSearchQuery.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchQueryCWProxy get copyWith => _$SearchQueryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchQuery _$SearchQueryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SearchQuery', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['query']);
      final val = SearchQuery(
        query: $checkedConvert('query', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SearchQueryToJson(SearchQuery instance) =>
    <String, dynamic>{'query': instance.query};
