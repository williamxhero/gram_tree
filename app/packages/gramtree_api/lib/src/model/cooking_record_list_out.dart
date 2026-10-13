//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/cooking_record_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_record_list_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingRecordListOut {
  /// Returns a new [CookingRecordListOut] instance.
  CookingRecordListOut({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<CookingRecordOut> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingRecordListOut &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory CookingRecordListOut.fromJson(Map<String, dynamic> json) =>
      _$CookingRecordListOutFromJson(json);

  Map<String, dynamic> toJson() => _$CookingRecordListOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
