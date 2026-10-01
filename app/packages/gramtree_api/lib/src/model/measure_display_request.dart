//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'measure_display_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeasureDisplayRequest {
  /// Returns a new [MeasureDisplayRequest] instance.
  MeasureDisplayRequest({
    required this.baseQuantity,

    required this.baseUnit,

    this.density,

    this.measureId,

    required this.mode,
  });

  // minimum: 0.0
  @JsonKey(name: r'base_quantity', required: true, includeIfNull: false)
  final num baseQuantity;

  @JsonKey(name: r'base_unit', required: true, includeIfNull: false)
  final MeasureDisplayRequestBaseUnitEnum baseUnit;

  @JsonKey(name: r'density', required: false, includeIfNull: false)
  final num? density;

  @JsonKey(name: r'measure_id', required: false, includeIfNull: false)
  final String? measureId;

  @JsonKey(name: r'mode', required: true, includeIfNull: false)
  final MeasureDisplayRequestModeEnum mode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureDisplayRequest &&
          other.baseQuantity == baseQuantity &&
          other.baseUnit == baseUnit &&
          other.density == density &&
          other.measureId == measureId &&
          other.mode == mode;

  @override
  int get hashCode =>
      baseQuantity.hashCode +
      baseUnit.hashCode +
      (density == null ? 0 : density.hashCode) +
      (measureId == null ? 0 : measureId.hashCode) +
      mode.hashCode;

  factory MeasureDisplayRequest.fromJson(Map<String, dynamic> json) =>
      _$MeasureDisplayRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MeasureDisplayRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MeasureDisplayRequestBaseUnitEnum {
  @JsonValue(r'g')
  g(r'g'),
  @JsonValue(r'ml')
  ml(r'ml');

  const MeasureDisplayRequestBaseUnitEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum MeasureDisplayRequestModeEnum {
  @JsonValue(r'base')
  base_(r'base'),
  @JsonValue(r'standard')
  standard(r'standard'),
  @JsonValue(r'home')
  home(r'home');

  const MeasureDisplayRequestModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
