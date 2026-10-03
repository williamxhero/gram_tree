//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'serving_conversion_warning.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServingConversionWarning {
  /// Returns a new [ServingConversionWarning] instance.
  ServingConversionWarning({
    required this.code,

    this.ingredientId,

    required this.message,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final ServingConversionWarningCodeEnum code;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServingConversionWarning &&
          other.code == code &&
          other.ingredientId == ingredientId &&
          other.message == message;

  @override
  int get hashCode =>
      code.hashCode +
      (ingredientId == null ? 0 : ingredientId.hashCode) +
      message.hashCode;

  factory ServingConversionWarning.fromJson(Map<String, dynamic> json) =>
      _$ServingConversionWarningFromJson(json);

  Map<String, dynamic> toJson() => _$ServingConversionWarningToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ServingConversionWarningCodeEnum {
  @JsonValue(r'round_deviation')
  roundDeviation(r'round_deviation');

  const ServingConversionWarningCodeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
