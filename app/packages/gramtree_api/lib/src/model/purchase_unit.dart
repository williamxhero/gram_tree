//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'purchase_unit.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PurchaseUnit {
  /// Returns a new [PurchaseUnit] instance.
  PurchaseUnit({required this.grams, required this.name});

  /// 一个购买单位大约多少克
  @JsonKey(name: r'grams', required: true, includeIfNull: false)
  final num grams;

  /// 购买单位，例如 盒、把、瓶
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseUnit && other.grams == grams && other.name == name;

  @override
  int get hashCode => grams.hashCode + name.hashCode;

  factory PurchaseUnit.fromJson(Map<String, dynamic> json) =>
      _$PurchaseUnitFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseUnitToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
