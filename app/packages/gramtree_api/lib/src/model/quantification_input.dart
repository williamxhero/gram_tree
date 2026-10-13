//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quantification_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuantificationInput {
  /// Returns a new [QuantificationInput] instance.
  QuantificationInput({required this.baseVersionId});

  @JsonKey(name: r'base_version_id', required: true, includeIfNull: false)
  final String baseVersionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantificationInput && other.baseVersionId == baseVersionId;

  @override
  int get hashCode => baseVersionId.hashCode;

  factory QuantificationInput.fromJson(Map<String, dynamic> json) =>
      _$QuantificationInputFromJson(json);

  Map<String, dynamic> toJson() => _$QuantificationInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
