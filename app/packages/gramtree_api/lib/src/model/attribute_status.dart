//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// 字段的校对状态。
enum AttributeStatus {
  /// 字段的校对状态。
  @JsonValue(r'ai_draft')
  aiDraft(r'ai_draft'),

  /// 字段的校对状态。
  @JsonValue(r'verified')
  verified(r'verified');

  const AttributeStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
