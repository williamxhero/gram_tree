//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'one_line_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OneLineInput {
  /// Returns a new [OneLineInput] instance.
  OneLineInput({required this.text});

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OneLineInput && other.text == text;

  @override
  int get hashCode => text.hashCode;

  factory OneLineInput.fromJson(Map<String, dynamic> json) =>
      _$OneLineInputFromJson(json);

  Map<String, dynamic> toJson() => _$OneLineInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
