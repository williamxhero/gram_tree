//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generate_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GenerateInput {
  /// Returns a new [GenerateInput] instance.
  GenerateInput({this.cookware, this.servings});

  @JsonKey(name: r'cookware', required: false, includeIfNull: false)
  final String? cookware;

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'servings', required: false, includeIfNull: false)
  final int? servings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerateInput &&
          other.cookware == cookware &&
          other.servings == servings;

  @override
  int get hashCode =>
      (cookware == null ? 0 : cookware.hashCode) +
      (servings == null ? 0 : servings.hashCode);

  factory GenerateInput.fromJson(Map<String, dynamic> json) =>
      _$GenerateInputFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
