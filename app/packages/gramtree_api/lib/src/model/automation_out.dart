//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'automation_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AutomationOut {
  /// Returns a new [AutomationOut] instance.
  AutomationOut({required this.automaticLearning, required this.saveToTaste});

  @JsonKey(name: r'automatic_learning', required: true, includeIfNull: false)
  final bool automaticLearning;

  @JsonKey(name: r'save_to_taste', required: true, includeIfNull: false)
  final bool saveToTaste;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomationOut &&
          other.automaticLearning == automaticLearning &&
          other.saveToTaste == saveToTaste;

  @override
  int get hashCode => automaticLearning.hashCode + saveToTaste.hashCode;

  factory AutomationOut.fromJson(Map<String, dynamic> json) =>
      _$AutomationOutFromJson(json);

  Map<String, dynamic> toJson() => _$AutomationOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
