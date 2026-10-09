// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_measure_history_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageMeasureHistoryOutCWProxy {
  PageMeasureHistoryOut items(List<MeasureHistoryOut> items);

  PageMeasureHistoryOut nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageMeasureHistoryOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageMeasureHistoryOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PageMeasureHistoryOut call({
    List<MeasureHistoryOut> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPageMeasureHistoryOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPageMeasureHistoryOut.copyWith.fieldName(...)`
class _$PageMeasureHistoryOutCWProxyImpl
    implements _$PageMeasureHistoryOutCWProxy {
  const _$PageMeasureHistoryOutCWProxyImpl(this._value);

  final PageMeasureHistoryOut _value;

  @override
  PageMeasureHistoryOut items(List<MeasureHistoryOut> items) =>
      this(items: items);

  @override
  PageMeasureHistoryOut nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageMeasureHistoryOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageMeasureHistoryOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PageMeasureHistoryOut call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PageMeasureHistoryOut(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MeasureHistoryOut>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PageMeasureHistoryOutCopyWith on PageMeasureHistoryOut {
  /// Returns a callable class that can be used as follows: `instanceOfPageMeasureHistoryOut.copyWith(...)` or like so:`instanceOfPageMeasureHistoryOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageMeasureHistoryOutCWProxy get copyWith =>
      _$PageMeasureHistoryOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageMeasureHistoryOut _$PageMeasureHistoryOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PageMeasureHistoryOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = PageMeasureHistoryOut(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => MeasureHistoryOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PageMeasureHistoryOutToJson(
  PageMeasureHistoryOut instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': ?instance.nextCursor,
};
