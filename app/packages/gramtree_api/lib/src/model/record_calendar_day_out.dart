//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'record_calendar_day_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecordCalendarDayOut {
  /// Returns a new [RecordCalendarDayOut] instance.
  RecordCalendarDayOut({
    required this.date,

    required this.end,

    required this.start,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  @JsonKey(name: r'end', required: true, includeIfNull: false)
  final String end;

  @JsonKey(name: r'start', required: true, includeIfNull: false)
  final String start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordCalendarDayOut &&
          other.date == date &&
          other.end == end &&
          other.start == start;

  @override
  int get hashCode => date.hashCode + end.hashCode + start.hashCode;

  factory RecordCalendarDayOut.fromJson(Map<String, dynamic> json) =>
      _$RecordCalendarDayOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecordCalendarDayOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
