//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'normalize_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NormalizeItem {
  /// Returns a new [NormalizeItem] instance.
  NormalizeItem({this.context, required this.name});

  @JsonKey(name: r'context', required: false, includeIfNull: false)
  final String? context;

  /// 菜谱里写的食材名称
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizeItem && other.context == context && other.name == name;

  @override
  int get hashCode => (context == null ? 0 : context.hashCode) + name.hashCode;

  factory NormalizeItem.fromJson(Map<String, dynamic> json) =>
      _$NormalizeItemFromJson(json);

  Map<String, dynamic> toJson() => _$NormalizeItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
