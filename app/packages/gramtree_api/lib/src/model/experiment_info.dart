//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'experiment_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExperimentInfo {
  /// Returns a new [ExperimentInfo] instance.
  ExperimentInfo({required this.experiment, required this.variant});

  @JsonKey(name: r'experiment', required: true, includeIfNull: false)
  final String experiment;

  @JsonKey(name: r'variant', required: true, includeIfNull: false)
  final String variant;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentInfo &&
          other.experiment == experiment &&
          other.variant == variant;

  @override
  int get hashCode => experiment.hashCode + variant.hashCode;

  factory ExperimentInfo.fromJson(Map<String, dynamic> json) =>
      _$ExperimentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
