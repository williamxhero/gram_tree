//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ingredient_detail.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchResponse {
  /// Returns a new [BatchResponse] instance.
  BatchResponse({required this.items, required this.missingIds});

  /// 读到完整数据的食材，按请求里的顺序；已合并的旧 ID 返回合并后的新食材
  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<IngredientDetail> items;

  /// 库里没有的 ID，单独列出，不影响整次请求
  @JsonKey(name: r'missing_ids', required: true, includeIfNull: false)
  final List<String> missingIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchResponse &&
          other.items == items &&
          other.missingIds == missingIds;

  @override
  int get hashCode => items.hashCode + missingIds.hashCode;

  factory BatchResponse.fromJson(Map<String, dynamic> json) =>
      _$BatchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BatchResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
