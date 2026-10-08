//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'value_source.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ValueSource {
  /// Returns a new [ValueSource] instance.
  ValueSource({
    this.adjustment,

    this.baseline,

    this.basis,

    this.confidence,

    this.confidenceLevel,

    this.original,

    required this.source_,
  });

  @JsonKey(name: r'adjustment', required: false, includeIfNull: false)
  final String? adjustment;

  @JsonKey(name: r'baseline', required: false, includeIfNull: false)
  final String? baseline;

  @JsonKey(name: r'basis', required: false, includeIfNull: false)
  final String? basis;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'confidence', required: false, includeIfNull: false)
  final num? confidence;

  @JsonKey(name: r'confidence_level', required: false, includeIfNull: false)
  final ValueSourceConfidenceLevelEnum? confidenceLevel;

  @JsonKey(name: r'original', required: false, includeIfNull: false)
  final String? original;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final ValueSourceSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueSource &&
          other.adjustment == adjustment &&
          other.baseline == baseline &&
          other.basis == basis &&
          other.confidence == confidence &&
          other.confidenceLevel == confidenceLevel &&
          other.original == original &&
          other.source_ == source_;

  @override
  int get hashCode =>
      (adjustment == null ? 0 : adjustment.hashCode) +
      (baseline == null ? 0 : baseline.hashCode) +
      (basis == null ? 0 : basis.hashCode) +
      (confidence == null ? 0 : confidence.hashCode) +
      (confidenceLevel == null ? 0 : confidenceLevel.hashCode) +
      (original == null ? 0 : original.hashCode) +
      source_.hashCode;

  factory ValueSource.fromJson(Map<String, dynamic> json) =>
      _$ValueSourceFromJson(json);

  Map<String, dynamic> toJson() => _$ValueSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ValueSourceConfidenceLevelEnum {
  @JsonValue(r'high')
  high(r'high'),
  @JsonValue(r'medium')
  medium(r'medium'),
  @JsonValue(r'low')
  low(r'low');

  const ValueSourceConfidenceLevelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ValueSourceSource_Enum {
  @JsonValue(r'author_filled')
  authorFilled(r'author_filled'),
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated'),
  @JsonValue(r'verified')
  verified(r'verified');

  const ValueSourceSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
