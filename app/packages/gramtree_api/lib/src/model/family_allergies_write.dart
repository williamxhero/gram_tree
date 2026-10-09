//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_allergies_write.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyAllergiesWrite {
  /// Returns a new [FamilyAllergiesWrite] instance.
  FamilyAllergiesWrite({this.categories, this.ingredientIds});

  @JsonKey(name: r'categories', required: false, includeIfNull: false)
  final List<String>? categories;

  @JsonKey(name: r'ingredient_ids', required: false, includeIfNull: false)
  final List<String>? ingredientIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyAllergiesWrite &&
          other.categories == categories &&
          other.ingredientIds == ingredientIds;

  @override
  int get hashCode => categories.hashCode + ingredientIds.hashCode;

  factory FamilyAllergiesWrite.fromJson(Map<String, dynamic> json) =>
      _$FamilyAllergiesWriteFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyAllergiesWriteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
