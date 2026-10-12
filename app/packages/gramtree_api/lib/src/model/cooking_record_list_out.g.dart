// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_record_list_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingRecordListOutCWProxy {
  CookingRecordListOut items(List<CookingRecordOut> items);

  CookingRecordListOut nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordListOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordListOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordListOut call({List<CookingRecordOut> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingRecordListOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingRecordListOut.copyWith.fieldName(...)`
class _$CookingRecordListOutCWProxyImpl
    implements _$CookingRecordListOutCWProxy {
  const _$CookingRecordListOutCWProxyImpl(this._value);

  final CookingRecordListOut _value;

  @override
  CookingRecordListOut items(List<CookingRecordOut> items) =>
      this(items: items);

  @override
  CookingRecordListOut nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordListOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordListOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordListOut call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return CookingRecordListOut(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CookingRecordOut>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $CookingRecordListOutCopyWith on CookingRecordListOut {
  /// Returns a callable class that can be used as follows: `instanceOfCookingRecordListOut.copyWith(...)` or like so:`instanceOfCookingRecordListOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingRecordListOutCWProxy get copyWith =>
      _$CookingRecordListOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingRecordListOut _$CookingRecordListOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CookingRecordListOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = CookingRecordListOut(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => CookingRecordOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$CookingRecordListOutToJson(
  CookingRecordListOut instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
