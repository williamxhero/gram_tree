// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_record_history_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingRecordHistoryOutCWProxy {
  CookingRecordHistoryOut items(List<CookingRecordRevisionOut> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordHistoryOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordHistoryOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordHistoryOut call({List<CookingRecordRevisionOut> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingRecordHistoryOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingRecordHistoryOut.copyWith.fieldName(...)`
class _$CookingRecordHistoryOutCWProxyImpl
    implements _$CookingRecordHistoryOutCWProxy {
  const _$CookingRecordHistoryOutCWProxyImpl(this._value);

  final CookingRecordHistoryOut _value;

  @override
  CookingRecordHistoryOut items(List<CookingRecordRevisionOut> items) =>
      this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingRecordHistoryOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingRecordHistoryOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingRecordHistoryOut call({Object? items = const $CopyWithPlaceholder()}) {
    return CookingRecordHistoryOut(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CookingRecordRevisionOut>,
    );
  }
}

extension $CookingRecordHistoryOutCopyWith on CookingRecordHistoryOut {
  /// Returns a callable class that can be used as follows: `instanceOfCookingRecordHistoryOut.copyWith(...)` or like so:`instanceOfCookingRecordHistoryOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingRecordHistoryOutCWProxy get copyWith =>
      _$CookingRecordHistoryOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingRecordHistoryOut _$CookingRecordHistoryOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CookingRecordHistoryOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = CookingRecordHistoryOut(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map(
            (e) => CookingRecordRevisionOut.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$CookingRecordHistoryOutToJson(
  CookingRecordHistoryOut instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
