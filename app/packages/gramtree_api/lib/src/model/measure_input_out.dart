//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/value_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'measure_input_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeasureInputOut {
  /// Returns a new [MeasureInputOut] instance.
  MeasureInputOut({
    this.baseQuantity,

    required this.baseUnit,

    required this.basis,

    this.measureInputToken,

    required this.original,

    this.quantitySource,

    required this.status,
  });

  @JsonKey(name: r'base_quantity', required: false, includeIfNull: false)
  final num? baseQuantity;

  @JsonKey(name: r'base_unit', required: true, includeIfNull: false)
  final MeasureInputOutBaseUnitEnum baseUnit;

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'measure_input_token', required: false, includeIfNull: false)
  final String? measureInputToken;

  @JsonKey(name: r'original', required: true, includeIfNull: false)
  final String original;

  @JsonKey(name: r'quantity_source', required: false, includeIfNull: false)
  final ValueSource? quantitySource;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final MeasureInputOutStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureInputOut &&
          other.baseQuantity == baseQuantity &&
          other.baseUnit == baseUnit &&
          other.basis == basis &&
          other.measureInputToken == measureInputToken &&
          other.original == original &&
          other.quantitySource == quantitySource &&
          other.status == status;

  @override
  int get hashCode =>
      (baseQuantity == null ? 0 : baseQuantity.hashCode) +
      baseUnit.hashCode +
      basis.hashCode +
      (measureInputToken == null ? 0 : measureInputToken.hashCode) +
      original.hashCode +
      (quantitySource == null ? 0 : quantitySource.hashCode) +
      status.hashCode;

  factory MeasureInputOut.fromJson(Map<String, dynamic> json) =>
      _$MeasureInputOutFromJson(json);

  Map<String, dynamic> toJson() => _$MeasureInputOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MeasureInputOutBaseUnitEnum {
  @JsonValue(r'g')
  g(r'g'),
  @JsonValue(r'ml')
  ml(r'ml');

  const MeasureInputOutBaseUnitEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum MeasureInputOutStatusEnum {
  @JsonValue(r'ready')
  ready(r'ready'),
  @JsonValue(r'no_density')
  noDensity(r'no_density'),
  @JsonValue(r'estimate_confirmation_required')
  estimateConfirmationRequired(r'estimate_confirmation_required');

  const MeasureInputOutStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
