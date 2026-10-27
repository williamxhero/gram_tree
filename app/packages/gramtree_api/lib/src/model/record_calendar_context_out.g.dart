// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_calendar_context_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecordCalendarContextOutCWProxy {
  RecordCalendarContextOut days(List<RecordCalendarDayOut> days);

  RecordCalendarContextOut month(int month);

  RecordCalendarContextOut timezone(String timezone);

  RecordCalendarContextOut year(int year);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecordCalendarContextOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecordCalendarContextOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecordCalendarContextOut call({
    List<RecordCalendarDayOut> days,
    int month,
    String timezone,
    int year,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecordCalendarContextOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecordCalendarContextOut.copyWith.fieldName(...)`
class _$RecordCalendarContextOutCWProxyImpl
    implements _$RecordCalendarContextOutCWProxy {
  const _$RecordCalendarContextOutCWProxyImpl(this._value);

  final RecordCalendarContextOut _value;

  @override
  RecordCalendarContextOut days(List<RecordCalendarDayOut> days) =>
      this(days: days);

  @override
  RecordCalendarContextOut month(int month) => this(month: month);

  @override
  RecordCalendarContextOut timezone(String timezone) =>
      this(timezone: timezone);

  @override
  RecordCalendarContextOut year(int year) => this(year: year);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecordCalendarContextOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecordCalendarContextOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecordCalendarContextOut call({
    Object? days = const $CopyWithPlaceholder(),
    Object? month = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
  }) {
    return RecordCalendarContextOut(
      days: days == const $CopyWithPlaceholder()
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as List<RecordCalendarDayOut>,
      month: month == const $CopyWithPlaceholder()
          ? _value.month
          // ignore: cast_nullable_to_non_nullable
          : month as int,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      year: year == const $CopyWithPlaceholder()
          ? _value.year
          // ignore: cast_nullable_to_non_nullable
          : year as int,
    );
  }
}

extension $RecordCalendarContextOutCopyWith on RecordCalendarContextOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecordCalendarContextOut.copyWith(...)` or like so:`instanceOfRecordCalendarContextOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecordCalendarContextOutCWProxy get copyWith =>
      _$RecordCalendarContextOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordCalendarContextOut _$RecordCalendarContextOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecordCalendarContextOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['days', 'month', 'timezone', 'year']);
  final val = RecordCalendarContextOut(
    days: $checkedConvert(
      'days',
      (v) => (v as List<dynamic>)
          .map((e) => RecordCalendarDayOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    month: $checkedConvert('month', (v) => (v as num).toInt()),
    timezone: $checkedConvert('timezone', (v) => v as String),
    year: $checkedConvert('year', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$RecordCalendarContextOutToJson(
  RecordCalendarContextOut instance,
) => <String, dynamic>{
  'days': instance.days.map((e) => e.toJson()).toList(),
  'month': instance.month,
  'timezone': instance.timezone,
  'year': instance.year,
};
