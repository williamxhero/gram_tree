// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_taste_profile_change_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageTasteProfileChangeOutCWProxy {
  PageTasteProfileChangeOut items(List<TasteProfileChangeOut> items);

  PageTasteProfileChangeOut nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageTasteProfileChangeOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageTasteProfileChangeOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PageTasteProfileChangeOut call({
    List<TasteProfileChangeOut> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPageTasteProfileChangeOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPageTasteProfileChangeOut.copyWith.fieldName(...)`
class _$PageTasteProfileChangeOutCWProxyImpl
    implements _$PageTasteProfileChangeOutCWProxy {
  const _$PageTasteProfileChangeOutCWProxyImpl(this._value);

  final PageTasteProfileChangeOut _value;

  @override
  PageTasteProfileChangeOut items(List<TasteProfileChangeOut> items) =>
      this(items: items);

  @override
  PageTasteProfileChangeOut nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageTasteProfileChangeOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageTasteProfileChangeOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PageTasteProfileChangeOut call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PageTasteProfileChangeOut(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TasteProfileChangeOut>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PageTasteProfileChangeOutCopyWith on PageTasteProfileChangeOut {
  /// Returns a callable class that can be used as follows: `instanceOfPageTasteProfileChangeOut.copyWith(...)` or like so:`instanceOfPageTasteProfileChangeOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageTasteProfileChangeOutCWProxy get copyWith =>
      _$PageTasteProfileChangeOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageTasteProfileChangeOut _$PageTasteProfileChangeOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PageTasteProfileChangeOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = PageTasteProfileChangeOut(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => TasteProfileChangeOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PageTasteProfileChangeOutToJson(
  PageTasteProfileChangeOut instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
