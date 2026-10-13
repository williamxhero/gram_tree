//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/unrecorded_ingredient_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_unrecorded_ingredient_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageUnrecordedIngredientItem {
  /// Returns a new [PageUnrecordedIngredientItem] instance.
  PageUnrecordedIngredientItem({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<UnrecordedIngredientItem> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageUnrecordedIngredientItem &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory PageUnrecordedIngredientItem.fromJson(Map<String, dynamic> json) =>
      _$PageUnrecordedIngredientItemFromJson(json);

  Map<String, dynamic> toJson() => _$PageUnrecordedIngredientItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
