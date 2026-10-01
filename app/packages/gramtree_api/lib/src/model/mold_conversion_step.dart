//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mold_conversion_step.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MoldConversionStep {
  /// Returns a new [MoldConversionStep] instance.
  MoldConversionStep({
    this.donenessWarning = false,

    this.donenessWarningText,

    required this.durationSeconds,

    this.heat,

    required this.id,

    required this.instruction,

    this.temperatureCelsius,

    this.timeAdvisory,
  });

  @JsonKey(
    defaultValue: false,
    name: r'doneness_warning',
    required: false,
    includeIfNull: false,
  )
  final bool? donenessWarning;

  @JsonKey(
    name: r'doneness_warning_text',
    required: false,
    includeIfNull: false,
  )
  final String? donenessWarningText;

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

  @JsonKey(name: r'time_advisory', required: false, includeIfNull: false)
  final String? timeAdvisory;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoldConversionStep &&
          other.donenessWarning == donenessWarning &&
          other.donenessWarningText == donenessWarningText &&
          other.durationSeconds == durationSeconds &&
          other.heat == heat &&
          other.id == id &&
          other.instruction == instruction &&
          other.temperatureCelsius == temperatureCelsius &&
          other.timeAdvisory == timeAdvisory;

  @override
  int get hashCode =>
      donenessWarning.hashCode +
      (donenessWarningText == null ? 0 : donenessWarningText.hashCode) +
      durationSeconds.hashCode +
      (heat == null ? 0 : heat.hashCode) +
      id.hashCode +
      instruction.hashCode +
      (temperatureCelsius == null ? 0 : temperatureCelsius.hashCode) +
      (timeAdvisory == null ? 0 : timeAdvisory.hashCode);

  factory MoldConversionStep.fromJson(Map<String, dynamic> json) =>
      _$MoldConversionStepFromJson(json);

  Map<String, dynamic> toJson() => _$MoldConversionStepToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
