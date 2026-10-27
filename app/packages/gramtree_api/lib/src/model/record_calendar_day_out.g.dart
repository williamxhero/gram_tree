// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_calendar_day_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecordCalendarDayOutCWProxy {
  RecordCalendarDayOut date(String date);

  RecordCalendarDayOut end(String end);

  RecordCalendarDayOut start(String start);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecordCalendarDayOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecordCalendarDayOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecordCalendarDayOut call({String date, String end, String start});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecordCalendarDayOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecordCalendarDayOut.copyWith.fieldName(...)`
class _$RecordCalendarDayOutCWProxyImpl
    implements _$RecordCalendarDayOutCWProxy {
  const _$RecordCalendarDayOutCWProxyImpl(this._value);

  final RecordCalendarDayOut _value;

  @override
  RecordCalendarDayOut date(String date) => this(date: date);

  @override
  RecordCalendarDayOut end(String end) => this(end: end);

  @override
  RecordCalendarDayOut start(String start) => this(start: start);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecordCalendarDayOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecordCalendarDayOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecordCalendarDayOut call({
    Object? date = const $CopyWithPlaceholder(),
    Object? end = const $CopyWithPlaceholder(),
    Object? start = const $CopyWithPlaceholder(),
  }) {
    return RecordCalendarDayOut(
      date: date == const $CopyWithPlaceholder()
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      end: end == const $CopyWithPlaceholder()
          ? _value.end
          // ignore: cast_nullable_to_non_nullable
          : end as String,
      start: start == const $CopyWithPlaceholder()
          ? _value.start
          // ignore: cast_nullable_to_non_nullable
          : start as String,
    );
  }
}

extension $RecordCalendarDayOutCopyWith on RecordCalendarDayOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecordCalendarDayOut.copyWith(...)` or like so:`instanceOfRecordCalendarDayOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecordCalendarDayOutCWProxy get copyWith =>
      _$RecordCalendarDayOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordCalendarDayOut _$RecordCalendarDayOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecordCalendarDayOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['date', 'end', 'start']);
  final val = RecordCalendarDayOut(
    date: $checkedConvert('date', (v) => v as String),
    end: $checkedConvert('end', (v) => v as String),
    start: $checkedConvert('start', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RecordCalendarDayOutToJson(
  RecordCalendarDayOut instance,
) => <String, dynamic>{
  'date': instance.date,
  'end': instance.end,
  'start': instance.start,
};
