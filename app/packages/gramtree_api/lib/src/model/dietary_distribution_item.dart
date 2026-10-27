//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dietary_distribution_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DietaryDistributionItem {
  /// Returns a new [DietaryDistributionItem] instance.
  DietaryDistributionItem({required this.count, required this.key});

  /// Records containing this category, once per record
  // minimum: 0
  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryDistributionItem &&
          other.count == count &&
          other.key == key;

  @override
  int get hashCode => count.hashCode + key.hashCode;

  factory DietaryDistributionItem.fromJson(Map<String, dynamic> json) =>
      _$DietaryDistributionItemFromJson(json);

  Map<String, dynamic> toJson() => _$DietaryDistributionItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
