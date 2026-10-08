//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_version_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeVersionCreate {
  /// Returns a new [RecipeVersionCreate] instance.
  RecipeVersionCreate({
    this.aiAssisted = false,

    this.baseVersionId,

    this.changeNote = '',

    this.expectedCurrentVersionId,

    this.imageIds,

    required this.snapshot,
  });

  @JsonKey(
    defaultValue: false,
    name: r'ai_assisted',
    required: false,
    includeIfNull: false,
  )
  final bool? aiAssisted;

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(
    defaultValue: '',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  /// 可选并发保护；不改变显式从历史版分支的行为
  @JsonKey(
    name: r'expected_current_version_id',
    required: false,
    includeIfNull: false,
  )
  final String? expectedCurrentVersionId;

  @JsonKey(name: r'image_ids', required: false, includeIfNull: false)
  final List<String>? imageIds;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeVersionCreate &&
          other.aiAssisted == aiAssisted &&
          other.baseVersionId == baseVersionId &&
          other.changeNote == changeNote &&
          other.expectedCurrentVersionId == expectedCurrentVersionId &&
          other.imageIds == imageIds &&
          other.snapshot == snapshot;

  @override
  int get hashCode =>
      aiAssisted.hashCode +
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      changeNote.hashCode +
      (expectedCurrentVersionId == null
          ? 0
          : expectedCurrentVersionId.hashCode) +
      imageIds.hashCode +
      snapshot.hashCode;

  factory RecipeVersionCreate.fromJson(Map<String, dynamic> json) =>
      _$RecipeVersionCreateFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeVersionCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
