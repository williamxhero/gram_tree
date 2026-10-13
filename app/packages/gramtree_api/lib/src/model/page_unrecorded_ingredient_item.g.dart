// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_unrecorded_ingredient_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageUnrecordedIngredientItemCWProxy {
  PageUnrecordedIngredientItem items(List<UnrecordedIngredientItem> items);

  PageUnrecordedIngredientItem nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageUnrecordedIngredientItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageUnrecordedIngredientItem(...).copyWith(id: 12, name: "My name")
  /// ````
  PageUnrecordedIngredientItem call({
    List<UnrecordedIngredientItem> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPageUnrecordedIngredientItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPageUnrecordedIngredientItem.copyWith.fieldName(...)`
class _$PageUnrecordedIngredientItemCWProxyImpl
    implements _$PageUnrecordedIngredientItemCWProxy {
  const _$PageUnrecordedIngredientItemCWProxyImpl(this._value);

  final PageUnrecordedIngredientItem _value;

  @override
  PageUnrecordedIngredientItem items(List<UnrecordedIngredientItem> items) =>
      this(items: items);

  @override
  PageUnrecordedIngredientItem nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageUnrecordedIngredientItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageUnrecordedIngredientItem(...).copyWith(id: 12, name: "My name")
  /// ````
  PageUnrecordedIngredientItem call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PageUnrecordedIngredientItem(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<UnrecordedIngredientItem>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PageUnrecordedIngredientItemCopyWith
    on PageUnrecordedIngredientItem {
  /// Returns a callable class that can be used as follows: `instanceOfPageUnrecordedIngredientItem.copyWith(...)` or like so:`instanceOfPageUnrecordedIngredientItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageUnrecordedIngredientItemCWProxy get copyWith =>
      _$PageUnrecordedIngredientItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageUnrecordedIngredientItem _$PageUnrecordedIngredientItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PageUnrecordedIngredientItem', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = PageUnrecordedIngredientItem(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map(
            (e) => UnrecordedIngredientItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PageUnrecordedIngredientItemToJson(
  PageUnrecordedIngredientItem instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
