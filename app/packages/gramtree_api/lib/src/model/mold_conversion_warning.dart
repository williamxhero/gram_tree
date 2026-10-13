//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mold_conversion_warning.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MoldConversionWarning {
  /// Returns a new [MoldConversionWarning] instance.
  MoldConversionWarning({
    required this.code,

    this.ingredientId,

    required this.message,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final MoldConversionWarningCodeEnum code;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoldConversionWarning &&
          other.code == code &&
          other.ingredientId == ingredientId &&
          other.message == message;

  @override
  int get hashCode =>
      code.hashCode +
      (ingredientId == null ? 0 : ingredientId.hashCode) +
      message.hashCode;

  factory MoldConversionWarning.fromJson(Map<String, dynamic> json) =>
      _$MoldConversionWarningFromJson(json);

  Map<String, dynamic> toJson() => _$MoldConversionWarningToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MoldConversionWarningCodeEnum {
  @JsonValue(r'round_deviation')
  roundDeviation(r'round_deviation'),
  @JsonValue(r'doneness_check')
  donenessCheck(r'doneness_check');

  const MoldConversionWarningCodeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
