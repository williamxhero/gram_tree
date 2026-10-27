//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/record_calendar_day_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'record_calendar_context_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecordCalendarContextOut {
  /// Returns a new [RecordCalendarContextOut] instance.
  RecordCalendarContextOut({
    required this.days,

    required this.month,

    required this.timezone,

    required this.year,
  });

  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<RecordCalendarDayOut> days;

  @JsonKey(name: r'month', required: true, includeIfNull: false)
  final int month;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  @JsonKey(name: r'year', required: true, includeIfNull: false)
  final int year;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordCalendarContextOut &&
          other.days == days &&
          other.month == month &&
          other.timezone == timezone &&
          other.year == year;

  @override
  int get hashCode =>
      days.hashCode + month.hashCode + timezone.hashCode + year.hashCode;

  factory RecordCalendarContextOut.fromJson(Map<String, dynamic> json) =>
      _$RecordCalendarContextOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecordCalendarContextOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
