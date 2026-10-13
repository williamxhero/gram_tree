//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quantification_suggestion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuantificationSuggestion {
  /// Returns a new [QuantificationSuggestion] instance.
  QuantificationSuggestion({
    this.adjustment,

    this.baseline,

    required this.basis,

    required this.confidence,

    required this.problemId,

    this.unit,

    required this.value,
  });

  @JsonKey(name: r'adjustment', required: false, includeIfNull: false)
  final String? adjustment;

  @JsonKey(name: r'baseline', required: false, includeIfNull: false)
  final String? baseline;

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final QuantificationSuggestionConfidenceEnum confidence;

  @JsonKey(name: r'problem_id', required: true, includeIfNull: false)
  final String problemId;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final String? unit;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantificationSuggestion &&
          other.adjustment == adjustment &&
          other.baseline == baseline &&
          other.basis == basis &&
          other.confidence == confidence &&
          other.problemId == problemId &&
          other.unit == unit &&
          other.value == value;

  @override
  int get hashCode =>
      (adjustment == null ? 0 : adjustment.hashCode) +
      (baseline == null ? 0 : baseline.hashCode) +
      basis.hashCode +
      confidence.hashCode +
      problemId.hashCode +
      (unit == null ? 0 : unit.hashCode) +
      value.hashCode;

  factory QuantificationSuggestion.fromJson(Map<String, dynamic> json) =>
      _$QuantificationSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuantificationSuggestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum QuantificationSuggestionConfidenceEnum {
  @JsonValue(r'high')
  high(r'high'),
  @JsonValue(r'medium')
  medium(r'medium'),
  @JsonValue(r'low')
  low(r'low');

  const QuantificationSuggestionConfidenceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
