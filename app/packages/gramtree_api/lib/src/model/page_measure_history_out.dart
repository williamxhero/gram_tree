//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/measure_history_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_measure_history_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageMeasureHistoryOut {
  /// Returns a new [PageMeasureHistoryOut] instance.
  PageMeasureHistoryOut({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<MeasureHistoryOut> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageMeasureHistoryOut &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory PageMeasureHistoryOut.fromJson(Map<String, dynamic> json) =>
      _$PageMeasureHistoryOutFromJson(json);

  Map<String, dynamic> toJson() => _$PageMeasureHistoryOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
