//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/action_descriptor.dart';
import 'package:gramtree_api/src/model/component_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'component_descriptor.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComponentDescriptor {
  /// Returns a new [ComponentDescriptor] instance.
  ComponentDescriptor({
    this.actions,

    required this.data,

    required this.detail,

    required this.id,

    required this.reason,

    this.required_ = false,

    required this.type,
  });

  @JsonKey(name: r'actions', required: false, includeIfNull: false)
  final List<ActionDescriptor>? actions;

  /// 组件数据，形状由该 type 的组件 Schema 定义
  @JsonKey(name: r'data', required: true, includeIfNull: false)
  final Object data;

  @JsonKey(name: r'detail', required: true, includeIfNull: false)
  final ComponentDescriptorDetailEnum detail;

  /// 这份描述里的组件实例 ID
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final ComponentReason reason;

  /// 是否是必显组件
  @JsonKey(
    defaultValue: false,
    name: r'required',
    required: false,
    includeIfNull: false,
  )
  final bool? required_;

  /// 组件类型名，必须是 App 声明支持的组件
  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final String type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentDescriptor &&
          other.actions == actions &&
          other.data == data &&
          other.detail == detail &&
          other.id == id &&
          other.reason == reason &&
          other.required_ == required_ &&
          other.type == type;

  @override
  int get hashCode =>
      actions.hashCode +
      data.hashCode +
      detail.hashCode +
      id.hashCode +
      reason.hashCode +
      required_.hashCode +
      type.hashCode;

  factory ComponentDescriptor.fromJson(Map<String, dynamic> json) =>
      _$ComponentDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentDescriptorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ComponentDescriptorDetailEnum {
  @JsonValue(r'brief')
  brief(r'brief'),
  @JsonValue(r'standard')
  standard(r'standard'),
  @JsonValue(r'detailed')
  detailed(r'detailed');

  const ComponentDescriptorDetailEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
