//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'component_reason.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComponentReason {
  /// Returns a new [ComponentReason] instance.
  ComponentReason({required this.code, required this.text});

  /// 理由代码，例如 default
  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  /// 给人看的一句话说明
  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentReason && other.code == code && other.text == text;

  @override
  int get hashCode => code.hashCode + text.hashCode;

  factory ComponentReason.fromJson(Map<String, dynamic> json) =>
      _$ComponentReasonFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentReasonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
