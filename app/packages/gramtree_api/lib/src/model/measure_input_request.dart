//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'measure_input_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeasureInputRequest {
  /// Returns a new [MeasureInputRequest] instance.
  MeasureInputRequest({
    this.acceptEstimate = false,

    required this.baseUnit,

    this.ingredientId,

    required this.measureId,

    required this.quantity,
  });

  @JsonKey(
    defaultValue: false,
    name: r'accept_estimate',
    required: false,
    includeIfNull: false,
  )
  final bool? acceptEstimate;

  @JsonKey(name: r'base_unit', required: true, includeIfNull: false)
  final MeasureInputRequestBaseUnitEnum baseUnit;

  @JsonKey(name: r'ingredient_id', required: false, includeIfNull: false)
  final String? ingredientId;

  @JsonKey(name: r'measure_id', required: true, includeIfNull: false)
  final String measureId;

  // minimum: 0.0
  // maximum: 10000000
  @JsonKey(name: r'quantity', required: true, includeIfNull: false)
  final num quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureInputRequest &&
          other.acceptEstimate == acceptEstimate &&
          other.baseUnit == baseUnit &&
          other.ingredientId == ingredientId &&
          other.measureId == measureId &&
          other.quantity == quantity;

  @override
  int get hashCode =>
      acceptEstimate.hashCode +
      baseUnit.hashCode +
      (ingredientId == null ? 0 : ingredientId.hashCode) +
      measureId.hashCode +
      quantity.hashCode;

  factory MeasureInputRequest.fromJson(Map<String, dynamic> json) =>
      _$MeasureInputRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MeasureInputRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MeasureInputRequestBaseUnitEnum {
  @JsonValue(r'g')
  g(r'g'),
  @JsonValue(r'ml')
  ml(r'ml');

  const MeasureInputRequestBaseUnitEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
