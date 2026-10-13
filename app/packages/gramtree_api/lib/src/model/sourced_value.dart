//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/source_basis.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sourced_value.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SourcedValue {
  /// Returns a new [SourcedValue] instance.
  SourcedValue({
    required this.basis,

    this.originalValue,

    required this.sourceType,

    required this.value,
  });

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final SourceBasis basis;

  @JsonKey(name: r'original_value', required: false, includeIfNull: false)
  final String? originalValue;

  @JsonKey(name: r'source_type', required: true, includeIfNull: false)
  final SourcedValueSourceTypeEnum sourceType;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourcedValue &&
          other.basis == basis &&
          other.originalValue == originalValue &&
          other.sourceType == sourceType &&
          other.value == value;

  @override
  int get hashCode =>
      basis.hashCode +
      (originalValue == null ? 0 : originalValue.hashCode) +
      sourceType.hashCode +
      value.hashCode;

  factory SourcedValue.fromJson(Map<String, dynamic> json) =>
      _$SourcedValueFromJson(json);

  Map<String, dynamic> toJson() => _$SourcedValueToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SourcedValueSourceTypeEnum {
  @JsonValue(r'author_filled')
  authorFilled(r'author_filled'),
  @JsonValue(r'taste_adjusted')
  tasteAdjusted(r'taste_adjusted'),
  @JsonValue(r'scenario_adjusted')
  scenarioAdjusted(r'scenario_adjusted'),
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated'),
  @JsonValue(r'verified')
  verified(r'verified');

  const SourcedValueSourceTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
