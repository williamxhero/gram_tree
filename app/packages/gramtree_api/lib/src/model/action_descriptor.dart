//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_descriptor.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionDescriptor {
  /// Returns a new [ActionDescriptor] instance.
  ActionDescriptor({required this.intent, this.params});

  /// 已登记的意图名（SPEC-009.1 #81）
  @JsonKey(name: r'intent', required: true, includeIfNull: false)
  final String intent;

  @JsonKey(name: r'params', required: false, includeIfNull: false)
  final Object? params;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionDescriptor &&
          other.intent == intent &&
          other.params == params;

  @override
  int get hashCode => intent.hashCode + params.hashCode;

  factory ActionDescriptor.fromJson(Map<String, dynamic> json) =>
      _$ActionDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$ActionDescriptorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
