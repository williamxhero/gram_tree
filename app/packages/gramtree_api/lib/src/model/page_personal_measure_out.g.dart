// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_personal_measure_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PagePersonalMeasureOutCWProxy {
  PagePersonalMeasureOut items(List<PersonalMeasureOut> items);

  PagePersonalMeasureOut nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PagePersonalMeasureOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PagePersonalMeasureOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PagePersonalMeasureOut call({
    List<PersonalMeasureOut> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPagePersonalMeasureOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPagePersonalMeasureOut.copyWith.fieldName(...)`
class _$PagePersonalMeasureOutCWProxyImpl
    implements _$PagePersonalMeasureOutCWProxy {
  const _$PagePersonalMeasureOutCWProxyImpl(this._value);

  final PagePersonalMeasureOut _value;

  @override
  PagePersonalMeasureOut items(List<PersonalMeasureOut> items) =>
      this(items: items);

  @override
  PagePersonalMeasureOut nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PagePersonalMeasureOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PagePersonalMeasureOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PagePersonalMeasureOut call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PagePersonalMeasureOut(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PersonalMeasureOut>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PagePersonalMeasureOutCopyWith on PagePersonalMeasureOut {
  /// Returns a callable class that can be used as follows: `instanceOfPagePersonalMeasureOut.copyWith(...)` or like so:`instanceOfPagePersonalMeasureOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PagePersonalMeasureOutCWProxy get copyWith =>
      _$PagePersonalMeasureOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagePersonalMeasureOut _$PagePersonalMeasureOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PagePersonalMeasureOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = PagePersonalMeasureOut(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => PersonalMeasureOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PagePersonalMeasureOutToJson(
  PagePersonalMeasureOut instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
