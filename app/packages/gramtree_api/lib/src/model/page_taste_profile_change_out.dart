//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/taste_profile_change_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_taste_profile_change_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageTasteProfileChangeOut {
  /// Returns a new [PageTasteProfileChangeOut] instance.
  PageTasteProfileChangeOut({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<TasteProfileChangeOut> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageTasteProfileChangeOut &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory PageTasteProfileChangeOut.fromJson(Map<String, dynamic> json) =>
      _$PageTasteProfileChangeOutFromJson(json);

  Map<String, dynamic> toJson() => _$PageTasteProfileChangeOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
