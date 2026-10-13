//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mold_spec.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MoldSpec {
  /// Returns a new [MoldSpec] instance.
  MoldSpec({
    this.diameter,

    this.length,

    required this.shape,

    this.side,

    this.unit,

    this.width,
  });

  // maximum: 1000.0
  @JsonKey(name: r'diameter', required: false, includeIfNull: false)
  final num? diameter;

  // maximum: 1000.0
  @JsonKey(name: r'length', required: false, includeIfNull: false)
  final num? length;

  @JsonKey(name: r'shape', required: true, includeIfNull: false)
  final MoldSpecShapeEnum shape;

  // maximum: 1000.0
  @JsonKey(name: r'side', required: false, includeIfNull: false)
  final num? side;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final MoldSpecUnitEnum? unit;

  // maximum: 1000.0
  @JsonKey(name: r'width', required: false, includeIfNull: false)
  final num? width;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoldSpec &&
          other.diameter == diameter &&
          other.length == length &&
          other.shape == shape &&
          other.side == side &&
          other.unit == unit &&
          other.width == width;

  @override
  int get hashCode =>
      (diameter == null ? 0 : diameter.hashCode) +
      (length == null ? 0 : length.hashCode) +
      shape.hashCode +
      (side == null ? 0 : side.hashCode) +
      (unit == null ? 0 : unit.hashCode) +
      (width == null ? 0 : width.hashCode);

  factory MoldSpec.fromJson(Map<String, dynamic> json) =>
      _$MoldSpecFromJson(json);

  Map<String, dynamic> toJson() => _$MoldSpecToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MoldSpecShapeEnum {
  @JsonValue(r'round')
  round(r'round'),
  @JsonValue(r'square')
  square(r'square'),
  @JsonValue(r'rectangular')
  rectangular(r'rectangular'),
  @JsonValue(r'custom')
  custom(r'custom');

  const MoldSpecShapeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum MoldSpecUnitEnum {
  @JsonValue(r'cm')
  cm(r'cm'),
  @JsonValue(r'in')
  in_(r'in'),
  @JsonValue(r'inch')
  inch(r'inch');

  const MoldSpecUnitEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
