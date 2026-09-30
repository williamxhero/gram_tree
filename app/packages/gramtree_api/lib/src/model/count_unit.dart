//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'count_unit.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CountUnit {
  /// Returns a new [CountUnit] instance.
  CountUnit({required this.grams, required this.unit});

  /// 一个这样的单位大约多少克
  @JsonKey(name: r'grams', required: true, includeIfNull: false)
  final num grams;

  /// 计数单位，例如 个、瓣、根、片
  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final String unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountUnit && other.grams == grams && other.unit == unit;

  @override
  int get hashCode => grams.hashCode + unit.hashCode;

  factory CountUnit.fromJson(Map<String, dynamic> json) =>
      _$CountUnitFromJson(json);

  Map<String, dynamic> toJson() => _$CountUnitToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
