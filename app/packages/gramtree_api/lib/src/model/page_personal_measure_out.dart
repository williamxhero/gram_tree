//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/personal_measure_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_personal_measure_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PagePersonalMeasureOut {
  /// Returns a new [PagePersonalMeasureOut] instance.
  PagePersonalMeasureOut({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<PersonalMeasureOut> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagePersonalMeasureOut &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory PagePersonalMeasureOut.fromJson(Map<String, dynamic> json) =>
      _$PagePersonalMeasureOutFromJson(json);

  Map<String, dynamic> toJson() => _$PagePersonalMeasureOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
