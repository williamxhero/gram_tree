//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_version_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_version_history.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeVersionHistory {
  /// Returns a new [RecipeVersionHistory] instance.
  RecipeVersionHistory({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<RecipeVersionSummary> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeVersionHistory &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode => items.hashCode + nextCursor.hashCode;

  factory RecipeVersionHistory.fromJson(Map<String, dynamic> json) =>
      _$RecipeVersionHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeVersionHistoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
