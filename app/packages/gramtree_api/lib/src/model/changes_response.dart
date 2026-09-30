//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/merge_relation.dart';
import 'package:gramtree_api/src/model/ingredient_detail.dart';
import 'package:gramtree_api/src/model/release_note.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'changes_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangesResponse {
  /// Returns a new [ChangesResponse] instance.
  ChangesResponse({
    required this.added,

    required this.currentVersion,

    required this.merged,

    required this.modified,

    required this.releases,
  });

  /// 这个区间里新增的食材，含全部详细属性
  @JsonKey(name: r'added', required: true, includeIfNull: false)
  final List<IngredientDetail> added;

  /// 服务端当前的食材库版本，App 存下来当下次请求的 since_version
  @JsonKey(name: r'current_version', required: true, includeIfNull: false)
  final String currentVersion;

  /// 这个区间里生效的合并关系，旧 ID → 新 ID
  @JsonKey(name: r'merged', required: true, includeIfNull: false)
  final List<MergeRelation> merged;

  /// 这个区间里改动过的食材，含全部详细属性
  @JsonKey(name: r'modified', required: true, includeIfNull: false)
  final List<IngredientDetail> modified;

  /// 这个区间内每次发布的版本号和变更说明，按版本从早到晚
  @JsonKey(name: r'releases', required: true, includeIfNull: false)
  final List<ReleaseNote> releases;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangesResponse &&
          other.added == added &&
          other.currentVersion == currentVersion &&
          other.merged == merged &&
          other.modified == modified &&
          other.releases == releases;

  @override
  int get hashCode =>
      added.hashCode +
      currentVersion.hashCode +
      merged.hashCode +
      modified.hashCode +
      releases.hashCode;

  factory ChangesResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChangesResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
