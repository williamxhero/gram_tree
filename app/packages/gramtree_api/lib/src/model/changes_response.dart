//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
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

    required  this.added,

    required  this.currentVersion,

    required  this.merged,

    required  this.modified,
  });

      /// 新增的食材 ID
  @JsonKey(
    
    name: r'added',
    required: true,
    includeIfNull: false,
  )


  final List<String> added;



      /// 数据库里当前的食材库版本
  @JsonKey(
    
    name: r'current_version',
    required: true,
    includeIfNull: false,
  )


  final String currentVersion;



      /// 合并关系：旧 ID -> 新 ID
  @JsonKey(
    
    name: r'merged',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> merged;



      /// 内容有变化的食材 ID（含属性变化）
  @JsonKey(
    
    name: r'modified',
    required: true,
    includeIfNull: false,
  )


  final List<String> modified;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChangesResponse &&
      other.added == added &&
      other.currentVersion == currentVersion &&
      other.merged == merged &&
      other.modified == modified;

    @override
    int get hashCode =>
        added.hashCode +
        currentVersion.hashCode +
        merged.hashCode +
        modified.hashCode;

  factory ChangesResponse.fromJson(Map<String, dynamic> json) => _$ChangesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChangesResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

