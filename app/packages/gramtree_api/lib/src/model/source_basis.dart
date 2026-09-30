//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'source_basis.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SourceBasis {
  /// Returns a new [SourceBasis] instance.
  SourceBasis({this.citation, required this.reasonCode, required this.text});

  @JsonKey(name: r'citation', required: false, includeIfNull: false)
  final String? citation;

  /// 理由代码，供程序判断用
  @JsonKey(name: r'reason_code', required: true, includeIfNull: false)
  final String reasonCode;

  /// 一句大白话说明
  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceBasis &&
          other.citation == citation &&
          other.reasonCode == reasonCode &&
          other.text == text;

  @override
  int get hashCode =>
      (citation == null ? 0 : citation.hashCode) +
      reasonCode.hashCode +
      text.hashCode;

  factory SourceBasis.fromJson(Map<String, dynamic> json) =>
      _$SourceBasisFromJson(json);

  Map<String, dynamic> toJson() => _$SourceBasisToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
