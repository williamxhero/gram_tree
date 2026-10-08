//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_flavor_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteFlavorOut {
  /// Returns a new [TasteFlavorOut] instance.
  TasteFlavorOut({
    required this.coefficient,

    required this.confidence,

    required this.confidenceText,

    required this.label,

    required this.level,
  });

  @JsonKey(name: r'coefficient', required: true, includeIfNull: false)
  final num coefficient;

  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final TasteFlavorOutConfidenceEnum confidence;

  @JsonKey(name: r'confidence_text', required: true, includeIfNull: false)
  final String confidenceText;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final int level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteFlavorOut &&
          other.coefficient == coefficient &&
          other.confidence == confidence &&
          other.confidenceText == confidenceText &&
          other.label == label &&
          other.level == level;

  @override
  int get hashCode =>
      coefficient.hashCode +
      confidence.hashCode +
      confidenceText.hashCode +
      label.hashCode +
      level.hashCode;

  factory TasteFlavorOut.fromJson(Map<String, dynamic> json) =>
      _$TasteFlavorOutFromJson(json);

  Map<String, dynamic> toJson() => _$TasteFlavorOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TasteFlavorOutConfidenceEnum {
  @JsonValue(r'low')
  low(r'low'),
  @JsonValue(r'high')
  high(r'high');

  const TasteFlavorOutConfidenceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
