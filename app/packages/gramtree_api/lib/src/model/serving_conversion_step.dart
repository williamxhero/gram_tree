//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'serving_conversion_step.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServingConversionStep {
  /// Returns a new [ServingConversionStep] instance.
  ServingConversionStep({
    this.batchWarning = false,

    this.batchWarningText,

    required this.durationSeconds,

    this.heat,

    required this.id,

    required this.instruction,

    this.temperatureCelsius,
  });

  @JsonKey(
    defaultValue: false,
    name: r'batch_warning',
    required: false,
    includeIfNull: false,
  )
  final bool? batchWarning;

  @JsonKey(name: r'batch_warning_text', required: false, includeIfNull: false)
  final String? batchWarningText;

  @JsonKey(name: r'duration_seconds', required: true, includeIfNull: false)
  final int durationSeconds;

  @JsonKey(name: r'heat', required: false, includeIfNull: false)
  final String? heat;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'instruction', required: true, includeIfNull: false)
  final String instruction;

  @JsonKey(name: r'temperature_celsius', required: false, includeIfNull: false)
  final num? temperatureCelsius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServingConversionStep &&
          other.batchWarning == batchWarning &&
          other.batchWarningText == batchWarningText &&
          other.durationSeconds == durationSeconds &&
          other.heat == heat &&
          other.id == id &&
          other.instruction == instruction &&
          other.temperatureCelsius == temperatureCelsius;

  @override
  int get hashCode =>
      batchWarning.hashCode +
      (batchWarningText == null ? 0 : batchWarningText.hashCode) +
      durationSeconds.hashCode +
      (heat == null ? 0 : heat.hashCode) +
      id.hashCode +
      instruction.hashCode +
      (temperatureCelsius == null ? 0 : temperatureCelsius.hashCode);

  factory ServingConversionStep.fromJson(Map<String, dynamic> json) =>
      _$ServingConversionStepFromJson(json);

  Map<String, dynamic> toJson() => _$ServingConversionStepToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
