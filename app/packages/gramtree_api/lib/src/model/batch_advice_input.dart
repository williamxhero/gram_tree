//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_advice_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchAdviceInput {
  /// Returns a new [BatchAdviceInput] instance.
  BatchAdviceInput({required this.targetServings});

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'target_servings', required: true, includeIfNull: false)
  final int targetServings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchAdviceInput && other.targetServings == targetServings;

  @override
  int get hashCode => targetServings.hashCode;

  factory BatchAdviceInput.fromJson(Map<String, dynamic> json) =>
      _$BatchAdviceInputFromJson(json);

  Map<String, dynamic> toJson() => _$BatchAdviceInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
